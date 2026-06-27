/**
 * Characterization (golden master) for the shape of key read endpoints.
 *
 * These GET routes read only fixed seed data (no clock, no randomness, no
 * mutation), so their full responses are deterministic and can be snapshotted
 * directly. The snapshots pin the response CONTRACT (keys, nesting, values) so a
 * change to a DTO, a sort order, a default, or the seed surfaces immediately.
 *
 * We deliberately use only READ routes here and never mutate, so the shared
 * in-memory seed is not contaminated within this file.
 *
 * Sources under test: modules/{discovery,listings,health}/routes.ts via
 *                     DealDropPlatform, app/create-app.ts.
 */
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { createApp } from '../../services/api/src/app/create-app.js';
import { stripVolatile } from './_support.js';

let app: Awaited<ReturnType<typeof createApp>>;

beforeAll(async () => {
  app = await createApp();
});

afterAll(async () => {
  await app.close();
});

async function snapshotGet(url: string) {
  const response = await app.inject({ method: 'GET', url, headers: { 'x-dev-role': 'user' } });
  expect(response.statusCode).toBe(200);
  return stripVolatile(response.json());
}

describe('read-route shapes — golden master', () => {
  it('pins GET /health', async () => {
    expect(await snapshotGet('/health')).toMatchSnapshot();
  });

  it('pins GET /health/ready', async () => {
    expect(await snapshotGet('/health/ready')).toMatchSnapshot();
  });

  it('pins GET /v1/filters/metadata', async () => {
    expect(await snapshotGet('/v1/filters/metadata')).toMatchSnapshot();
  });

  it('pins GET /v1/feed/home (default ordering, limit 5)', async () => {
    expect(await snapshotGet('/v1/feed/home?limit=5')).toMatchSnapshot();
  });

  it('pins GET /v1/search for a known term', async () => {
    expect(await snapshotGet('/v1/search?q=ramen&limit=10')).toMatchSnapshot();
  });

  it('pins GET /v1/listings/map-bounds over the Atlanta seed area', async () => {
    expect(
      await snapshotGet('/v1/listings/map-bounds?north=33.9&south=33.6&east=-84.2&west=-84.5'),
    ).toMatchSnapshot();
  });

  it('pins GET /v1/listings/:id detail for a known seed listing', async () => {
    expect(await snapshotGet('/v1/listings/lst_taco_tuesday')).toMatchSnapshot();
  });
});
