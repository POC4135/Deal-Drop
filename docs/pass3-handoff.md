# Post-Launch Handoff

Pass 3 completed the mobile integration pass. The next work should focus on release hardening and operational rollout, not reworking the primary app IA.

## Immediate follow-ups

1. Replace preference-backed auth session persistence with secure OS-backed storage.
2. Complete native push delivery using FCM/APNs tokens against the existing device registration and inbox APIs.
3. Swap the seed-backed API service layer to real Postgres repositories and run the Node/Terraform validation toolchains.
4. Connect the admin web shell to live moderation/admin endpoints instead of local mock data.

## Launch validation checklist

- verify Google Maps keys for Android and iOS environments
- validate auth, save sync, contribution retry, and notification inbox flows against a live backend
- run API, worker, and migration tests once `node`, `pnpm`, and `terraform` are installed
- test contribution moderation and trust/Karma reconciliation with real review actions
