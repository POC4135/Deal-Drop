import { describe, expect, it } from 'vitest';

import { createApp } from '../../services/api/src/app/create-app.js';

describe('api routes', () => {
  it('returns feed sections for the home feed', async () => {
    const app = await createApp();
    const response = await app.inject({
      method: 'GET',
      url: '/v1/feed/home?limit=5',
      headers: {
        'x-dev-role': 'user',
      },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().sections.length).toBeGreaterThanOrEqual(3);
  });

  it('enforces moderator role for admin dashboard', async () => {
    const app = await createApp();
    const response = await app.inject({
      method: 'GET',
      url: '/v1/admin/dashboard',
      headers: {
        'x-dev-role': 'user',
      },
    });

    expect(response.statusCode).toBe(403);
  });

  it('bootstraps an authenticated user into the app session contract', async () => {
    const app = await createApp();
    const response = await app.inject({
      method: 'POST',
      url: '/v1/auth/bootstrap',
      headers: {
        'x-dev-user-id': 'usr_bootstrap_test',
        'x-dev-email': 'bootstrap@dealdrop.app',
        'x-dev-role': 'user',
        'x-dev-name': 'Bootstrap User',
      },
      payload: {
        displayName: 'Bootstrap User',
        homeNeighborhood: 'Midtown',
      },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().session.userId).toBe('usr_bootstrap_test');
    expect(response.json().profile.email).toBe('bootstrap@dealdrop.app');
  });

  it('allows moderators into the admin dashboard', async () => {
    const app = await createApp();
    const response = await app.inject({
      method: 'GET',
      url: '/v1/admin/dashboard',
      headers: {
        'x-dev-role': 'moderator',
      },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().openContributionCount).toBeGreaterThan(0);
  });
});
