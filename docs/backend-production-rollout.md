# Backend Pending For Production Rollout

> Status update: this document was moved from the repo root during the Supabase + Render production pass. The selected production direction is now Supabase Auth/Postgres/Storage, Render-hosted API/admin/workers, and Postgres-backed outbox workers. Older Cognito/EventBridge/SQS references below are retained as historical pending-work context until each section is rewritten around the selected stack.

## Purpose

This document defines the backend that the current DealDrop mobile app is already prepared to talk to, what is still missing before the system is production-ready, and the order in which the remaining work should be completed.

It is written from the app-contract point of view, not from the current backend scaffold point of view.

The key rule is simple:

- the mobile app is already integrated against a specific API shape and a specific set of product semantics
- the production backend must preserve those semantics exactly unless the mobile app is updated in lockstep

Primary contract sources:

- `packages/contracts/openapi/dealdrop.v1.yaml`
- `packages/shared_types/src/index.ts`
- `apps/mobile_flutter/lib/src/core/services/dealdrop_repository.dart`
- `packages/config/src/index.ts`

## Executive Summary

The mobile app is no longer a pure mock client. It already expects:

- public discovery reads
- email/password auth endpoints
- authenticated profile, Karma, contribution, favorites, notifications, and preference endpoints
- map-bounds and search endpoints with real query parameters
- idempotent write endpoints
- trust-state and gamification semantics that are visible in the UI
- a notification inbox plus device registration
- a telemetry ingest endpoint

The current backend foundation is good enough for local integration and product development, but it is not yet a production backend.

The biggest rollout blockers are:

1. The service layer is still seed-backed and in-memory.
2. Real auth/JWT validation is not wired.
3. The database schema is not fully aligned with the mobile/shared contract.
4. Notifications, device registration, and telemetry are not yet backed by durable storage and delivery pipelines.
5. Workers, cache, queues, and infrastructure have not been validated end-to-end against real AWS services.

## What The Mobile App Already Expects

### Public, unauthenticated endpoints

These endpoints must remain callable without auth:

| Endpoint | Method | Used For |
| --- | --- | --- |
| `/v1/feed/home` | `GET` | Deals feed sections on the primary home surface |
| `/v1/listings/live-now` | `GET` | Live-now discovery slices |
| `/v1/listings/tonight` | `GET` | Tonight discovery slices |
| `/v1/listings/nearby` | `GET` | Nearby alternative listings |
| `/v1/listings/map-bounds` | `GET` | Viewport-driven map loading |
| `/v1/search` | `GET` | Search results and suggestions |
| `/v1/filters/metadata` | `GET` | Search/filter sheet metadata |
| `/v1/listings/:listingId` | `GET` | Listing detail screen |
| `/v1/venues/:venueId` | `GET` | Venue detail payloads |

Required query behavior:

- `/v1/search` supports `q`, `neighborhood`, `trustBand`, `sort`, `cursor`, `limit`
- `/v1/listings/map-bounds` supports `north`, `south`, `east`, `west`, `zoom`, `trustBand`
- `/v1/listings/nearby` supports `latitude`, `longitude`, `radiusMiles`, `cursor`, `limit`

### Auth endpoints

The app currently expects email/password auth with these endpoints:

| Endpoint | Method | Used For |
| --- | --- | --- |
| `/v1/auth/sign-in` | `POST` | Sign in flow |
| `/v1/auth/sign-up` | `POST` | Account creation flow |

Expected behavior:

- `401` on invalid credentials
- `409` on duplicate sign-up email
- a stable auth response shape containing `session` and `profile`
- email/password remains the visible UX even if Cognito is the underlying provider

### Authenticated read endpoints

| Endpoint | Method | Used For |
| --- | --- | --- |
| `/v1/me/profile` | `GET` | Profile screen |
| `/v1/me/karma` | `GET` | Karma summary and progression |
| `/v1/me/contributions` | `GET` | Contribution history |
| `/v1/me/saved` | `GET` | Saved deals |
| `/v1/leaderboards` | `GET` | Leaderboard screen |
| `/v1/notifications` | `GET` | Notification inbox |
| `/v1/me/preferences` | `GET` | Notification/settings toggles |

Required semantics:

- `/v1/me/karma` supports `window=daily|weekly|all_time`
- `/v1/leaderboards` supports `window=daily|weekly|all_time`
- notifications must return `items` plus `unreadCount`
- preferences must match app toggles exactly

### Authenticated write endpoints

| Endpoint | Method | Used For |
| --- | --- | --- |
| `/v1/favorites/:listingId` | `POST` | Save listing |
| `/v1/favorites/:listingId` | `DELETE` | Unsave listing |
| `/v1/favorites/sync` | `POST` | Merge guest-local saves after sign-in |
| `/v1/contributions/listings` | `POST` | Suggest new listing |
| `/v1/contributions/listings/:listingId/update` | `POST` | Suggest update |
| `/v1/listings/:listingId/confirm` | `POST` | Confirm valid |
| `/v1/listings/:listingId/report-expired` | `POST` | Report expired/incorrect |
| `/v1/contributions/proofs/presign` | `POST` | Request proof-upload target |
| `/v1/notifications/:notificationId/read` | `POST` | Mark inbox item read |
| `/v1/me/preferences` | `PUT` | Update preferences |
| `/v1/devices/register` | `POST` | Register device/push token |
| `/v1/devices/:deviceId` | `DELETE` | Unregister device |
| `/v1/telemetry/events` | `POST` | Ingest app analytics/log events |

Required write behavior:

- writes must be idempotent or duplicate-safe
- `401` must only mean auth/session failure
- non-`401` transient failures may be retried by the app later
- write endpoints must not double-award points or double-create contributions when replayed

### Product semantics the backend must preserve

#### Trust bands

The app already renders and reasons about these exact values:

- `founder_verified`
- `merchant_confirmed`
- `user_confirmed`
- `recently_updated`
- `needs_recheck`
- `disputed`

These are not cosmetic labels only. They drive UI tone, explanation copy, and trust messaging.

#### Contribution states

The app expects:

- contribution types: `new_listing`, `listing_update`, `confirm_valid`, `report_expired`
- contribution statuses: `submitted`, `needs_proof`, `under_review`, `approved`, `rejected`, `merged`
- points states: `pending`, `finalized`, `reversed`

#### Notification kinds

The app expects:

- `contribution_resolved`
- `points_finalized`
- `trust_status_changed`
- `listing_reported_stale`
- `moderation_update`

#### Leaderboard windows

The app expects:

- `daily`
- `weekly`
- `all_time`

## Current Backend State

The current backend foundation provides:

- a Fastify modular monolith
- route definitions for public and authenticated app surfaces
- shared types and OpenAPI contract files
- a seed-backed platform service for local contract flow
- a Drizzle/Postgres schema foundation
- local infra scaffolding with Docker Compose
- Terraform module skeletons for AWS deployment
- queue worker entrypoints and naming conventions

The current backend does **not** yet provide a fully production-capable runtime.

In practical terms, the current system is:

- suitable for local integration, contract development, admin shape work, and mobile UI wiring
- not suitable for real production traffic, real auth, real push, or persistent state guarantees

## Known Contract And Schema Drift

These are important because they will break or degrade a real DB-backed rollout if not fixed first.

### 1. Trust-band enum drift

Current shared/mobile contract expects:

- `founder_verified`
- `merchant_confirmed`
- `user_confirmed`
- `recently_updated`
- `needs_recheck`
- `disputed`

Current database enum in `services/api/src/db/schema/index.ts` only includes:

- `founder_verified`
- `user_confirmed`
- `recently_updated`
- `needs_recheck`

Missing:

- `merchant_confirmed`
- `disputed`

This must be fixed before persistence is wired.

### 2. Contribution-type enum drift

The app and shared types use:

- `new_listing`
- `listing_update`
- `confirm_valid`
- `report_expired`

The database enum currently does not include `report_expired`.

This will break report-expired persistence once the backend stops using seed-only storage.

### 3. Notification preference drift

Shared/mobile preferences include:

- `contributionResolved`
- `pointsFinalized`
- `trustStatusChanged`
- `marketingAnnouncements`

The database schema currently covers the first three but does not persist `marketingAnnouncements`.

### 4. Missing persistent inbox and device registration model

The app contract already supports:

- notification inbox reads
- notification read state
- device registration
- device unregister

The current schema does not yet define:

- a durable notification inbox table
- a device registration / push token table
- notification delivery tracking

### 5. Missing telemetry persistence model

The app already sends batched telemetry events.

The schema does not yet define:

- telemetry event storage
- analytics queue/projector
- retention policy
- analytics aggregation outputs

## Detailed Pending Work By Backend Domain

## 1. Identity And Auth

### Required production state

- Cognito-backed auth or equivalent identity provider
- JWT verification in Fastify
- proper access token / refresh token flow
- role claims for `user`, `moderator`, and `admin`
- token expiry, revocation, and session invalidation behavior
- device/session auditing

### Pending tasks

- replace `x-dev-*` auth headers with bearer/JWT verification
- map Cognito groups to app roles consistently
- support email/password flows while preserving current app UX
- define token refresh strategy used by mobile
- persist device sessions and optionally last-seen metadata
- add admin audit coverage for privileged actions

### Production-readiness requirement

The mobile client must be able to stop using dev auth headers without changing its screen flows or response shapes.

## 2. Persistence Layer

### Required production state

- PostgreSQL as source of truth
- PostGIS for geospatial queries
- repository layer behind the current platform service
- migration-safe schema evolution
- reproducible seeds for dev/staging only

### Pending tasks

- replace the seed-backed `DealDropPlatform` with repository-backed reads and writes
- resolve all enum drift before the first real migration wave
- add missing tables for notification inbox, device registrations, and telemetry persistence
- validate indexes for feed, search, saved, moderation queue, leaderboard, and stale-scan paths
- implement soft-delete/archive strategy consistently
- validate idempotency key storage and expiration

### Production-readiness requirement

Every app-facing endpoint must operate correctly when the seed dataset is removed.

## 3. Discovery, Search, And Map Reads

### Required production state

- fast public reads
- cursor-safe list endpoints
- PostGIS-backed nearby and bounds queries
- search suggestions and ranking
- saved/favorite overlay support for authenticated users

### Pending tasks

- implement real repository queries for feed sections
- build/refresh search documents from listings and venues
- add real `tsvector` / trigram support or equivalent
- validate `map-bounds` performance under frequent viewport changes
- ensure reads degrade gracefully when Redis is unavailable
- verify correct trust-band filtering semantics in search and map

### Production-readiness requirement

These endpoints must remain public and fast because the app allows guest browsing.

## 4. Favorites And Guest Save Sync

### Required production state

- guest-local favorites merge safely after sign-in
- authenticated favorites persist durably
- favorite writes are idempotent
- favorite changes invalidate or refresh relevant read caches

### Pending tasks

- validate merge semantics in persistence layer
- ensure duplicate sync calls never duplicate rows
- verify saved state is consistent across feed, search, detail, map, and saved screen
- confirm cross-device consistency once real auth is in place

### Production-readiness requirement

The app already uses guest-local saves. The backend must merge them safely without data loss or duplicate state.

## 5. Contributions, Reports, And Proofs

### Required production state

- moderated contributions
- stale/expired reports
- proof-upload lifecycle
- duplicate-merge workflows
- admin review visibility

### Pending tasks

- persist all contribution types, including `report_expired`
- implement proof-upload finalize/attach workflow after presign
- add moderation state transitions with audit records
- add duplicate-detection and merge-target behavior
- ensure contribution write endpoints remain idempotent
- prevent duplicate points awards when offline writes replay
- define source-of-truth behavior for conflicting update vs report signals

### Production-readiness requirement

The app already exposes contribution UX end-to-end. The backend must make those actions durable, reviewable, and duplicate-safe.

## 6. Trust And Confidence Engine

### Required production state

- confidence recomputation outside request paths where practical
- trust snapshots and visibility decisions
- stale scans and recheck scheduling
- moderator overrides
- conflict handling for disputed listings

### Pending tasks

- wire trust recompute off outbox/event flow instead of seed-only mutation logic
- persist `verification_events`, `trust_signals`, and `confidence_snapshots`
- validate score thresholds against real data
- implement stale scan worker behavior and thresholds
- expose trustworthy explanations for every public trust state

### Production-readiness requirement

Trust labels are product-critical. They must be reproducible, explainable, and not double-count confirmations or reports.

## 7. Gamification, Karma, And Leaderboards

### Required production state

- immutable ledger
- pending vs finalized points
- streak computation
- badge unlocks
- leaderboard snapshotting or reliable live derivation
- moderation-aware reversals and adjustments

### Pending tasks

- persist and validate the points ledger under replay conditions
- prevent double-awards when contribution writes retry
- define reversal semantics for rejected or merged contributions
- persist streak checkpoints and badge unlock history
- build leaderboard snapshot jobs or optimized live aggregation
- validate the impact metrics shown in the UI

### Production-readiness requirement

The backend must guarantee that Karma totals are consistent across:

- profile
- Karma screen
- contribution history
- moderation outcomes
- leaderboard ranking

## 8. Notifications And Push

### Required production state

- durable notification inbox
- read/unread state
- device registration store
- FCM/APNs dispatch workers
- preference enforcement
- retry and delivery visibility

### Pending tasks

- add notification inbox table
- add device registration table
- wire preference checks before enqueueing notifications
- integrate FCM/APNs credentials and dispatch logic
- persist delivery attempts and failures
- support deep-link payloads compatible with the mobile app

### Production-readiness requirement

The app already has an inbox and expects push registration to exist. Production rollout requires both durable inbox state and real outbound delivery.

## 9. Telemetry And Analytics

### Required production state

- durable telemetry ingest
- retention policy
- operational dashboards
- failure isolation so analytics never break the app

### Pending tasks

- define storage target for telemetry events
- keep ingest cheap and non-blocking
- redact or constrain PII in event payloads
- expose useful product and operational dashboards
- add alerting for ingest failures if telemetry becomes operationally important

### Production-readiness requirement

The mobile app already emits telemetry events. The backend must accept them safely, store them durably, and avoid coupling analytics failures to core app flows.

## 10. Cache Layer

### Required production state

- Redis-backed cache
- stable key versioning
- precise invalidation
- safe fallback when cache is cold or unavailable

### Pending tasks

- replace in-memory cache store with Redis
- validate key namespaces against current `packages/config` cache strategy
- ensure favorite/trust/moderation changes invalidate dependent reads
- confirm no sensitive per-user state leaks through shared cache keys

### Production-readiness requirement

Cache must be a performance layer, not a correctness dependency.

## 11. Eventing And Workers

### Required production state

- outbox pattern
- EventBridge fan-out
- SQS workers with retries and DLQs
- idempotent projectors

### Pending tasks

- implement real outbox persistence and relay publishing
- wire all required worker responsibilities:
  - read model projector
  - trust scorer
  - gamification projector
  - moderation dedupe
  - leaderboard refresh
  - stale listing scan
  - notifications dispatch
- validate retry, poison-message, and DLQ handling
- add alarms for queue depth, age, and DLQ growth

### Production-readiness requirement

The backend cannot rely on request-path mutation logic alone once real traffic and moderation workflows exist.

## 12. Admin And Moderation Backend

### Required production state

- live moderation queues
- contributor review
- stale queue
- reports queue
- audit visibility

### Pending tasks

- replace admin mock data with live API reads
- expose richer moderation detail for proofs, related reports, and contributor trust history
- add audit trails for all privileged actions
- ensure admin RBAC is enforced at the API layer

### Production-readiness requirement

The moderation tool must be live before public rollout because the product depends on rapid trust correction.

## 13. Security, Abuse, And Compliance

### Required production state

- rate limiting
- abuse protection
- signed URL constraints
- secrets management
- audit coverage
- request tracing

### Pending tasks

- add request-level rate limiting
- add anti-automation protections for auth and contribution endpoints
- validate signed upload scope, TTL, and content-type checks
- move all secrets into Secrets Manager or equivalent
- ensure request IDs and actor IDs are captured in sensitive flows
- define retention and privacy handling for user-generated evidence

### Production-readiness requirement

The contribution system is inherently abuse-sensitive. This area is mandatory, not optional.

## 14. Observability And Operations

### Required production state

- structured logs
- metrics
- health checks
- dashboards
- alarms
- rollback and incident procedures

### Pending tasks

- validate request ID propagation end-to-end
- expose queue, worker, DB, Redis, API, and auth metrics
- create dashboards for trust failures, moderation backlog, queue health, and auth failures
- define deployment rollback steps
- define on-call and incident ownership

### Production-readiness requirement

The backend must be operable under real traffic, not just correct in development.

## 15. Testing And Release Validation

### Required production state

- route tests
- trust and Karma logic tests
- integration tests over persistence
- queue/worker tests
- staging validation with real services

### Pending tasks

- run and expand API tests once Node.js tooling is installed locally
- add persistence-backed integration tests
- add migration replay and rollback tests
- add load tests for feed, search, and map-bounds
- validate offline replay/idempotency against real persistence
- validate sign-in, favorites sync, contribution flows, notification inbox, and leaderboard consistency against staging

### Production-readiness requirement

The current Flutter tests are useful, but they do not validate the real backend runtime.

## Technologies Required For The Production Backend

### Required

- Node.js
- pnpm
- TypeScript
- Fastify
- Drizzle ORM
- PostgreSQL
- PostGIS
- Redis
- S3
- EventBridge
- SQS
- Cognito
- CloudWatch
- ECS Fargate
- ECR
- Terraform
- Secrets Manager
- DynamoDB for Terraform state locking

### Required integrations

- Google Maps keys for mobile map surfaces
- FCM
- APNs
- MinIO and Docker Compose for local development parity

### Strongly recommended

- OpenSearch later if PostgreSQL search stops being sufficient
- a durable analytics target for telemetry ingestion
- CI/CD for API, workers, infra, and mobile/backend contract validation

## Recommended Implementation Order

1. Fix contract/schema drift first.
2. Replace seed-backed auth with real Cognito/JWT verification while preserving current response shapes.
3. Implement repository-backed persistence for app-critical reads and writes.
4. Add missing persistence for notifications, device registrations, and telemetry.
5. Wire Redis cache and validate invalidation.
6. Wire outbox, EventBridge, SQS, and workers.
7. Finish proof upload finalize flows and moderation detail.
8. Wire admin web to live APIs.
9. Validate everything in staging with real AWS services.
10. Only then treat the backend as ready for production rollout.

## Definition Of Backend Production Ready

The backend should not be considered production-ready until all of the following are true:

- the mobile app can run entirely against real persistence
- auth uses real JWT validation, not dev headers
- trust and Karma are durable and replay-safe
- notification inbox state is durable
- push delivery is real and preference-aware
- idempotent write replay cannot double-create or double-award
- map, search, and feed reads are fast under staging load
- admin moderation is live
- observability and alarms are in place
- deployment, rollback, and incident procedures exist

Until then, the backend should be treated as a strong integration scaffold, not a production rollout backend.
