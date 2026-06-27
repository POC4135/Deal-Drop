/**
 * Characterization for the in-memory seed platform's auth behavior.
 *
 * The README explicitly calls out that the seed auth backend "now validates
 * passwords and rejects duplicate sign-ups". This pins that behavior, plus the
 * bootstrap upsert semantics, so a regression here is caught.
 *
 * IMPORTANT determinism note: DealDropPlatform mutates its seed. Every test
 * constructs a platform over a FRESH CLONE (`freshSeed()`) so tests are isolated
 * and order-independent.
 *
 * NOTE on the production cascade-delete: the high-risk
 * `PostgresDealDropPlatform.bootstrapAuthenticatedUser` cascade-deletes a user's
 * entire data graph on email re-registration. That path requires a real Postgres
 * connection and is characterized in the Phase 2 integration tier (CI-only). The
 * in-memory bootstrap below is an UPSERT (no delete) — a deliberately different
 * behavior, pinned here so the difference is documented.
 *
 * Source under test: services/api/src/bootstrap/platform.ts
 */
import { describe, expect, it } from 'vitest';

import { DealDropPlatform } from '../../services/api/src/bootstrap/platform.js';
import { freshSeed } from './_support.js';

const SEEDED_EMAIL = 'alex@dealdrop.app';
const SEEDED_PASSWORD = 'dealdrop123';

describe('seed platform auth — sign in', () => {
  it('signs in a seeded user with the correct password', () => {
    const platform = new DealDropPlatform(freshSeed());
    const result = platform.authenticate({
      email: SEEDED_EMAIL,
      password: SEEDED_PASSWORD,
      mode: 'sign_in',
    });
    expect(result.session.email).toBe(SEEDED_EMAIL);
    expect(result.session.role).toBe('user');
  });

  it('rejects a wrong password with invalid_credentials', () => {
    const platform = new DealDropPlatform(freshSeed());
    expect(() =>
      platform.authenticate({ email: SEEDED_EMAIL, password: 'wrong', mode: 'sign_in' }),
    ).toThrow('invalid_credentials');
  });

  it('rejects an unknown email with invalid_credentials', () => {
    const platform = new DealDropPlatform(freshSeed());
    expect(() =>
      platform.authenticate({ email: 'nobody@dealdrop.app', password: 'x', mode: 'sign_in' }),
    ).toThrow('invalid_credentials');
  });

  it('normalizes email casing/whitespace on sign in', () => {
    const platform = new DealDropPlatform(freshSeed());
    const result = platform.authenticate({
      email: '  ALEX@DealDrop.app  ',
      password: SEEDED_PASSWORD,
      mode: 'sign_in',
    });
    expect(result.session.email).toBe(SEEDED_EMAIL);
  });
});

describe('seed platform auth — sign up', () => {
  it('creates a new user with a default neighborhood and user role', () => {
    const platform = new DealDropPlatform(freshSeed());
    const result = platform.authenticate({
      email: 'newbie@dealdrop.app',
      password: 'pw',
      displayName: 'Newbie',
      mode: 'sign_up',
    });
    expect(result.session.userId).toMatch(/^usr_/);
    expect(result.session.role).toBe('user');
    expect(result.session.verifiedContributor).toBe(false);
    expect(result.profile.homeNeighborhood).toBe('Midtown');
  });

  it('rejects sign up for an existing email with email_already_exists', () => {
    const platform = new DealDropPlatform(freshSeed());
    expect(() =>
      platform.authenticate({ email: SEEDED_EMAIL, password: 'pw', mode: 'sign_up' }),
    ).toThrow('email_already_exists');
  });
});

describe('seed platform auth — bootstrap (upsert, no cascade delete)', () => {
  it('creates a profile for a brand-new authenticated identity', () => {
    const platform = new DealDropPlatform(freshSeed());
    const result = platform.bootstrapAuthenticatedUser(
      {
        userId: 'usr_brand_new',
        email: 'brand@dealdrop.app',
        role: 'user',
        displayName: 'Brand New',
        verifiedContributor: false,
      },
      { displayName: 'Brand New', homeNeighborhood: 'Inman Park' },
    );
    expect(result.session.userId).toBe('usr_brand_new');
    expect(result.profile.homeNeighborhood).toBe('Inman Park');
  });

  it('updates an existing profile in place WITHOUT deleting prior data', () => {
    const seed = freshSeed();
    const platform = new DealDropPlatform(seed);
    const favoritesBefore = seed.favoriteIdsByUser['usr_alex'] ?? [];

    const result = platform.bootstrapAuthenticatedUser(
      {
        userId: 'usr_alex',
        email: 'alex@dealdrop.app',
        role: 'moderator',
        displayName: 'Alex Updated',
        verifiedContributor: true,
      },
      { displayName: 'Alex Updated', homeNeighborhood: 'Cabbagetown' },
    );

    expect(result.session.role).toBe('moderator');
    expect(result.profile.displayName).toBe('Alex Updated');
    expect(result.profile.homeNeighborhood).toBe('Cabbagetown');
    // The in-memory path is an upsert: favorites are preserved, not cascaded away.
    expect(seed.favoriteIdsByUser['usr_alex']).toEqual(favoritesBefore);
  });
});
