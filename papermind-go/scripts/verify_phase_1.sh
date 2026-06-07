#!/bin/bash
# Phase 1 Verification Script
# Checks all Phase 1 requirements and outputs PASS/FAIL for each item.
#
# Modes:
#   CI mode (PHASE1_CI=true):  All checks must PASS. No SKIP allowed.
#   Local mode (default):      Docker-dependent checks are SKIPped gracefully.

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPORT_DIR="$PROJECT_DIR/reports"
LOG_FILE="$REPORT_DIR/phase-1-acceptance.log"

mkdir -p "$REPORT_DIR"

# Initialize log
echo "Phase 1 Acceptance Test - $(date)" > "$LOG_FILE"
echo "==========================================" >> "$LOG_FILE"
if [ "${PHASE1_CI:-false}" = "true" ]; then
    echo "Mode: CI (strict - no SKIP allowed)" >> "$LOG_FILE"
else
    echo "Mode: Local (Docker-dependent checks may SKIP)" >> "$LOG_FILE"
fi

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

check_pass() {
    echo "[PASS] $1"
    echo "[PASS] $1 - $2" >> "$LOG_FILE"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
    echo "[FAIL] $1"
    echo "[FAIL] $1 - $2" >> "$LOG_FILE"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_skip() {
    if [ "${PHASE1_CI:-false}" = "true" ]; then
        echo "[FAIL] $1 (CI requires PASS, cannot SKIP)"
        echo "[FAIL] $1 - SKIP not allowed in CI: $2" >> "$LOG_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "[SKIP] $1"
        echo "[SKIP] $1 - $2" >> "$LOG_FILE"
        SKIP_COUNT=$((SKIP_COUNT + 1))
    fi
}

echo ""
echo "=========================================="
echo "  PaperMind Phase 1 Acceptance Test"
if [ "${PHASE1_CI:-false}" = "true" ]; then
    echo "  Mode: CI (strict)"
else
    echo "  Mode: Local"
fi
echo "=========================================="
echo ""

# =============================================================================
# 1. Docker Compose Services
# =============================================================================
echo "--- Docker Compose Services ---"
if command -v docker &> /dev/null; then
    DOCKER_OK=true
    for svc in papermind-postgres papermind-qdrant papermind-minio papermind-temporal papermind-temporal-ui; do
        if docker ps --format '{{.Names}}' | grep -q "^${svc}$"; then
            check_pass "Docker service: $svc" "Container is running"
        else
            check_fail "Docker service: $svc" "Container is not running"
            DOCKER_OK=false
        fi
    done
else
    check_skip "Docker services" "Docker is not installed on this system"
fi

# =============================================================================
# 2. PostgreSQL Connection
# =============================================================================
echo ""
echo "--- PostgreSQL Connection ---"
if command -v docker &> /dev/null && docker ps --format '{{.Names}}' | grep -q "papermind-postgres"; then
    if PGPASSWORD=papermind psql -h localhost -p 5432 -U papermind -d papermind -c "SELECT 1" &> /dev/null; then
        check_pass "PostgreSQL connection" "Successfully connected"
    else
        check_fail "PostgreSQL connection" "Failed to connect"
    fi
else
    check_skip "PostgreSQL connection" "Docker/PostgreSQL not available"
fi

# =============================================================================
# 3. Qdrant Health
# =============================================================================
echo ""
echo "--- Qdrant Health ---"
if command -v curl &> /dev/null; then
    if curl -sf http://localhost:6333/healthz &> /dev/null; then
        check_pass "Qdrant health" "HTTP health check passed"
    else
        if [ "${PHASE1_CI:-false}" = "true" ]; then
            check_fail "Qdrant health" "Qdrant not reachable on http://localhost:6333/healthz"
        else
            check_skip "Qdrant health" "Qdrant not reachable (service may not be running)"
        fi
    fi
else
    check_skip "Qdrant health" "curl not available"
fi

# =============================================================================
# 4. MinIO Health
# =============================================================================
echo ""
echo "--- MinIO Health ---"
if command -v curl &> /dev/null; then
    if curl -sf http://localhost:9000/minio/health/live &> /dev/null; then
        check_pass "MinIO health" "HTTP health check passed"
    else
        if [ "${PHASE1_CI:-false}" = "true" ]; then
            check_fail "MinIO health" "MinIO not reachable on http://localhost:9000/minio/health/live"
        else
            check_skip "MinIO health" "MinIO not reachable (service may not be running)"
        fi
    fi
else
    check_skip "MinIO health" "curl not available"
fi

# =============================================================================
# 5. Temporal Health
# =============================================================================
echo ""
echo "--- Temporal Health ---"
# Temporal is a gRPC service - check if port 7233 is accepting connections
if (echo > /dev/tcp/localhost/7233) &>/dev/null 2>&1; then
    check_pass "Temporal health" "gRPC port 7233 is reachable"
else
    if [ "${PHASE1_CI:-false}" = "true" ]; then
        check_fail "Temporal health" "Temporal gRPC port 7233 not reachable"
    else
        check_skip "Temporal health" "Temporal not reachable (service may not be running)"
    fi
fi

# =============================================================================
# 6. Database Migrations (table verification)
# =============================================================================
echo ""
echo "--- Database Migrations ---"
if command -v docker &> /dev/null && docker ps --format '{{.Names}}' | grep -q "papermind-postgres"; then
    TABLES=$(PGPASSWORD=papermind psql -h localhost -p 5432 -U papermind -d papermind -t -A -c \
        "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name" 2>/dev/null)
    REQUIRED_TABLES="tenants users papers paper_chunks paper_logic_models logic_nodes logic_edges workflow_runs query_logs citations"
    for tbl in $REQUIRED_TABLES; do
        if echo "$TABLES" | grep -q "^${tbl}$"; then
            check_pass "Table exists: $tbl" "Found in database"
        else
            check_fail "Table exists: $tbl" "Not found in database"
        fi
    done
else
    check_skip "Database migrations" "Docker/PostgreSQL not available - cannot verify tables"
fi

# =============================================================================
# 7. Go Tests
# =============================================================================
echo ""
echo "--- Go Tests ---"
TEST_OUTPUT=$(cd "$PROJECT_DIR" && go test ./... 2>&1) || true
echo "$TEST_OUTPUT"
echo "$TEST_OUTPUT" >> "$LOG_FILE"
if echo "$TEST_OUTPUT" | grep -q "^FAIL\|^--- FAIL\|^panic\|^fatal"; then
    check_fail "Go tests" "Some tests failed"
else
    check_pass "Go tests" "All tests passed"
fi

# =============================================================================
# 8-10. API Endpoints (require PostgreSQL)
# =============================================================================
echo ""
echo "--- API Health Endpoint ---"
API_STARTED_BY_US=false
if command -v docker &> /dev/null && docker ps --format '{{.Names}}' | grep -q "papermind-postgres"; then
    # Wait for API to be ready (it may have been started by CI step)
    API_READY=false
    for i in $(seq 1 15); do
        if curl -sf http://localhost:8080/api/v1/health &> /dev/null; then
            API_READY=true
            echo "API server is ready (attempt $i)"
            break
        fi
        echo "Waiting for API server... (attempt $i/15)"
        sleep 2
    done

    # If API not running yet, start it ourselves
    if [ "$API_READY" = false ]; then
        cd "$PROJECT_DIR"
        go run cmd/api/main.go > "$REPORT_DIR/api_verify.log" 2>&1 &
        API_PID=$!
        API_STARTED_BY_US=true
        echo "Starting API server (PID: $API_PID)..."
        # Wait for our API to be ready
        for i in $(seq 1 15); do
            if curl -sf http://localhost:8080/api/v1/health &> /dev/null; then
                echo "API server started successfully (attempt $i)"
                break
            fi
            echo "Waiting for API server to start... (attempt $i/15)"
            sleep 2
        done
    fi

    HEALTH_RESP=$(curl -s http://localhost:8080/api/v1/health 2>/dev/null || echo "")
    if echo "$HEALTH_RESP" | grep -q '"status":"ok"'; then
        check_pass "API health endpoint" "Response: $HEALTH_RESP"
    else
        check_fail "API health endpoint" "Unexpected response: $HEALTH_RESP"
    fi

    # 9. Login endpoint
    echo ""
    echo "--- Login Endpoint ---"
    LOGIN_RESP=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin123"}' 2>/dev/null || echo "")
    if echo "$LOGIN_RESP" | grep -q '"access_token"'; then
        TOKEN=$(echo "$LOGIN_RESP" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        check_pass "Login endpoint" "Got JWT token: ${TOKEN:0:20}..."
    else
        check_fail "Login endpoint" "Response: $LOGIN_RESP"
    fi

    # 10. Me endpoint
    echo ""
    echo "--- Me Endpoint ---"
    if [ -n "${TOKEN:-}" ]; then
        ME_RESP=$(curl -s http://localhost:8080/api/v1/me \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "")
        if echo "$ME_RESP" | grep -q '"username":"admin"'; then
            check_pass "Me endpoint" "Response: $ME_RESP"
        else
            check_fail "Me endpoint" "Response: $ME_RESP"
        fi
    else
        check_fail "Me endpoint" "No token available from login"
    fi

    # Stop API if we started it
    if [ "$API_STARTED_BY_US" = true ] && [ -n "${API_PID:-}" ]; then
        kill $API_PID 2>/dev/null || true
        sleep 1
    fi
else
    check_skip "API health endpoint" "Docker/PostgreSQL not available - cannot start API"
    check_skip "Login endpoint" "Docker/PostgreSQL not available"
    check_skip "Me endpoint" "Docker/PostgreSQL not available"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=========================================="
echo "  Phase 1 Acceptance Summary"
echo "=========================================="
echo "  PASS:  $PASS_COUNT"
echo "  FAIL:  $FAIL_COUNT"
echo "  SKIP:  $SKIP_COUNT"
echo "=========================================="
echo ""

# Save summary to log
echo "" >> "$LOG_FILE"
echo "Summary: PASS=$PASS_COUNT FAIL=$FAIL_COUNT SKIP=$SKIP_COUNT" >> "$LOG_FILE"

# Export results for report generation
echo "PASS_COUNT=$PASS_COUNT" > "$REPORT_DIR/phase-1-results.env"
echo "FAIL_COUNT=$FAIL_COUNT" >> "$REPORT_DIR/phase-1-results.env"
echo "SKIP_COUNT=$SKIP_COUNT" >> "$REPORT_DIR/phase-1-results.env"
if [ "${PHASE1_CI:-false}" = "true" ]; then
    echo "VERIFICATION_MODE=ci" >> "$REPORT_DIR/phase-1-results.env"
else
    echo "VERIFICATION_MODE=local" >> "$REPORT_DIR/phase-1-results.env"
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Phase 1 verification FAILED ($FAIL_COUNT failure(s))"
    exit 1
elif [ "$SKIP_COUNT" -gt 0 ] && [ "${PHASE1_CI:-false}" = "true" ]; then
    echo "Phase 1 CI verification FAILED ($SKIP_COUNT skipped item(s) not allowed in CI)"
    exit 1
else
    echo "Phase 1 verification PASSED"
    exit 0
fi
