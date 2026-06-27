/**
 * Characterization for authentication & role-based access control.
 *
 * This is the highest-risk surface in the app. We pin the CURRENT behavior of
 * the dev-auth path (USE_DEV_AUTH, the default in local/CI) as a route × role
 * status-code matrix, including one behavior that is surprising and worth
 * locking down so it cannot change silently:
 *
 *   >>> When NO x-dev-* headers are sent, a request to a PROTECTED route is
 *       treated as a fully-privileged ADMIN (see plugins/auth.ts). <<<
 *
 * If that default ever changes (e.g. to deny-by-default), this snapshot fails
 * and forces a deliberate review.
 *
 * Sources under test: plugins/auth.ts (registerAuth, requireRole),
 *                     app/create-app.ts, modules/admin/routes.ts
 */
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { createApp } from '../../services/api/src/app/create-app.js';

type RoleLabel = 'no-headers' | 'user' | 'moderator' | 'admin';

const ROLE_HEADERS: Record<RoleLabel, Record<string, string>> = {
  'no-headers': {},
  user: { 'x-dev-user-id': 'usr_test', 'x-dev-role': 'user' },
  moderator: { 'x-dev-user-id': 'usr_test', 'x-dev-role': 'moderator' },
  admin: { 'x-dev-user-id': 'usr_test', 'x-dev-role': 'admin' },
};

// Read-only routes spanning the three access tiers.
const ROUTES: Array<{ label: string; method: 'GET'; url: string }> = [
  { label: 'public:feed-home', method: 'GET', url: '/v1/feed/home?limit=3' },
  { label: 'public:health', method: 'GET', url: '/health' },
  { label: 'authed:me-profile', method: 'GET', url: '/v1/me/profile' },
  { label: 'moderator:admin-dashboard', method: 'GET', url: '/v1/admin/dashboard' },
  { label: 'admin-only:admin-audit', method: 'GET', url: '/v1/admin/audit' },
];

let app: Awaited<ReturnType<typeof createApp>>;
const priorEnv: Record<string, string | undefined> = {};

beforeAll(async () => {
  // Phase 1 characterization is hermetic: pin the in-memory seed backend and dev
  // auth so the RBAC matrix is deterministic and identical everywhere,
  // independent of CI's PLATFORM_BACKEND=postgres (which would require a live DB).
  for (const key of ['PLATFORM_BACKEND', 'USE_DEV_AUTH'] as const) {
    priorEnv[key] = process.env[key];
  }
  process.env.PLATFORM_BACKEND = 'seed';
  process.env.USE_DEV_AUTH = 'true';
  app = await createApp();
});

afterAll(async () => {
  await app.close();
  for (const [key, value] of Object.entries(priorEnv)) {
    if (value === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = value;
    }
  }
});

describe('auth/RBAC — status-code matrix (dev auth)', () => {
  it('pins the route × role access matrix', async () => {
    const matrix: Record<string, Record<RoleLabel, number>> = {};
    for (const route of ROUTES) {
      matrix[route.label] = {} as Record<RoleLabel, number>;
      for (const role of Object.keys(ROLE_HEADERS) as RoleLabel[]) {
        const response = await app.inject({
          method: route.method,
          url: route.url,
          headers: ROLE_HEADERS[role],
        });
        matrix[route.label][role] = response.statusCode;
      }
    }
    expect(matrix).toMatchSnapshot();
  });
});

describe('auth/RBAC — security-critical invariants (explicit)', () => {
  it('treats a header-less request to a protected route as ADMIN (current behavior)', async () => {
    const response = await app.inject({ method: 'GET', url: '/v1/admin/audit', headers: {} });
    // Documents the dev-auth default-admin behavior — NOT a recommendation.
    expect(response.statusCode).toBe(200);
  });

  it('forbids a plain user from the moderator-gated admin dashboard', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/admin/dashboard',
      headers: ROLE_HEADERS.user,
    });
    expect(response.statusCode).toBe(403);
    expect(response.json()).toMatchObject({ error: 'forbidden' });
  });

  it('forbids a moderator from the admin-only audit log but allows an admin', async () => {
    const moderator = await app.inject({
      method: 'GET',
      url: '/v1/admin/audit',
      headers: ROLE_HEADERS.moderator,
    });
    const admin = await app.inject({
      method: 'GET',
      url: '/v1/admin/audit',
      headers: ROLE_HEADERS.admin,
    });
    expect(moderator.statusCode).toBe(403);
    expect(admin.statusCode).toBe(200);
  });

  it('serves public discovery routes to an unauthenticated guest', async () => {
    const response = await app.inject({ method: 'GET', url: '/v1/feed/home?limit=3', headers: {} });
    expect(response.statusCode).toBe(200);
    expect(Array.isArray(response.json().sections)).toBe(true);
  });
});
