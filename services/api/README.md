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
- Drizzle schema plus SQL migration in `migrations/0001_platform_foundation.sql`
- in-memory seed-backed service layer for local contract flow today
- Aurora/PostGIS, Redis, S3, EventBridge, and Cognito infrastructure assumptions baked into config and scripts

## Local auth note

The current local seed auth flow is only intended to validate mobile-to-API integration while the real identity layer is pending.

- `alex@dealdrop.app` / `dealdrop123`
- `maya@dealdrop.app` / `dealdrop123`
- `jon@dealdrop.app` / `dealdrop123`
- `sam@dealdrop.app` / `dealdrop123`

Production auth is still pending on Cognito-backed JWT validation and should not reuse this local seed mechanism.

## Backend work still pending for production

- replace the seed-backed platform service with real repositories over PostgreSQL / PostGIS
- wire real Cognito JWT verification instead of `x-dev-*` auth headers
- replace local proof-upload placeholders with real S3 upload finalize flows
- validate Redis, outbox relay, EventBridge, SQS, DLQs, and workers against real AWS infrastructure
- persist telemetry and notification delivery state in production-grade storage
- wire the admin web shell to live admin APIs instead of mock data
- run the Node.js, worker, and migration test suites once `node`/`pnpm` are installed in the workspace

## Useful commands

- `pnpm --filter @dealdrop/api dev`
- `pnpm --filter @dealdrop/api db:migrate`
- `pnpm --filter @dealdrop/api db:seed`
- `pnpm --filter @dealdrop/api test`

## Contract

The public API contract source of truth is [`packages/contracts/openapi/dealdrop.v1.yaml`](../../packages/contracts/openapi/dealdrop.v1.yaml).
