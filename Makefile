# DealDrop test harness — canonical, tiered entry points.
# Each target shells into scripts/test.sh, which fixes seeds + TZ, emits JUnit,
# and exits non-zero on any failure. See TESTING.md for the full contract.

.DEFAULT_GOAL := help
.PHONY: help test-smoke test-unit test-gate test-full test-changed test-flaky security-scan coverage

help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

test-smoke: ## seconds — boot + critical health
	@bash scripts/test.sh smoke

test-unit: ## fast — pure-logic unit tests (every commit)
	@bash scripts/test.sh unit

test-gate: ## <10 min — PRE-MERGE GATE (typecheck+lint+unit/integration/contract/smoke/security+coverage). Blocks merge.
	@bash scripts/test.sh gate

test-full: ## nightly/on-demand — everything incl. e2e-browser, k6 load, mutation
	@bash scripts/test.sh full

test-changed: ## fast — only tests affected by the current diff
	@bash scripts/test.sh changed

test-flaky: ## rerun failures + quarantine report (flake detection)
	@bash scripts/flaky-detect.sh

security-scan: ## dependency audit + secrets + SAST (degrades if tools absent)
	@bash scripts/security-scan.sh

coverage: ## run the full vitest suite with coverage + ratchet thresholds
	@JUNIT=1 pnpm --filter @dealdrop/tests exec vitest run --coverage
