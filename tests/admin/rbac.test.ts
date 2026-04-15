import { describe, expect, it } from 'vitest';

import { createApp } from '../../services/api/src/app/create-app.js';

describe('admin RBAC', () => {
  it('blocks moderators from admin-only audit export', async () => {
    const app = await createApp();
    const response = await app.inject({
      method: 'GET',
      url: '/v1/admin/audit',
      headers: {
        'x-dev-role': 'moderator',
      },
    });

    expect(response.statusCode).toBe(403);
  });

  it('allows admins to read audit events', async () => {
    const app = await createApp();
    const response = await app.inject({
      method: 'GET',
      url: '/v1/admin/audit',
      headers: {
        'x-dev-role': 'admin',
      },
    });

    expect(response.statusCode).toBe(200);
    expect(Array.isArray(response.json())).toBe(true);
  });
});
