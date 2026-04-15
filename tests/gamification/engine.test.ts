import { describe, expect, it } from 'vitest';

import { buildKarmaSummary, computeLeaderboard, deriveLevel } from '../../services/api/src/modules/gamification/engine.js';
import { atlantaSeed } from '../../services/api/src/db/seeds/atlanta.js';

describe('gamification engine', () => {
  it('derives levels from finalized points', () => {
    expect(deriveLevel(20)).toBe('Newcomer');
    expect(deriveLevel(120)).toBe('Verified Contributor');
  });

  it('computes a ranked weekly leaderboard', () => {
    const leaderboard = computeLeaderboard(
      atlantaSeed.pointsLedger,
      atlantaSeed.users.map((user) => ({
        id: user.id,
        displayName: user.displayName,
        verifiedContributor: user.verifiedContributor,
      })),
      'weekly',
    );

    expect(leaderboard[0].points).toBeGreaterThanOrEqual(leaderboard[1].points);
    expect(leaderboard[0].rank).toBe(1);
  });

  it('builds a karma summary with pending points', () => {
    const summary = buildKarmaSummary({
      userId: 'usr_alex',
      entries: atlantaSeed.pointsLedger.filter((entry) => entry.userId === 'usr_alex'),
      users: atlantaSeed.users.map((user) => ({
        id: user.id,
        displayName: user.displayName,
        verifiedContributor: user.verifiedContributor,
      })),
      activityDates: ['2026-04-14T20:55:00.000Z', '2026-04-13T19:00:00.000Z'],
      badges: [{ code: 'first-proof', title: 'First Proof', description: 'desc', minPoints: 10 }],
      window: 'weekly',
    });

    expect(summary.pendingPoints).toBeGreaterThan(0);
    expect(summary.badges[0].unlocked).toBe(true);
  });
});
