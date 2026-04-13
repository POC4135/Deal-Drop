# DealDrop Mobile

Flutter consumer app for the Atlanta-first DealDrop discovery experience.

## Implemented in this pass

- Riverpod + go_router app shell
- bottom-nav IA for `Deals / Map / Post / Karma`
- account stack for profile, saved items, and notifications
- mockup-aligned onboarding, feed, map, detail, contribution, karma, and profile screens
- seed-backed discovery repository and persisted favorites
- shared design tokens consumed from `../../packages/design_tokens`

## Local Commands

- `flutter pub get`
- `flutter test`
- `flutter analyze`

## Known Gaps

- map screen currently uses a custom-painted placeholder instead of a production SDK
- typography uses platform serif/sans fallbacks until brand fonts are supplied
- contribution actions are local UI flows pending backend moderation APIs and signed uploads
