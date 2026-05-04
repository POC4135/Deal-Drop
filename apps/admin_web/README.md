# DealDrop Admin Web

Internal Next.js operations console for moderation, trust review, stale listing triage, catalog CRUD, and audit review.

## Included pages

- dashboard
- login shell
- venues list and create/detail screens
- listings list and create/detail screens
- moderation queue
- reports queue
- stale listings queue
- contributor review page
- audit log page

## Notes

- The UI intentionally prioritizes operator speed and dense information over marketing polish.
- Admin pages read and mutate live Fastify admin APIs through `src/lib/api.ts`.
- Production auth uses a Supabase-issued bearer token supplied to the server as `DEALDROP_ADMIN_BEARER_TOKEN`; local development falls back to dev admin headers.
