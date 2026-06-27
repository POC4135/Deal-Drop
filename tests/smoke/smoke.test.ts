/**
 * Smoke tests — the fast, post-deploy / pre-gate sanity check.
 * Confirms the app boots, health probes answer, and a few critical public
 * endpoints respond. Intentionally tiny and assertion-light (shape, not values).
 */
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { buildSeedApp } from '../support/app.js';

let app: Awaited<ReturnType<typeof buildSeedApp>>;

beforeAll(async () => {
  app = await buildSeedApp();
  await app.ready();
});

afterAll(async () => {
  await app.close();
});

describe('smoke', () => {
  it('boots and answers the liveness probe', async () => {
    const res = await app.inject({ method: 'GET', url: '/health/live' });
    expect(res.statusCode).toBe(200);
    expect(res.json().status).toBe('ok');
  });

  it('answers the readiness probe with dependency status', async () => {
    const res = await app.inject({ method: 'GET', url: '/health/ready' });
    expect(res.statusCode).toBe(200);
    expect(res.json().dependencies).toMatchObject({ database: expect.any(String) });
  });

  it.each([
    '/v1/feed/home?limit=3',
    '/v1/search?q=taco',
    '/v1/filters/metadata',
    '/v1/listings/map-bounds?north=33.9&south=33.6&east=-84.2&west=-84.5',
  ])('serves public endpoint %s', async (url) => {
    const res = await app.inject({ method: 'GET', url });
    expect(res.statusCode).toBe(200);
  });
});
