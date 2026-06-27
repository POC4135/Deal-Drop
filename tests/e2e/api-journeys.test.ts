/**
 * End-to-end API journeys — a small number of critical request→response flows
 * exercised through the real app (no mocks of internal logic). Covers the happy
 * paths a mobile client actually performs.
 *
 * Mutating journeys use a fresh authenticated identity (not a seed user) so they
 * start from a known-empty state and don't depend on test order.
 */
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { asRole, buildSeedApp, SEED } from '../support/app.js';

let app: Awaited<ReturnType<typeof buildSeedApp>>;

beforeAll(async () => {
  app = await buildSeedApp();
  await app.ready();
});

afterAll(async () => {
  await app.close();
});

describe('journey: guest discovery → detail → search', () => {
  it('browses the feed, opens a listing, and searches', async () => {
    const feed = await app.inject({ method: 'GET', url: '/v1/feed/home?limit=10' });
    expect(feed.statusCode).toBe(200);
    const sections = feed.json().sections as Array<{ items: Array<{ id: string }> }>;
    const firstListingId = sections.flatMap((s) => s.items)[0]?.id;
    expect(firstListingId).toBeTruthy();

    const detail = await app.inject({ method: 'GET', url: `/v1/listings/${firstListingId}` });
    expect(detail.statusCode).toBe(200);
    expect(detail.json().trustSummary).toBeTruthy();

    const search = await app.inject({ method: 'GET', url: '/v1/search?q=taco&limit=5' });
    expect(search.statusCode).toBe(200);
    expect(Array.isArray(search.json().listings)).toBe(true);
  });

  it('returns 404 for an unknown listing id', async () => {
    const res = await app.inject({ method: 'GET', url: '/v1/listings/lst_does_not_exist' });
    expect(res.statusCode).toBe(404);
  });
});

describe('journey: authenticated favorite lifecycle', () => {
  const headers = asRole('user', 'usr_journey_fav');

  it('adds a favorite, sees it in saved, then removes it', async () => {
    const add = await app.inject({ method: 'POST', url: `/v1/favorites/${SEED.listingId}`, headers });
    expect(add.statusCode).toBe(204);

    const saved = await app.inject({ method: 'GET', url: '/v1/me/saved', headers });
    expect(saved.statusCode).toBe(200);
    expect((saved.json() as Array<{ id: string }>).some((l) => l.id === SEED.listingId)).toBe(true);

    const remove = await app.inject({ method: 'DELETE', url: `/v1/favorites/${SEED.listingId}`, headers });
    expect(remove.statusCode).toBe(204);

    const after = await app.inject({ method: 'GET', url: '/v1/me/saved', headers });
    expect((after.json() as Array<{ id: string }>).some((l) => l.id === SEED.listingId)).toBe(false);
  });
});

describe('journey: confirming a listing strengthens trust', () => {
  it('records a confirmation and returns updated trust', async () => {
    const headers = asRole('user', 'usr_journey_confirm');
    const res = await app.inject({ method: 'POST', url: `/v1/listings/${SEED.listingId}/confirm`, headers, payload: {} });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({
      confidenceScore: expect.any(Number),
      trustBand: expect.any(String),
    });
  });
});
