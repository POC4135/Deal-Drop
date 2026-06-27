/**
 * Global Vitest setup — runs before every test file.
 *
 * Enforces determinism that is independent of the host machine:
 *  - Fixed timezone so any date formatting is stable across CI/local.
 *  - Frozen-clock helpers live per-suite (vi.setSystemTime) where needed; this
 *    file only sets the ambient invariants every tier relies on.
 */
process.env.TZ = 'UTC';

// Default the hermetic tiers to the seed backend + dev auth unless a suite
// explicitly overrides. Real-DB integration tests opt back into postgres.
process.env.PLATFORM_BACKEND ??= 'seed';
process.env.USE_DEV_AUTH ??= 'true';
