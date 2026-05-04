# Platform Foundation

## Runtime topology

- `apps/mobile_flutter` consumes `packages/contracts` and now talks to the live API surface through a Dio repository, local cache, and offline mutation queue.
- `apps/admin_web` is an operator console hosted as a Render web service.
- `services/api` is a modular Fastify API hosted as a Render web service.
- `services/workers/*` are Render background workers that consume Postgres-backed outbox and projection tables.
- Supabase PostgreSQL + PostGIS is the source of truth for entities and event-heavy tables.
- Supabase Auth owns user identity; DealDrop `users.role` owns app authorization.

## Data flow

1. User and moderator write paths hit the API.
2. API writes domain state plus `outbox_events`.
3. Outbox relay marks durable Postgres events for worker consumption.
4. Worker entrypoints process read-model, trust, gamification, dedupe, leaderboard, stale-scan, and notification dispatch responsibilities.
5. Read models and confidence snapshots drive feed, map, search, and admin queues.

## Read path rules

- Feed/search/map/listing detail/venue detail use cache-first reads with versioned keys.
- Heavy list endpoints use opaque cursor pagination.
- Search starts with PostgreSQL text search and trigram support, with a clean future migration path to OpenSearch.
