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
- Production auth is designed around Cognito groups and JWT claims; the UI currently uses static mock data for page rendering while the backend admin routes mature.
