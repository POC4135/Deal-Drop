# AGENTS.md

Entry point for AI coding agents (Claude Code, Cursor, Copilot, etc.) working in
this repository. Humans: see `README.md` and `TESTING.md`.

## What this repo is

DealDrop — an Atlanta-first local-deal discovery platform. A **pnpm monorepo**:

- `services/api` — Fastify + Drizzle API (the core business logic) and 7 workers.
- `apps/admin_web` — Next.js admin/moderation console. `apps/mobile_flutter` — Flutter app.
- `packages/*` — shared config, types, and the OpenAPI contract (`packages/contracts`).
- `tests/` — the TypeScript test harness (Vitest). Browser e2e in `e2e-browser/`, load in `perf/`.

## Before you propose any merge

Run the pre-merge gate from the repo root and make sure it exits `0`:

```bash
pnpm install      # first time
pnpm test:gate    # == make test-gate  (the required pre-merge check)
```

`test:gate` runs typecheck + lint + the test tiers (unit, characterization,
contract, integration, smoke, security, resilience, property, e2e) + the coverage
ratchet + the dependency/secrets/SAST scan. Other tiers: `pnpm test:smoke`,
`test:unit`, `test:full` (nightly: adds mutation/load/browser), `test:changed`,
`test:flaky`.

## Rules (do not violate)

- **Do not** weaken coverage thresholds (`tests/vitest.config.ts`), the mutation
  threshold (`stryker.conf.json`), or the advisory baseline (`security/audit-baseline.json`)
  to make the gate pass. Fix the cause, or flag it.
- **Do not** delete or skip a failing test to go green. Tests prefixed `FINDING:`
  pin real, known weaknesses on purpose — fixing the code there will fail the test;
  update it deliberately and note it.
- **Do not** make tests touch real external services or production data. Hermetic
  tiers pin the in-memory seed backend; only the integration tier uses a real
  (ephemeral) Postgres.
- Keep tests **deterministic**: frozen clock (`vi.setSystemTime`), fixed seeds,
  cloned seed data for mutating tests, no test-order dependence.

## Where to go next

- **`TESTING.md`** — the full contract: every tier, how to run/write/debug, fixtures,
  thresholds, the known findings, and the **Roadmap (what's left to build)**.
- Branch/PR context: this harness is built on `phase1-base` (PR #3) and is decoupled
  from `main` while `main`'s postgres-only migration is in flight — see TESTING.md ›
  "Note on the branch base".
