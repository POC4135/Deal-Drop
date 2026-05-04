import { defineConfig } from 'vitest/config';
import { fileURLToPath } from 'node:url';

const fromRoot = (path: string): string => fileURLToPath(new URL(`../${path}`, import.meta.url));

export default defineConfig({
  resolve: {
    alias: {
      '@dealdrop/config': fromRoot('packages/config/src/index.ts'),
      '@dealdrop/shared-types': fromRoot('packages/shared_types/src/index.ts'),
    },
  },
  test: {
    environment: 'node',
    include: ['**/*.test.ts'],
  },
});
