import { defineConfig } from 'vitest/config';
import { fileURLToPath } from 'node:url';

const repoRoot = fileURLToPath(new URL('..', import.meta.url));
const fromRoot = (path: string): string => fileURLToPath(new URL(`../${path}`, import.meta.url));

// Emit machine-readable JUnit (for CI) alongside the human reporter when CI or
// JUNIT is set; otherwise keep local output quiet.
const wantJunit = Boolean(process.env.CI || process.env.JUNIT);
const reporters = wantJunit
  ? (['default', ['junit', { outputFile: 'test-results/junit.xml' }]] as const)
  : (['default'] as const);

export default defineConfig({
  resolve: {
    alias: {
      '@dealdrop/config': fromRoot('packages/config/src/index.ts'),
      '@dealdrop/shared-types': fromRoot('packages/shared_types/src/index.ts'),
    },
  },
  test: {
    // Root at the repo so coverage can see app source in services/* and packages/*.
    root: repoRoot,
    include: ['tests/**/*.test.ts'],
    setupFiles: ['tests/support/setup.ts'],
    environment: 'node',
    reporters: reporters as unknown as string[],
    coverage: {
      provider: 'v8',
      all: true,
      // Only the modules this harness meaningfully exercises in-process. The
      // postgres-platform + workers + db scripts are covered by the integration
      // tier (real DB, CI-only) and worker smoke, so they are excluded here to
      // keep these thresholds honest rather than gamed.
      include: ['services/api/src/**/*.ts', 'packages/config/src/**/*.ts'],
      exclude: [
        'services/api/src/db/**',
        'services/api/src/workers/**',
        'services/api/src/bootstrap/postgres-platform.ts',
        'services/api/src/index.ts',
        '**/*.d.ts',
      ],
      reporter: ['text-summary', 'json-summary', 'html', 'lcov'],
      reportsDirectory: 'tests/coverage',
      // Ratchet: these are the floor. They may only be raised, never lowered.
      // Baseline set from the Phase 2 measurement; see TESTING.md › Coverage.
      // Baseline measured in Phase 2: stmts 67.3 / branches 84.2 / funcs 71.9 /
      // lines 67.3. Floors sit just under that. Ratchet UP as coverage grows.
      thresholds: {
        statements: 65,
        branches: 78,
        functions: 68,
        lines: 65,
      },
    },
  },
});
