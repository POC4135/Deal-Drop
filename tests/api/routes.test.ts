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
    expect(response.json().sections).toHaveLength(3);
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
