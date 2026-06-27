# Testing

This document is the contract for how DealDrop is tested. It covers the testing
philosophy, every test category, how to run and write tests, the thresholds the
pre-merge gate enforces, and how to debug failures.

> **For an AI agent / automated reviewer:** before proposing any merge, run
> **`pnpm test:gate`** (or `make test-gate`) from the repo root and ensure it
> exits `0`. That single command is the pre-merge gate — typecheck, lint,
> unit/characterization/contract/integration/smoke/security/resilience/property/
> e2e tiers, the coverage ratchet, and the dependency/secrets/SAST scan. Do not
> propose a merge if it is red. Do not weaken thresholds or delete a failing
> test to make it pass — fix the cause or flag it.

---

## Philosophy & the pyramid

We test in tiers, most tests at the bottom, few at the top:

```
        ▲  e2e (API journeys; opt-in browser e2e + a11y)
       ───  contract (OpenAPI ⇄ routes)
      ─────  integration (real Postgres/PostGIS, CI)
    ─────────  characterization (golden masters of current behavior)
  ─────────────  unit (pure logic, edges, property/fuzz)
 smoke ──────── (boot + health; seconds)
```

Principles, enforced in code:

- **Deterministic.** No real wall-clock (frozen via `vi.setSystemTime`), no real
  network (mocked at the boundary), fixed seeds (`fast-check` runs with a pinned
  seed), no test-order dependence (mutating tests clone the seed). `TZ=UTC` is
  fixed globally (`tests/support/setup.ts`).
- **Behavior, not mocks.** Internal logic is exercised for real; only true
  external boundaries (Slack/FCM/Storage, the DB for hermetic tiers) are mocked.
- **No retry-to-green.** Flakes are defects; `scripts/flaky-detect.sh` surfaces
  and quarantines them instead of hiding them.

---

## Test categories & layout

All TypeScript tests live under `tests/` (the `@dealdrop/tests` workspace) and run
on **Vitest**. Config: `tests/vitest.config.ts` (root is the repo so coverage can
see app source). Browser tests live under `e2e-browser/` (Playwright) and load
scripts under `perf/` (k6).

| Dir | Tier | What it covers | Runs where |
|---|---|---|---|
| `tests/unit/` | unit | Pure logic: geo, pagination, cache, events, config — edges, null/empty/malformed | anywhere |
| `tests/characterization/` | characterization | Golden masters pinning **current** behavior of high-risk paths (trust/gamification engines, auth/RBAC matrix, read-route shapes, seed-auth) | anywhere |
| `tests/contract/` | contract | OpenAPI (`packages/contracts/openapi/dealdrop.v1.yaml`) ⇄ registered routes; critical endpoints + coverage drift | anywhere |
| `tests/smoke/` | smoke | App boots, health probes, critical public endpoints respond | anywhere |
| `tests/e2e/` | e2e | Critical request→response journeys via `app.inject()` | anywhere |
| `tests/security/` | security | Access control, sensitive-data exposure, injection resistance, info disclosure | anywhere |
| `tests/resilience/` | resilience | External dependency down/slow/garbage (Slack webhook), graceful degradation | anywhere |
| `tests/property/` | property/fuzz | Invariants over generated input (fast-check, fixed seed) | anywhere |
| `tests/integration/` | integration | **Real Postgres + PostGIS**: schema, migrations, constraints, geo, idempotency. Writes are rolled back | CI / local DB only — skips otherwise |
| `tests/{api,admin,trust,gamification,geospatial,migrations,workers}/` | mixed | Pre-existing suites (kept and extended) | anywhere |
| `e2e-browser/` | e2e (browser) | Playwright smoke + axe a11y against a running admin web | opt-in (`E2E_BASE_URL`) |
| `perf/` | load | k6 load/soak with performance budgets | opt-in (`scripts/load.sh`) |

---

## Running tests (copy-paste)

```bash
pnpm install                  # once

pnpm test:smoke               # seconds — boot + health
pnpm test:unit                # fast — pure logic
pnpm test:gate                # THE PRE-MERGE GATE (single-digit minutes)
pnpm test:full                # everything incl. mutation (nightly/on-demand)
pnpm test:changed             # only tests affected by the current diff
pnpm test:flaky               # rerun failures + quarantine report

make test-gate                # identical via Makefile; `make help` lists targets
```

Useful direct invocations:

```bash
# one tier
pnpm --filter @dealdrop/tests exec vitest run tests/unit
# watch mode while iterating
pnpm --filter @dealdrop/tests exec vitest tests/security
# coverage + ratchet
make coverage
# mutation score on core logic
pnpm exec stryker run            # or: MUTATE=services/api/src/modules/trust/engine.ts scripts/mutation.sh
```

**Integration tier** runs only when a Postgres/PostGIS database is reachable via
`DATABASE_URL` and has been migrated + seeded. Locally:

```bash
docker compose -f infra/local/docker-compose.yml up -d
pnpm --filter @dealdrop/api db:migrate && pnpm --filter @dealdrop/api db:seed
pnpm --filter @dealdrop/tests exec vitest run tests/integration
```

Without a database it **skips cleanly** (this is expected on machines without PostGIS).

---

## Writing a new test

Use the shared helpers in `tests/support/app.ts` (`buildSeedApp`, `asRole`, `SEED`).

**Unit** (`tests/unit/…test.ts`):
```ts
import { describe, expect, it } from 'vitest';
import { haversineDistanceMiles } from '../../services/api/src/lib/geo.js';
it('is zero for identical points', () => {
  expect(haversineDistanceMiles(33.78, -84.4, 33.78, -84.4)).toBe(0);
});
```

**Route / e2e** (hermetic, no DB):
```ts
import { buildSeedApp, asRole } from '../support/app.js';
const app = await buildSeedApp();
const res = await app.inject({ method: 'GET', url: '/v1/me/profile', headers: asRole('user') });
expect(res.statusCode).toBe(200);
```

**Time-dependent logic** — freeze the clock:
```ts
beforeEach(() => { vi.useFakeTimers(); vi.setSystemTime(new Date('2026-04-15T12:00:00Z')); });
afterEach(() => vi.useRealTimers());
```

**Mutating state** — clone the seed so tests stay isolated:
```ts
import { freshSeed } from '../characterization/_support.js';
const platform = new DealDropPlatform(freshSeed());
```

**Property** — pin the seed:
```ts
fc.assert(fc.property(fc.string({ minLength: 1 }), (s) => decode(encode(s)) === s), { seed: 0xdea1d309, numRuns: 300 });
```

**Integration** — guard on availability and roll back writes (see
`tests/integration/postgres.integration.test.ts` for the pattern).

---

## Fixtures, factories & seed data

- The **in-memory seed dataset** (`services/api/src/db/seeds/atlanta.ts`, exported
  as `atlantaSeed`) backs all hermetic tiers. It is a module singleton that the
  `DealDropPlatform` mutates, so **clone it** with `freshSeed()`
  (`structuredClone`) in any test that writes. Stable ids: `usr_alex`,
  `lst_taco_tuesday`, `ven_taqueria_del_sol` (see `SEED` in `tests/support/app.ts`).
- Hermetic tiers pin `PLATFORM_BACKEND=seed` + `USE_DEV_AUTH=true` so they never
  touch a database, regardless of the ambient environment.
- The **real DB** for the integration tier is populated by `db:migrate` + `db:seed`.

---

## Debugging a failing or flaky test

- **Read the assertion**, then run just that file: `vitest run tests/<dir>/<file>`.
- **Snapshot diffs** (golden masters): if the change is intended, update with
  `vitest run -u <file>` and review the diff carefully — a snapshot change is a
  behavior change.
- **Flaky?** `pnpm test:flaky` reruns failures once; anything that flips to passing
  is written to `test-results/quarantine.json`. Treat flakes as defects: find the
  shared state / clock / ordering assumption and remove it. Do not add retries.
- **Determinism check**: run a suite twice; output must be identical. Most flakes
  here come from an unfrozen clock or a mutated shared seed.

---

## Thresholds & how to change them

**Coverage (ratchet)** — `tests/vitest.config.ts › test.coverage.thresholds`.
Baseline (Phase 2): statements 67.3 / branches 84.2 / functions 71.9 / lines 67.3;
floors are set just under that (65 / 78 / 68 / 65). **Raise them as coverage grows;
never lower them.** Scope excludes the postgres-platform, workers, and db scripts
(covered by the integration tier / worker smoke) to keep the number honest.

**Mutation** — `stryker.conf.json › thresholds` (`break: 50`). Current core score:
**90.45%** (geo 100, pagination 92, trust 94.4, gamification 85.5). A green suite
with a low mutation score is a warning sign; investigate survivors before merging.

**Dependency advisories (ratchet)** — `security/audit-baseline.json` records the
known, pre-existing advisories. The scan blocks only on **newly introduced** ones.
After deliberately upgrading deps, regenerate with
`UPDATE_AUDIT_BASELINE=1 pnpm security:scan` and review the diff.

**Performance budgets** — `perf/api-smoke.js › options.thresholds` (e.g. feed
p95 < 400ms). A regression past budget fails k6.

---

## What the pre-merge gate enforces

`pnpm test:gate` runs, in order, and fails on any error:

1. **typecheck** — `pnpm typecheck` across the workspace.
2. **lint** — best-effort (non-blocking until an ESLint config lands; `next lint`
   is not yet configured for the admin app).
3. **tests + coverage ratchet** — unit, characterization, contract, smoke,
   security, resilience, property, e2e, integration (real DB in CI), plus the
   pre-existing suites, under the coverage floors above.
4. **security scan** — `pnpm audit` against the baseline ratchet; gitleaks /
   semgrep / trivy run if installed (blocking on findings), else skipped with a
   notice.

Machine-readable output: JUnit at `test-results/junit.xml`, coverage at
`tests/coverage/` (+ `lcov.info`), audit at `test-results/pnpm-audit.json`.

### Branch protection guidance (for `main`)

In **Settings → Branches → Branch protection rules** for `main`:

- Require status check **`test:gate (pre-merge)`** (from `.github/workflows/test-harness.yml`) to pass before merge.
- Require branches to be up to date before merging.
- Do not allow the gate to be bypassed; coverage and the advisory baseline are
  ratchets — they may improve, never regress.

The legacy `.github/workflows/production-readiness.yml` also runs; its `flutter`
job currently fails on missing `SUPABASE_*` repository secrets (unrelated to this
harness — configure those secrets to make it pass).

---

## Known findings (pinned, not hidden)

The harness documents real weaknesses in the current **dev/seed** backend by
pinning them in `tests/security/access-and-exposure.test.ts` and
`tests/resilience/external-deps.test.ts` (tests prefixed `FINDING:`). They keep
the gate green while ensuring any change (a fix, or a regression) is caught.

1. `GET /v1/me/profile` and `POST /v1/auth/sign-in` return the `password` field in
   plaintext (sensitive-data exposure).
2. An unknown authenticated user id falls back to another user's profile
   (broken object-level authorization).
3. Validation (zod) errors surface as HTTP **500** instead of 400 (no `statusCode`
   mapping in the error handler).
4. Dev auth (`USE_DEV_AUTH=true`) treats a header-less request to a protected route
   as a fully-privileged **admin**.
5. The feedback→Slack call has no error handling/circuit-breaker; a webhook failure
   surfaces as 500.

These are dev/seed-backend behaviors and should be resolved as part of the
postgres-only migration (see below). Fixing any of them will fail its pinned test —
update the test deliberately at that point.

---

## Note on the branch base

This harness is built on `phase1-base` (the pre-migration commit) and its PR
targets that branch, not `main`. `main` is mid-migration to a postgres-only
backend (removing the in-memory seed backend these hermetic tiers rely on) and is
currently red on its own gate. When that migration lands, the hermetic tiers will
be re-pointed at an ephemeral real Postgres and the seed-specific findings above
will be revisited.
