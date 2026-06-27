/**
 * Unit tests for the in-memory cache store — TTL and prefix invalidation.
 * Uses a frozen clock so TTL expiry is deterministic.
 * Source: services/api/src/lib/cache.ts
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { InMemoryCacheStore } from '../../services/api/src/lib/cache.js';

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date('2026-01-01T00:00:00.000Z'));
});

afterEach(() => {
  vi.useRealTimers();
});

describe('InMemoryCacheStore', () => {
  it('returns null for a missing key', async () => {
    const cache = new InMemoryCacheStore();
    expect(await cache.get('missing')).toBeNull();
  });

  it('stores and retrieves a value within its TTL', async () => {
    const cache = new InMemoryCacheStore();
    await cache.set('k', { v: 1 }, 60);
    vi.advanceTimersByTime(59_000);
    expect(await cache.get('k')).toEqual({ v: 1 });
  });

  it('expires a value after its TTL elapses', async () => {
    const cache = new InMemoryCacheStore();
    await cache.set('k', { v: 1 }, 60);
    vi.advanceTimersByTime(61_000);
    expect(await cache.get('k')).toBeNull();
  });

  it('invalidates only keys matching the prefix', async () => {
    const cache = new InMemoryCacheStore();
    await cache.set('feed:home:a', 1, 600);
    await cache.set('feed:home:b', 2, 600);
    await cache.set('search:x', 3, 600);
    await cache.invalidatePrefix('feed:home');
    expect(await cache.get('feed:home:a')).toBeNull();
    expect(await cache.get('feed:home:b')).toBeNull();
    expect(await cache.get('search:x')).toBe(3);
  });

  it('overwrites an existing key', async () => {
    const cache = new InMemoryCacheStore();
    await cache.set('k', 1, 600);
    await cache.set('k', 2, 600);
    expect(await cache.get('k')).toBe(2);
  });
});
