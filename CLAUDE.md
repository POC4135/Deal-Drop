# Hapora (formerly DealDrop) — Claude Code Context

## Project Overview
Hapora is a Flutter web app (deployed on Vercel) for discovering verified local deals in Atlanta. It consists of:
- **`apps/mobile_flutter/`** — Flutter web frontend (`deploy/vercel-web` branch)
- **`services/api/`** — Fastify 5 + TypeScript backend
- **`packages/config/`** — Shared config/schema package
- **`packages/dealdrop_design_tokens/`** — Flutter design system

## Running Locally
**API:**
```bash
cd services/api && pnpm dev
```
**Flutter web:**
```bash
cd apps/mobile_flutter && ./run_web_dev.sh
```
> `run_web_dev.sh` reads from `.env.local` (gitignored). Copy `.env.local.example` and fill in keys.

## Architecture Decisions
- **Auth:** Supabase Auth (email/password). JWT verified server-side via JWKS. `USE_DEV_AUTH=false` in `services/api/.env`.
- **DB:** PostgreSQL 17 + PostGIS via Supabase. ORM: Drizzle. Platform: `PostgresDealDropPlatform`.
- **URL strategy:** Path-based (`usePathUrlStrategy()` in `main.dart`) — required for Supabase email redirect links to work. Vercel `vercel.json` has the `/(.*) → index.html` rewrite.
- **Feed sections:** `live-now`, `tonight`, `cheap-eats`, `fresh-this-week` — each filtered independently from the full listing pool (not paginated slice). 20 items per section max.
- **Seed data:** Removed from DB. Seed listings only surface as the Flutter offline fallback (`_fallbackDealCards` in `dealdrop_repository.dart`).

## Key Files
| File | Purpose |
|------|---------|
| `services/api/src/bootstrap/postgres-platform.ts` | All DB queries, feed logic, bootstrap |
| `services/api/src/plugins/auth.ts` | Supabase JWT verification middleware |
| `apps/mobile_flutter/lib/src/core/services/dealdrop_repository.dart` | All API calls + offline fallback |
| `apps/mobile_flutter/lib/src/core/services/app_providers.dart` | Riverpod auth controller |
| `apps/mobile_flutter/lib/src/features/auth/presentation/auth_form_screen.dart` | Sign-in/sign-up UI |
| `apps/mobile_flutter/lib/src/app/router/app_router.dart` | go_router routes |
| `packages/config/src/index.ts` | JWT claim schema (`authClaimSchema`) |

## Auth Flow
1. Sign-up → Supabase creates auth user → app calls `POST /v1/auth/bootstrap` → upserts `users` + `user_profiles`
2. Sign-in → Supabase returns JWT → bootstrap resolves display name from `user_metadata`
3. Email confirmation → redirects to `/auth/confirmed` → `EmailConfirmedScreen`
4. Duplicate email: detected via empty `identities` (confirm on) or `AuthApiException` (confirm off)
5. Bootstrap orphan cleanup: if same email exists with different ID (re-registration after Supabase deletion), cascades-deletes old user rows before inserting new

## Supabase Configuration (Dashboard)
- **Auth → Email → Confirm email:** Currently OFF for dev testing. Re-enable before production.
- **Auth → URL Configuration → Redirect URLs:** Add production domain before going live.
- **Allowed redirect URL for email confirmation:** Uses `Uri.base.resolve('/auth/confirmed')` — auto-adapts to current domain, no code change needed on deploy.

## Test Accounts
- `alex@dealdrop.app` / `dealdrop123` — exists in Supabase Auth + DB, linked to historical seed data (Alex Morgan, West Midtown)
- Create new accounts via the app sign-up flow

## Known Gotchas
- Deleting a user from Supabase Auth dashboard does NOT delete their row from the `users` table. Use the bootstrap orphan cleanup (automatic on next sign-in) or run the manual cleanup script pattern from `postgres-platform.ts`.
- Feed API has a 90-second cache (`cacheTtls.feedHomeSeconds`). Pull-to-refresh in app invalidates the Riverpod provider but the API response may still be cached — wait 90s or restart API server during dev.
- `run_web_dev.sh` previously had hardcoded API keys committed by mistake (commit `d22ed33`). Google Maps API key was rotated. History not yet rewritten — consider `git filter-repo` if needed.

## TODO — Next Session
- [ ] **Merge `deploy/vercel-web` → `main`**
- [ ] Rewrite git history to purge exposed secrets from commit `d22ed33` (optional, repo is private)
- [ ] Re-enable Supabase email confirmation before production launch
- [ ] Add production domain to Supabase Auth redirect URL allowlist
- [ ] Date/Time filter feature (deferred) — backend `GET /v1/listings/available?date&time` is already built and ready
