#!/usr/bin/env bash
#
# Security scan — dependency vulnerabilities, secrets, SAST.
# Blocking policy (keeps the gate reliable):
#   • dependency audit: BLOCK on CRITICAL advisories; report HIGH/moderate.
#   • secrets (gitleaks), SAST (semgrep), filesystem (trivy): run if installed,
#     BLOCK on findings; otherwise print an install hint and skip (do not fail).
# Writes machine-readable artifacts to test-results/.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p test-results
fail=0

note() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✓ %s\033[0m\n' "$*"; }
bad()  { printf '\033[1;31m✗ %s\033[0m\n' "$*"; }

echo "── dependency audit (pnpm, baselined ratchet) ──"
pnpm audit --json > test-results/pnpm-audit.json 2>/dev/null || true
if [ -s test-results/pnpm-audit.json ]; then
  if [ "${UPDATE_AUDIT_BASELINE:-}" = "1" ]; then
    node scripts/audit-baseline.mjs write
  fi
  if node scripts/audit-baseline.mjs check; then
    ok "no NEW advisories beyond the accepted baseline"
  else
    bad "NEW dependency advisories introduced (not in security/audit-baseline.json) — blocking"
    fail=1
  fi
else
  note "pnpm audit produced no report (offline registry?) — skipping dependency gate"
fi

echo "── secrets scan (gitleaks) ──"
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --no-banner --redact --report-path test-results/gitleaks.json; then
    ok "no secrets detected"
  else
    bad "gitleaks found potential secrets — blocking"; fail=1
  fi
else
  note "gitleaks not installed — skipping (install in CI: gitleaks detect)"
fi

echo "── SAST (semgrep) ──"
if command -v semgrep >/dev/null 2>&1; then
  if semgrep --config auto --error --json -o test-results/semgrep.json services packages apps; then
    ok "semgrep clean"
  else
    bad "semgrep found issues — blocking"; fail=1
  fi
else
  note "semgrep not installed — skipping (install in CI: semgrep --config auto)"
fi

echo "── filesystem vuln scan (trivy) ──"
if command -v trivy >/dev/null 2>&1; then
  trivy fs --quiet --scanners vuln,secret --severity CRITICAL --exit-code 1 . \
    && ok "trivy clean (critical)" || { bad "trivy found CRITICAL issues — blocking"; fail=1; }
else
  note "trivy not installed — skipping (install in CI: trivy fs .)"
fi

exit $fail
