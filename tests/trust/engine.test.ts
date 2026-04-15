import { describe, expect, it } from 'vitest';

import { computeConfidence } from '../../services/api/src/modules/trust/engine.js';

describe('trust engine', () => {
  it('rewards proof-backed confirmations', () => {
    const result = computeConfidence({
      sourceType: 'user',
      recentConfirmations: 4,
      recentReports: 0,
      contributorTrustScore: 0.8,
      proofCount: 2,
      hoursSinceLastVerified: 2,
    });

    expect(result.confidenceScore).toBeGreaterThan(0.75);
    expect(result.trustBand).toBe('user_confirmed');
  });

  it('degrades stale listings with repeated reports', () => {
    const result = computeConfidence({
      sourceType: 'user',
      recentConfirmations: 1,
      recentReports: 3,
      contributorTrustScore: 0.2,
      proofCount: 0,
      hoursSinceLastVerified: 36,
    });

    expect(result.confidenceScore).toBeLessThan(0.4);
    expect(result.trustBand).toBe('needs_recheck');
  });
});
