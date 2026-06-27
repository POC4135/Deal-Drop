/**
 * Characterization (golden master) for the gamification/karma engine.
 *
 * UNLIKE the trust engine, several functions here read the real wall clock:
 *   - computeLeaderboard() uses `new Date()` to apply daily/weekly/all_time
 *     lookback windows.
 *   - computeCurrentStreak() parses calendar dates relative to ordering.
 * The launch seed's points ledger uses FIXED past dates (2026-04-14), so the
 * leaderboard output depends on when the suite runs. We therefore FREEZE THE
 * CLOCK to a fixed instant so the golden master is deterministic and pins the
 * actual windowing behavior.
 *
 * Source under test: services/api/src/modules/gamification/engine.ts
 *                    (+ DealDropPlatform.getKarma / getLeaderboard wiring)
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { PointsLedgerEntry } from '@dealdrop/shared-types';

import {
  buildKarmaSummary,
  computeCurrentStreak,
  computeFinalizedPoints,
  computeLeaderboard,
  computePendingPoints,
  deriveLevel,
} from '../../services/api/src/modules/gamification/engine.js';
import { DealDropPlatform } from '../../services/api/src/bootstrap/platform.js';
import { freshSeed } from './_support.js';

// One day after the seed's most recent ledger entries — keeps the daily/weekly
// windows meaningful and the output deterministic regardless of real date.
const FROZEN_NOW = new Date('2026-04-15T12:00:00.000Z');

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(FROZEN_NOW);
});

afterEach(() => {
  vi.useRealTimers();
});

describe('gamification engine — level thresholds', () => {
  it.each([
    [0, 'Newcomer'],
    [34, 'Newcomer'],
    [35, 'Deal Scout'],
    [99, 'Deal Scout'],
    [100, 'Verified Contributor'],
    [219, 'Verified Contributor'],
    [220, 'Freshness Captain'],
    [399, 'Freshness Captain'],
    [400, 'Neighborhood Anchor'],
    [10_000, 'Neighborhood Anchor'],
  ])('deriveLevel(%i) === %s', (points, expected) => {
    expect(deriveLevel(points)).toBe(expected);
  });
});

describe('gamification engine — points aggregation', () => {
  const entries: PointsLedgerEntry[] = [
    { id: 'a', userId: 'u1', reason: 'x', pointsDelta: 10, status: 'finalized', createdAt: '2026-04-14T00:00:00.000Z' },
    { id: 'b', userId: 'u1', reason: 'x', pointsDelta: 5, status: 'pending', createdAt: '2026-04-14T00:00:00.000Z' },
    { id: 'c', userId: 'u1', reason: 'x', pointsDelta: 7, status: 'reversed', createdAt: '2026-04-14T00:00:00.000Z' },
    { id: 'd', userId: 'u1', reason: 'x', pointsDelta: 3, status: 'finalized', createdAt: '2026-04-14T00:00:00.000Z' },
  ];

  it('counts only finalized deltas as finalized points', () => {
    expect(computeFinalizedPoints(entries)).toBe(13);
  });

  it('counts only pending deltas as pending points (reversed excluded)', () => {
    expect(computePendingPoints(entries)).toBe(5);
  });

  it('returns 0 for empty ledgers', () => {
    expect(computeFinalizedPoints([])).toBe(0);
    expect(computePendingPoints([])).toBe(0);
  });
});

describe('gamification engine — streak counting', () => {
  it('counts consecutive calendar days, de-duplicating same-day timestamps', () => {
    const dates = [
      '2026-04-15T20:00:00.000Z',
      '2026-04-15T08:00:00.000Z', // duplicate day
      '2026-04-14T09:00:00.000Z',
      '2026-04-13T09:00:00.000Z',
    ];
    expect(computeCurrentStreak(dates)).toBe(3);
  });

  it('breaks the streak on a gap', () => {
    const dates = ['2026-04-15', '2026-04-14', '2026-04-11'];
    expect(computeCurrentStreak(dates)).toBe(2);
  });

  it('returns 0 for no activity', () => {
    expect(computeCurrentStreak([])).toBe(0);
  });
});

describe('gamification engine — leaderboard windows (frozen clock)', () => {
  it('pins daily/weekly/all_time leaderboards over the launch seed', () => {
    const seed = freshSeed();
    const users = seed.users.map((u) => ({
      id: u.id,
      displayName: u.displayName,
      verifiedContributor: u.verifiedContributor,
    }));

    const windows = (['daily', 'weekly', 'all_time'] as const).map((window) => ({
      window,
      entries: computeLeaderboard(seed.pointsLedger, users, window),
    }));

    expect(windows).toMatchSnapshot();
  });
});

describe('gamification engine — karma summary (frozen clock)', () => {
  it('pins the full karma summary for a seeded contributor via the platform', async () => {
    const platform = new DealDropPlatform(freshSeed());
    const summary = await platform.getKarma('usr_alex', 'weekly');
    expect(summary).toMatchSnapshot();
  });
});
