# Mockup Deviation Log

Record every intentional deviation from the PNG mockups here. The allowed order of compromise is:

1. Preserve information hierarchy
2. Preserve composition and spacing rhythm
3. Preserve styling

| Date | Screen | Deviation | Reason | Follow-up |
| --- | --- | --- | --- | --- |
| 2026-04-13 | Map | Current implementation uses a custom painted placeholder surface instead of a live SDK-backed map | No canonical tile assets or map SDK keys were provided in this pass | Replace with production map provider once keys, style, and pin assets are available |
| 2026-04-13 | Typography | Uses platform serif/sans stack rather than the exact mockup fonts | Font files were not provided | Swap to brand fonts once assets are available |
| 2026-04-13 | Profile access | Added a dedicated avatar action in the header to expose the secondary account stack with the selected 4-tab IA | Profile is not a bottom tab in the agreed architecture | Revisit if future mockups specify a different account entry treatment |
