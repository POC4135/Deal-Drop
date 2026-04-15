# Platform Foundation

## Runtime topology

- `apps/mobile_flutter` consumes `packages/contracts` and now talks to the live API surface through a Dio repository, local cache, and offline mutation queue.
- `apps/admin_web` is a static-export operator console hosted from S3 + CloudFront.
- `services/api` is a modular monolith running on ECS/Fargate.
- `services/workers/*` consume queue fan-out from EventBridge + SQS.
- Aurora PostgreSQL + PostGIS is the source of truth for entities and event-heavy tables.
- Redis fronts hot read paths and leaderboard slices.

## Data flow

1. User and moderator write paths hit the API.
2. API writes domain state plus `outbox_events`.
3. Outbox relay publishes to EventBridge.
4. Worker queues fan out to read-model, trust, gamification, dedupe, leaderboard, and stale-scan processors.
5. Read models and confidence snapshots drive feed, map, search, and admin queues.

## Read path rules

- Feed/search/map/listing detail/venue detail use cache-first reads with versioned keys.
- Heavy list endpoints use opaque cursor pagination.
- Search starts with PostgreSQL text search and trigram support, with a clean future migration path to OpenSearch.
