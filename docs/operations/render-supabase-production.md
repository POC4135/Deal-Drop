# Render + Supabase Production Runbook

## Services

- API: Render web service, root `services/api`, build `pnpm install && pnpm build`, start `node dist/index.js`.
- Admin web: Render web service, root `apps/admin_web`, build `pnpm install && pnpm build`, start `pnpm start`.
- Workers: Render background workers, root `services/api`, start one of:
  - `pnpm worker:outbox-relay`
  - `pnpm worker:trust`
  - `pnpm worker:gamification`
  - `pnpm worker:leaderboard-refresh`
  - `pnpm worker:stale-scan`
  - `pnpm worker:notifications`

## Required API Env

- `PLATFORM_BACKEND=postgres`
- `USE_DEV_AUTH=false`
- `DATABASE_URL`
- `SUPABASE_URL`
- `SUPABASE_JWKS_URL`
- `SUPABASE_JWT_ISSUER`
- `SUPABASE_JWT_AUDIENCE=authenticated`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_STORAGE_BUCKET=proofs`
- `FCM_PROJECT_ID`
- `FCM_SERVICE_ACCOUNT_JSON`
- `FCM_SERVER_KEY`
- `APNS_KEY_ID`
- `APNS_TEAM_ID`
- `APNS_BUNDLE_ID`
- `APNS_PRIVATE_KEY`

## Required Admin Env

- `DEALDROP_API_BASE_URL`
- `DEALDROP_ADMIN_BEARER_TOKEN`

## Supabase Settings

- Enable asymmetric JWT signing keys so the API can validate access tokens through JWKS.
- Keep app product data behind Fastify; do not expose product tables through Supabase Data API for the mobile app.
- Create the `proofs` Storage bucket for contribution proof uploads.
