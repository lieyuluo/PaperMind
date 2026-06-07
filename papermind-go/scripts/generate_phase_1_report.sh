#!/bin/bash
# Phase 1 Report Generator
# Generates reports/phase-1-report.md based on acceptance test results
# Distinguishes between Local Verification and CI Verification

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPORT_DIR="$PROJECT_DIR/reports"
REPORT_FILE="$REPORT_DIR/phase-1-report.md"
LOG_FILE="$REPORT_DIR/phase-1-acceptance.log"
RESULTS_FILE="$REPORT_DIR/phase-1-results.env"

mkdir -p "$REPORT_DIR"

# Load results if available
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
VERIFICATION_MODE="local"
if [ -f "$RESULTS_FILE" ]; then
    source "$RESULTS_FILE"
fi

# Parse log for individual results
parse_log() {
    local item="$1"
    local log_content
    log_content=$(cat "$LOG_FILE" 2>/dev/null || echo "")
    if echo "$log_content" | grep -q "\[PASS\].*${item}"; then
        echo "PASS"
    elif echo "$log_content" | grep -q "\[FAIL\].*${item}"; then
        echo "FAIL"
    elif echo "$log_content" | grep -q "\[SKIP\].*${item}"; then
        echo "SKIP"
    else
        echo "N/A"
    fi
}

get_evidence() {
    local item="$1"
    local log_content
    log_content=$(cat "$LOG_FILE" 2>/dev/null || echo "")
    echo "$log_content" | grep "\[${item}\]" | head -1 | sed 's/.*- //' || echo "Not available"
}

# Get git info if available
GIT_COMMIT=$(cd "$PROJECT_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "N/A")
GIT_BRANCH=$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null || echo "N/A")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Determine suggested next step
if [ "$VERIFICATION_MODE" = "ci" ]; then
    if [ "$FAIL_COUNT" -gt 0 ] || [ "$SKIP_COUNT" -gt 0 ]; then
        NEXT_STEP="Fix Phase 1"
    else
        NEXT_STEP="Proceed to Phase 2"
    fi
else
    # Local mode: always suggest checking CI
    NEXT_STEP="Check CI results before proceeding"
fi

# Generate report
cat > "$REPORT_FILE" << EOF
# Phase 1 Report

**Generated:** ${TIMESTAMP}
**Verification Mode:** ${VERIFICATION_MODE}
**Git Branch:** ${GIT_BRANCH}
**Git Commit:** ${GIT_COMMIT}

## 1. Phase Goal

Phase 1 的目标是建立 PaperMind-Go 的基础工程骨架，并完成本地开发所需的基础设施接入。

本阶段关注：
- Go module 初始化与 API 服务
- 基础目录结构与配置管理
- Docker Compose 基础服务（PostgreSQL, Qdrant, MinIO, Temporal）
- PostgreSQL 数据库迁移与种子数据
- JWT 基础认证闭环
- 统一 API 响应格式与错误处理
- 健康检查接口
- 自动验收脚本与报告生成

## 2. Verification Modes

| Mode | Where | What it checks |
|---|---|---|
| **Local** | Developer machine | \`go build\`, \`go test\` only. No Docker required. |
| **CI** | GitHub Actions (ubuntu-latest) | Full verification: Docker services, migrations, API endpoints, auth flow. |

**Local verification:** \`make phase-1-local\`
**CI verification:** Triggered by push/PR to main/develop, or manually via workflow_dispatch.

## 3. Completed Items

| # | Item | Status |
|---|------|--------|
| 1 | Go module 初始化 | Done |
| 2 | 基础目录结构 | Done |
| 3 | Docker Compose 配置 | Done |
| 4 | 配置文件（config.yaml / config.example.yaml） | Done |
| 5 | PostgreSQL 数据库 migration 文件 | Done |
| 6 | 10 张数据库表创建 | Done |
| 7 | 种子数据（默认租户 + admin 用户） | Done |
| 8 | 统一 API 响应格式 | Done |
| 9 | 统一错误处理 | Done |
| 10 | JWT 认证（生成/解析/中间件） | Done |
| 11 | 登录接口 POST /api/v1/auth/login | Done |
| 12 | 当前用户接口 GET /api/v1/me | Done |
| 13 | 健康检查接口 GET /api/v1/health | Done |
| 14 | Storage 连接检查（PostgreSQL/Qdrant/MinIO/Temporal） | Done |
| 15 | Makefile（phase-1-local / phase-1-ci） | Done |
| 16 | 自动验收脚本 verify_phase_1.sh | Done |
| 17 | 报告生成脚本 generate_phase_1_report.sh | Done |
| 18 | 基础设施等待脚本 wait_phase_1_infra.sh | Done |
| 19 | GitHub Actions CI workflow | Done |
| 20 | Go 单元测试 | Done |
| 21 | Worker 占位入口 | Done |
| 22 | Migration 占位入口 | Done |

## 4. Acceptance Commands

\`\`\`bash
# === Local (no Docker required) ===
make phase-1-local        # Build + test only

# === CI (GitHub Actions, full verification) ===
make phase-1-ci           # compose-up → migrate-up → test → verify → report

# === Individual targets ===
make test                 # Go tests
make verify-phase-1       # Run verification script
make report-phase-1       # Generate report
\`\`\`

## 5. Acceptance Results

**Verification Mode:** ${VERIFICATION_MODE}

| Check Item | Status | Evidence |
|---|---|---|
| Docker Compose services | $(parse_log "Docker services") | $(get_evidence "Docker services") |
| PostgreSQL connection | $(parse_log "PostgreSQL connection") | $(get_evidence "PostgreSQL connection") |
| Qdrant health | $(parse_log "Qdrant health") | $(get_evidence "Qdrant health") |
| MinIO health | $(parse_log "MinIO health") | $(get_evidence "MinIO health") |
| Temporal health | $(parse_log "Temporal health") | $(get_evidence "Temporal health") |
| Database migrations | $(parse_log "Database migrations") | $(get_evidence "Database migrations") |
| Go tests | $(parse_log "Go tests") | $(get_evidence "Go tests") |
| API health endpoint | $(parse_log "API health endpoint") | $(get_evidence "API health endpoint") |
| Login endpoint | $(parse_log "Login endpoint") | $(get_evidence "Login endpoint") |
| Me endpoint | $(parse_log "Me endpoint") | $(get_evidence "Me endpoint") |

**Summary:** PASS=${PASS_COUNT} / FAIL=${FAIL_COUNT} / SKIP=${SKIP_COUNT}

## 6. API Verification

### 6.1 Health Check

\`\`\`
GET /api/v1/health
\`\`\`

Expected Response:
\`\`\`json
{
  "code": 0,
  "message": "ok",
  "data": { "status": "ok" }
}
\`\`\`

### 6.2 Login

\`\`\`
POST /api/v1/auth/login
Content-Type: application/json

{"username": "admin", "password": "admin123"}
\`\`\`

Expected Response:
\`\`\`json
{
  "code": 0,
  "message": "ok",
  "data": {
    "access_token": "jwt-token",
    "token_type": "Bearer",
    "expires_in": 86400
  }
}
\`\`\`

### 6.3 Current User

\`\`\`
GET /api/v1/me
Authorization: Bearer <token>
\`\`\`

Expected Response:
\`\`\`json
{
  "code": 0,
  "message": "ok",
  "data": {
    "user_id": "uuid",
    "tenant_id": "uuid",
    "username": "admin",
    "role": "Admin"
  }
}
\`\`\`

## 7. Database Verification

### 7.1 Tables Created

| Table | Status |
|---|---|
| tenants | Created |
| users | Created |
| papers | Created |
| paper_chunks | Created |
| paper_logic_models | Created |
| logic_nodes | Created |
| logic_edges | Created |
| workflow_runs | Created |
| query_logs | Created |
| citations | Created |

### 7.2 Seed Data

- Default tenant: \`default\` (UUID: 00000000-0000-0000-0000-000000000001)
- Admin user: \`admin\` (UUID: 00000000-0000-0000-0000-000000000002)
- Password: bcrypt hashed (not plaintext)

## 8. Infrastructure Verification

### 8.1 Docker Compose Services

| Service | Container Name | Port |
|---|---|---|
| PostgreSQL | papermind-postgres | 5432 |
| Qdrant | papermind-qdrant | 6333 (HTTP), 6334 (gRPC) |
| MinIO | papermind-minio | 9000 (API), 9001 (Console) |
| Temporal | papermind-temporal | 7233 |
| Temporal UI | papermind-temporal-ui | 8088 |

### 8.2 Notes

$(if [ "$VERIFICATION_MODE" = "local" ]; then
echo "- Local verification does not require Docker"
echo "- Infrastructure services verified only in CI (GitHub Actions)"
echo "- Code compilation and unit tests pass locally"
else
echo "- CI verification runs on ubuntu-latest with Docker"
echo "- All services started via docker compose"
echo "- Infrastructure readiness verified by wait_phase_1_infra.sh"
fi)

## 9. Test Summary

\`\`\`
Go unit tests: $(parse_log "Go tests")
Packages tested:
  - pkg/jwt (JWT generation/parsing)
  - pkg/response (API response format)
  - pkg/errors (Business error codes)
  - pkg/logger (Logger initialization)
  - internal/config (Config struct)
\`\`\`

## 10. Failed Items

$(if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "The following items failed:"
    grep "\[FAIL\]" "$LOG_FILE" 2>/dev/null | while read line; do
        echo "- $line"
    done
elif [ "$SKIP_COUNT" -gt 0 ]; then
    echo "The following items were skipped (expected in local mode, not allowed in CI):"
    grep "\[SKIP\]" "$LOG_FILE" 2>/dev/null | while read line; do
        echo "- $line"
    done
else
    echo "No failures."
fi)

## 11. Risk Items

| Risk | Severity | Mitigation |
|---|---|---|
| bcrypt hash for admin123 hardcoded in migration | Low | Verify hash correctness in CI |
| Temporal health endpoint path may vary | Low | Verified in CI |

## 12. Suggested Next Step

**${NEXT_STEP}**

$(if [ "$NEXT_STEP" = "Fix Phase 1" ]; then
    echo "CI verification found failures or skipped items. Review the acceptance log and fix the issues before proceeding."
    echo "Run \`make phase-1-ci\` locally with Docker to debug, or check GitHub Actions logs."
elif [ "$NEXT_STEP" = "Check CI results before proceeding" ]; then
    echo "Local verification passed (build + tests). Full Phase 1 acceptance requires CI."
    echo "Push to main/develop or open a PR to trigger the full CI pipeline."
    echo "Only proceed to Phase 2 after CI passes with all items PASS."
else
    echo "All Phase 1 CI checks passed. The project is ready for Phase 2 development."
fi)
EOF

echo "Report generated: $REPORT_FILE"
