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
# Temporal auto-setup needs time to: wait for PostgreSQL -> create databases -> init schema -> start server
# We check both: gRPC port 7233 open AND "started" in container logs
TEMPORAL_RETRIES=90
TEMPORAL_INTERVAL=3
echo -n "Temporal (:7233): "
for i in $(seq 1 $TEMPORAL_RETRIES); do
    # Check if gRPC port is reachable
    if (echo > /dev/tcp/localhost/7233) &>/dev/null 2>&1; then
        # Port is open - verify server has actually started (not just binding)
        if docker logs papermind-temporal 2>&1 | tail -5 | grep -qi "started"; then
            echo "READY (${i}s) - server started"
            break
        fi
        # Port open but server not fully started yet, keep waiting
        if [ "$i" -eq "$TEMPORAL_RETRIES" ]; then
            echo "FAILED (port open but server not started after ${TEMPORAL_RETRIES}x${TEMPORAL_INTERVAL}s)"
        fi
    fi
    if [ "$i" -eq "$TEMPORAL_RETRIES" ]; then
        echo "FAILED (timeout after ${TEMPORAL_RETRIES}x${TEMPORAL_INTERVAL}s)"
        echo ""
        echo "=== Diagnostic: Docker container status ==="
        docker ps -a --filter "name=papermind-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
        echo ""
        echo "=== Diagnostic: Temporal container logs (last 40 lines) ==="
        docker logs papermind-temporal --tail 40 2>&1 || true
        echo ""
        echo "=== Diagnostic: PostgreSQL container logs (last 20 lines) ==="
        docker logs papermind-postgres --tail 20 2>&1 || true
        exit 1
    fi
    sleep $TEMPORAL_INTERVAL
done

echo ""
echo "All Phase 1 infrastructure services are ready."
