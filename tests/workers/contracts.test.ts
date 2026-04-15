import { describe, expect, it } from 'vitest';

import { eventTypes, queueNames } from '@dealdrop/config';

describe('worker and event contracts', () => {
  it('defines queue names for every async processor', () => {
    expect(queueNames.readModelProjector).toBeTruthy();
    expect(queueNames.trustScorer).toBeTruthy();
    expect(queueNames.gamificationProjector).toBeTruthy();
    expect(queueNames.staleListingScan).toBeTruthy();
  });

  it('defines the expected event catalog', () => {
    expect(eventTypes.contributionSubmitted).toBe('contribution.submitted');
    expect(eventTypes.leaderboardRefreshNeeded).toBe('leaderboard.refresh-needed');
  });
});
