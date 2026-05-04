# DealDrop

DealDrop is an Atlanta-first local value discovery platform optimized for freshness, trust, and speed.

Pass 3 finishes the consumer mobile product on top of the Pass 2 platform foundation: the repo now contains the production-facing Flutter app shell, live API integrations, offline-aware write flows, trust and Karma UX, admin/moderation scaffolding, and the shared contracts that connect them.

## Repository layout

- `apps/mobile_flutter`: Flutter consumer app from Pass 1, now renamed to the required monorepo path.
- `apps/admin_web`: internal admin and moderation console.
- `services/api`: Fastify + Drizzle backend foundation with public and admin APIs.
- `services/workers/*`: Render background worker entrypoints for Postgres outbox, trust, gamification, leaderboard, stale scan, and notification responsibilities.
- `packages/contracts`: OpenAPI contract source of truth.
- `packages/shared_types`: shared DTOs, enums, and event schemas.
- `packages/config`: runtime config, cache keys, queue names, and auth helpers.
- `packages/design_tokens`: Flutter design tokens preserved from Pass 1.
- `infra/terraform`: historical AWS IaC foundation; current production target is Supabase + Render.
- `infra/local`: Docker Compose stack for Postgres/PostGIS, Redis, and MinIO.
- `seed/atlanta`: launch-market seed payloads.
- `tests`: initial API, trust, gamification, migration, worker, and RBAC tests.

## Implemented through Pass 3

- monorepo reshape to the required app/package paths
- TypeScript workspace foundation for API, admin, shared types, config, and tests
- Fastify API routes for discovery, listings, venues, search, favorites, contributions, reporting, profile/karma, and admin operations
- trust/confidence engine and gamification engine foundations
- Drizzle schema plus SQL migration for the core platform tables
- queue worker wrappers and outbox/event naming foundation
- Next.js admin operator shell with dashboard, queues, catalog CRUD shells, contributor review, and audit views
- Terraform module skeletons for networking, compute, storage, auth, queues, and observability
- local Docker stack and Atlanta seed dataset
- Flutter app shell with `Deals / Map / Post / Karma`, secondary account stack, guest browsing, local-save sync, real API repository integration, Google Maps screen, trust-state detail UX, notifications inbox, and offline mutation retries
- custom mobile telemetry hooks, widget tests, and improved app docs for launch-readiness validation

## Local setup

### Tooling

- `pnpm` and `node` for the TypeScript workspace
- `flutter` for the consumer app
- `terraform` for IaC validation and plans
- `docker compose` for local Postgres/PostGIS, Redis, and MinIO

### Start local infrastructure

```bash
docker compose -f infra/local/docker-compose.yml up -d
```

### API and admin

```bash
pnpm install
pnpm --filter @dealdrop/api db:migrate
pnpm --filter @dealdrop/api db:seed
pnpm --filter @dealdrop/api dev
pnpm --filter @dealdrop/admin-web dev
```

### Test

```bash
pnpm --filter @dealdrop/tests test
pnpm --filter @dealdrop/api test
flutter test apps/mobile_flutter
```

## Production-readiness review

During the final review pass, the following issues were fixed:

- protected-route redirects now preserve contribution route context, including `listingId`
- auth redirect links now encode redirect targets safely
- map screen now triggers an initial bounds fetch after controller creation instead of waiting for manual interaction
- clearing active search chips now refreshes results immediately
- offline queued mutations are now scoped to the authenticated user so they do not replay under a different account
- notification read state now updates the local cache after a successful mark-read call
- profile notification preference writes now surface failure feedback instead of silently failing
- detail-screen directions now fail gracefully instead of silently doing nothing
- contribution form now handles listing prefetch failure, listing search failure, and proof-slot request failure more safely
- the seed auth backend now validates passwords and rejects duplicate sign-ups instead of accepting any password for an existing email
- favorite sync/favorite writes now invalidate the broader read-cache surface on the backend seed platform

## What is still pending before true production launch

### Mobile app pending work

- replace remaining `shared_preferences` app-session persistence with `flutter_secure_storage` or equivalent Keychain/Keystore-backed storage
- integrate native push end-to-end with `firebase_messaging` for FCM and APNs token handling, background message handling, and notification-open routing
- add a real proof upload flow with `image_picker` or `file_picker`, Supabase Storage upload execution, upload progress, and retry handling
- finish native Supabase auth edge cases such as confirmed-email flows, token-expiry UX, and deep-link callbacks
- add crash reporting and release telemetry sinks for production environments
- finalize native deep links / universal links / Android app links
- complete final accessibility QA across smaller devices, text scaling, screen readers, and reduced-motion cases
- add brand fonts and any final asset pack once licensing/assets are available

### Backend and platform pending work

- validate the Postgres platform backend against Supabase staging data and remove any remaining seed-only fallbacks from production paths
- keep Fastify auth on Supabase JWT verification and DealDrop DB roles; dev headers are local-only with `USE_DEV_AUTH=true`
- implement secure password handling only through the real identity provider; the seed password flow is for local integration only
- complete Redis-backed cache infrastructure and validate cache invalidation with real persistence
- harden Postgres outbox workers, retry behavior, and Render background worker scheduling
- complete Supabase Storage proof upload finalize/attach flows and moderation proof review storage
- implement real push delivery fan-out and notification preference enforcement on the backend
- persist telemetry/analytics to a real sink and wire dashboards/alerting
- complete browser-side Supabase admin login/session handling beyond the current server-token API bridge
- install `node`, `pnpm`, and `terraform` in the workspace and run API tests, worker tests, migrations, and Terraform validation for real
- complete production secrets, domain, TLS, environment promotion, and deployment automation
- finish rate limiting, abuse protection, and operational runbooks for public launch traffic

### Infrastructure and operations pending work

- provision and validate Supabase + Render environments for `dev`, `staging`, and `prod`
- configure Supabase Auth, asymmetric JWT signing keys, Postgres, and Storage buckets
- configure Google Maps SDK keys for Android and iOS release builds
- configure APNs credentials and FCM project settings
- add CI/CD for Flutter builds, backend tests, Terraform plan/apply, and release promotion

## How the app is already prepared for backend integration

The current app was structured so the UI does not depend on seed/mock widgets directly:

- `packages/contracts/openapi/dealdrop.v1.yaml` is the source-of-truth API contract
- `packages/shared_types` mirrors the core DTOs, trust states, notifications, contribution history, auth payloads, and leaderboard data shapes
- `apps/mobile_flutter/lib/src/core/services/dealdrop_repository.dart` is the single repository boundary between UI and backend APIs
- `apps/mobile_flutter/lib/src/core/services/api_client.dart` isolates network transport, idempotency keys, auth headers, and error mapping
- `apps/mobile_flutter/lib/src/core/services/app_config.dart` centralizes environment-dependent base URLs and feature/config flags
- Riverpod providers isolate app state from transport details, making it straightforward to swap the current local-dev auth bridge for real bearer auth
- the offline mutation queue already models retryable actions separately from UI widgets, so it can be retained when the real backend is wired
- device registration, notifications, telemetry, favorites sync, contribution flows, search, map-bounds, profile, and Karma already target explicit backend endpoints
- the mobile route structure is deep-link ready and already separated into public browsing flows vs protected account/contribution flows

## Technologies required for a fully functioning production stack

### Mobile

- Flutter / Dart
- Riverpod
- go_router
- Dio
- Google Maps Flutter SDK
- Geolocator
- url_launcher
- `flutter_secure_storage` for secure auth persistence
- `firebase_messaging` for push
- `image_picker` or `file_picker` for proof capture/upload

### Backend and data

- Node.js
- pnpm
- TypeScript
- Fastify
- Drizzle ORM
- PostgreSQL with PostGIS
- Supabase Auth/Postgres/Storage
- Render web services and background workers
- Postgres outbox workers
- FCM/APNs
- structured logging / metrics sinks

### Platform

- Supabase project with asymmetric JWT signing keys
- Render API, admin, and worker services
- Docker Compose for local Postgres/PostGIS, Redis, and MinIO where needed

### Notification and release infrastructure

- FCM
- APNs
- mobile signing/build toolchains for Android and iOS
- CI/CD for Flutter, backend, and infrastructure validation

## Local development auth notes

The local seed backend now expects an actual password for the seeded users:

- `alex@dealdrop.app` / `dealdrop123`
- `maya@dealdrop.app` / `dealdrop123`
- `jon@dealdrop.app` / `dealdrop123`
- `sam@dealdrop.app` / `dealdrop123`

This is only for local integration flow validation. Production auth comes from Supabase Auth and bearer-token verification in the API.
