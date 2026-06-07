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
if command -v mc &>/dev/null; then
    mc alias set local http://localhost:9000 minioadmin minioadmin &>/dev/null
    mc mb local/papers --ignore-existing &>/dev/null
    echo "ensured"
else
    # Fallback: use curl to create bucket via S3 API
    curl -sf -X PUT http://localhost:9000/papers \
        -u minioadmin:minioadmin &>/dev/null && echo "created" || echo "may already exist"
fi

# --- Temporal ---
echo -n "Temporal (:7233): "
for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf http://localhost:7233/health &>/dev/null; then
        echo "READY (${i}s)"
        break
    fi
    # Temporal may take longer to start; also try grpc health via temporal CLI
    if command -v temporal &>/dev/null; then
        if temporal operator search-attribute list &>/dev/null; then
            echo "READY (${i}s)"
            break
        fi
    fi
    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo "FAILED (timeout after ${MAX_RETRIES}x${RETRY_INTERVAL}s)"
        exit 1
    fi
    sleep $RETRY_INTERVAL
done

echo ""
echo "All Phase 1 infrastructure services are ready."
