# DealDrop API

Fastify modular monolith for the DealDrop platform foundation.

## Implemented domains

- identity and profile/karma access
- venues and listings
- discovery feed, nearby, live-now, tonight, search, and map-bounds queries
- favorites
- contributions and proof-upload presign flow
- reporting and stale-trust hooks
- moderation/admin queue reads
- trust/confidence engine foundation
- gamification and leaderboard foundation
- audit/event listing foundation

## Runtime shape

- Fastify HTTP layer
- Drizzle schema plus additive SQL migrations in `migrations/`
- selectable platform backend: `PLATFORM_BACKEND=seed` for local contract tests, `PLATFORM_BACKEND=postgres` for Supabase Postgres
- Supabase Auth JWT verification, Supabase Storage proof-upload slots, Firebase Cloud Messaging delivery, Postgres outbox workers, and Render-oriented deployment envs

## Auth note

Production auth is Supabase Auth. Mobile/admin clients authenticate with Supabase and send `Authorization: Bearer <access token>` to the API. The API verifies the Supabase JWT and reads DealDrop roles from the `users` table.

The local seed auth flow is still available only when `USE_DEV_AUTH=true`.

- `alex@dealdrop.app` / `dealdrop123`
- `maya@dealdrop.app` / `dealdrop123`
- `jon@dealdrop.app` / `dealdrop123`
- `sam@dealdrop.app` / `dealdrop123`

## Backend work still pending for production hardening

- validate all Postgres repository paths against the live Supabase staging database
- replace the signed-upload placeholder URL with a service-role Supabase Storage signed-upload call
- add rate limiting and abuse controls around auth-adjacent and contribution endpoints
- run the Node.js, worker, and migration test suites once `node`/`pnpm` are installed in the workspace

## Useful commands

- `pnpm --filter @dealdrop/api dev`
- `pnpm --filter @dealdrop/api db:migrate`
- `pnpm --filter @dealdrop/api db:seed`
- `pnpm --filter @dealdrop/api test`

## Contract

The public API contract source of truth is [`packages/contracts/openapi/dealdrop.v1.yaml`](../../packages/contracts/openapi/dealdrop.v1.yaml).
