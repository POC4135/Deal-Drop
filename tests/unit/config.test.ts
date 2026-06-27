/**
 * Unit tests for config helpers: env parsing, cache keys, role resolution.
 * Source: packages/config/src/index.ts
 */
import { describe, expect, it } from 'vitest';

import {
  buildCacheKey,
  cacheNamespace,
  parseRuntimeEnv,
  resolveRole,
} from '@dealdrop/config';

describe('parseRuntimeEnv', () => {
  it('applies documented defaults on an empty environment', () => {
    const env = parseRuntimeEnv({});
    expect(env.NODE_ENV).toBe('development');
    expect(env.PLATFORM_BACKEND).toBe('seed');
    expect(env.PORT).toBe(3000);
    expect(env.USE_DEV_AUTH).toBe(true);
  });

  it('coerces PORT and the USE_DEV_AUTH boolean', () => {
    const env = parseRuntimeEnv({ PORT: '8080', USE_DEV_AUTH: 'false' });
    expect(env.PORT).toBe(8080);
    expect(env.USE_DEV_AUTH).toBe(false);
  });

  it('rejects an invalid PLATFORM_BACKEND', () => {
    expect(() => parseRuntimeEnv({ PLATFORM_BACKEND: 'mysql' })).toThrow();
  });
});

describe('cache key helpers', () => {
  it('namespaces with the version prefix', () => {
    expect(cacheNamespace('feed-home')).toBe('dealdrop:v1:feed-home');
  });

  it('joins defined parts and drops undefined ones', () => {
    expect(buildCacheKey('feed-home', 33.7, undefined, 'usr_1')).toBe('dealdrop:v1:feed-home:33.7:usr_1');
  });
});

describe('resolveRole', () => {
  it('prefers an explicit app_role claim', () => {
    expect(resolveRole({ sub: 'u', app_role: 'admin' })).toBe('admin');
  });

  it('falls back to a recognized role claim', () => {
    expect(resolveRole({ sub: 'u', role: 'moderator' })).toBe('moderator');
  });

  it('defaults unknown/absent roles to user', () => {
    expect(resolveRole({ sub: 'u' })).toBe('user');
    expect(resolveRole({ sub: 'u', role: 'superhero' })).toBe('user');
  });
});
