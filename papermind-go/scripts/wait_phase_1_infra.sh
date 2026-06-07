#!/bin/bash
# Wait for Phase 1 infrastructure services to be ready in CI
# Expects: Docker Compose services already started
# Services: PostgreSQL, Qdrant, MinIO, Temporal

set -euo pipefail

MAX_RETRIES=60
RETRY_INTERVAL=3

echo "Waiting for Phase 1 infrastructure services..."

# --- PostgreSQL ---
echo -n "PostgreSQL: "
for i in $(seq 1 $MAX_RETRIES); do
    if PGPASSWORD=papermind psql -h localhost -p 5432 -U papermind -d papermind -c "SELECT 1" &>/dev/null; then
        echo "READY (${i}s)"
        break
    fi
    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo "FAILED (timeout after ${MAX_RETRIES}x${RETRY_INTERVAL}s)"
        exit 1
    fi
    sleep $RETRY_INTERVAL
done

# --- Qdrant HTTP ---
echo -n "Qdrant (HTTP :6333): "
for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf http://localhost:6333/healthz &>/dev/null; then
        echo "READY (${i}s)"
        break
    fi
    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo "FAILED (timeout after ${MAX_RETRIES}x${RETRY_INTERVAL}s)"
        exit 1
    fi
    sleep $RETRY_INTERVAL
done

# --- MinIO ---
echo -n "MinIO (:9000): "
for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf http://localhost:9000/minio/health/live &>/dev/null; then
        echo "READY (${i}s)"
        break
    fi
    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo "FAILED (timeout after ${MAX_RETRIES}x${RETRY_INTERVAL}s)"
        exit 1
    fi
    sleep $RETRY_INTERVAL
done

# Create MinIO bucket if not exists
echo -n "MinIO bucket 'papers': "
curl -sf -X PUT http://localhost:9000/papers \
    -u minioadmin:minioadmin &>/dev/null && echo "created" || echo "may already exist"

# --- Temporal ---
# Temporal exposes gRPC on :7233. We check if the port is open and accepting connections.
# The auto-setup image does not expose an HTTP health endpoint by default.
echo -n "Temporal (:7233): "
for i in $(seq 1 $MAX_RETRIES); do
    # Method 1: Check if gRPC port is reachable using bash /dev/tcp
    if (echo > /dev/tcp/localhost/7233) &>/dev/null 2>&1; then
        echo "READY (${i}s) - port open"
        break
    fi
    # Method 2: Try HTTP health endpoint (some Temporal versions expose it)
    if curl -sf --max-time 2 http://localhost:7233/health &>/dev/null; then
        echo "READY (${i}s) - HTTP health"
        break
    fi
    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo "FAILED (timeout after ${MAX_RETRIES}x${RETRY_INTERVAL}s)"
        # Print diagnostic info
        echo "--- Diagnostic: Docker container status ---"
        docker ps -a --filter "name=papermind-temporal" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
        echo "--- Diagnostic: Temporal container logs (last 20 lines) ---"
        docker logs papermind-temporal --tail 20 2>&1 || true
        exit 1
    fi
    sleep $RETRY_INTERVAL
done

echo ""
echo "All Phase 1 infrastructure services are ready."
