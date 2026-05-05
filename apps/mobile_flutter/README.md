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
- native Firebase Messaging push token registration, foreground alerts, and backend device sync
- Keychain / encrypted shared preferences session storage with legacy shared-preferences migration
- custom telemetry hooks and widget/unit tests around the production shell
- shared design tokens consumed from `../../packages/design_tokens`

## Local Commands

- `flutter pub get`
- `flutter test`
- `flutter analyze`

## Known Gaps

- typography still uses fallback fonts until the final licensed brand family is supplied

## Native release setup

- Android release builds need `android/app/google-services.json`.
- iOS release builds need `ios/Runner/GoogleService-Info.plist`, Push Notifications enabled on the App ID, and an APNs key uploaded to the Firebase project.
