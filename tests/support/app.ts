/**
 * Shared test-app helpers for the functional/non-functional tiers.
 *
 * All hermetic tiers (smoke, e2e-api, contract, security, resilience) drive the
 * real Fastify app via `app.inject()` against the in-memory seed backend. We pin
 * `PLATFORM_BACKEND=seed` + `USE_DEV_AUTH=true` so these are deterministic and
 * DB-free regardless of the ambient environment (CI sets `PLATFORM_BACKEND=postgres`).
 */
import { createApp } from '../../services/api/src/app/create-app.js';

export type TestRole = 'guest' | 'user' | 'moderator' | 'admin';

/** Build a Fastify app pinned to the hermetic seed backend. */
export async function buildSeedApp(): Promise<Awaited<ReturnType<typeof createApp>>> {
  process.env.PLATFORM_BACKEND = 'seed';
  process.env.USE_DEV_AUTH = 'true';
  return createApp();
}

/** Dev-auth headers for a given role. `guest` sends no auth headers. */
export function asRole(role: TestRole, userId?: string): Record<string, string> {
  if (role === 'guest') {
    return {};
  }
  return {
    'x-dev-user-id': userId ?? `usr_${role}_test`,
    'x-dev-role': role,
    'x-dev-email': `${role}@dealdrop.test`,
    'x-dev-name': `${role} tester`,
  };
}

/** A couple of real seed identifiers used across tiers for stable lookups. */
export const SEED = {
  listingId: 'lst_taco_tuesday',
  venueId: 'ven_taqueria_del_sol',
  userId: 'usr_alex',
  userEmail: 'alex@dealdrop.app',
  userPassword: 'dealdrop123',
} as const;
