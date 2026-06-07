.PHONY: phase-1-local phase-1-ci compose-up compose-down migrate-up migrate-down \
       test run-api verify-phase-1 report-phase-1

# Detect bash path for Windows compatibility
BASH := $(shell which bash 2>/dev/null || echo "C:\\Windows\\System32\\bash.exe")

# =============================================================================
# Phase 1 Targets
# =============================================================================

# phase-1-local: Local-only checks (no Docker required)
phase-1-local: test
	@echo ""
	@echo "=== Phase 1 Local Verification Complete ==="
	@echo "  - Go build:  OK"
	@echo "  - Go tests:  OK"
	@echo ""
	@echo "Full Phase 1 verification runs in GitHub Actions."
	@echo "Push to main/develop or open a PR to trigger CI."
	@echo ""

# phase-1-ci: Full CI pipeline (Docker required, used by GitHub Actions)
phase-1-ci: compose-up migrate-up test verify-phase-1 report-phase-1
	@echo "=== Phase 1 CI Complete ==="

# =============================================================================
# Docker Compose
# =============================================================================

compose-up:
	@echo "=== Starting Docker Compose services ==="
	docker compose -f deployments/docker-compose/docker-compose.yml up -d

compose-down:
	@echo "=== Stopping Docker Compose services ==="
	docker compose -f deployments/docker-compose/docker-compose.yml down

# =============================================================================
# Database Migrations
# =============================================================================

migrate-up:
	@echo "=== Running database migrations ==="
	@for f in migrations/*.up.sql; do \
		echo "Applying $$f..."; \
		PGPASSWORD=papermind psql -h localhost -p 5432 -U papermind -d papermind -f "$$f"; \
	done
	@echo "=== Migrations complete ==="

migrate-down:
	@echo "=== Rolling back database migrations ==="
	@for f in $$(ls -r migrations/*.down.sql); do \
		echo "Applying $$f..."; \
		PGPASSWORD=papermind psql -h localhost -p 5432 -U papermind -d papermind -f "$$f"; \
	done
	@echo "=== Rollback complete ==="

# =============================================================================
# Tests
# =============================================================================

test:
	@echo "=== Running Go tests ==="
	go test ./...

# =============================================================================
# API Server
# =============================================================================

run-api:
	@echo "=== Starting API server ==="
	go run cmd/api/main.go

# =============================================================================
# Verification & Reporting
# =============================================================================

verify-phase-1:
	@echo "=== Running Phase 1 verification ==="
	$(BASH) scripts/verify_phase_1.sh

report-phase-1:
	@echo "=== Generating Phase 1 report ==="
	$(BASH) scripts/generate_phase_1_report.sh
