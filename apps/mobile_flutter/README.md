# DealDrop Mobile

Flutter consumer app for the Atlanta-first DealDrop discovery experience.

## Implemented in this pass

- Riverpod + go_router app shell
- bottom-nav IA for `Deals / Map / Post / Karma`
- account stack for profile, saved items, and notifications
- polished onboarding, deals feed, search, map, detail, contribution, Karma, saved, notifications, and profile screens
- Dio-backed live API repository, guest-local saves, offline mutation queue, cached reads, and lifecycle resume sync
- trust-state UX for `Founder verified`, `Merchant confirmed`, `User confirmed`, `Recently updated`, `Needs recheck`, and `Disputed`
- Google Maps viewport fetching, bottom-sheet previews, and permission-aware fallback states
- contribution flows for new listings, updates, confirmations, expired reports, and proof upload requests
- custom telemetry hooks and widget/unit tests around the production shell
- shared design tokens consumed from `../../packages/design_tokens`

## Local Commands

- `flutter pub get`
- `flutter test`
- `flutter analyze`

## Known Gaps

- native push delivery still needs full FCM/APNs hookup beyond the in-app inbox/device-registration foundation
- auth session storage should move from shared preferences to secure platform storage before release builds
- typography still uses fallback fonts until the final licensed brand family is supplied
