import { describe, expect, it } from 'vitest';

import { assertProductionRuntimeEnv, parseRuntimeEnv } from '@dealdrop/config';

describe('runtime configuration', () => {
  it('rejects the removed seed platform backend', () => {
    expect(() => parseRuntimeEnv({ PLATFORM_BACKEND: 'seed' })).toThrow();
  });

  it('requires Supabase-backed production configuration', () => {
    const env = parseRuntimeEnv({
      NODE_ENV: 'production',
      APP_ENV: 'prod',
      PLATFORM_BACKEND: 'postgres',
      DATABASE_URL: 'postgres://postgres:postgres@localhost:5432/dealdrop',
      USE_DEV_AUTH: 'false',
    });

    expect(() => assertProductionRuntimeEnv(env)).toThrow(
      /SUPABASE_URL.*SUPABASE_JWKS_URL.*SUPABASE_JWT_ISSUER.*SUPABASE_PUBLISHABLE_KEY/,
    );
  });
});
