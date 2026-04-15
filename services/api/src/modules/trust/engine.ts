import type { TrustBand, VisibilityState } from '@dealdrop/shared-types';

export type ConfidenceComputationInput = {
  sourceType: 'founder' | 'merchant' | 'user' | 'moderator';
  recentConfirmations: number;
  recentReports: number;
  contributorTrustScore: number;
  proofCount: number;
  hoursSinceLastVerified: number;
  moderatorBoost?: number;
};

export type ConfidenceComputation = {
  confidenceScore: number;
  trustBand: TrustBand;
  visibilityState: VisibilityState;
  freshUntilHours: number;
  recheckAfterHours: number;
};

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function computeConfidence(input: ConfidenceComputationInput): ConfidenceComputation {
  const sourceBase =
    input.sourceType === 'founder'
      ? 0.86
      : input.sourceType === 'merchant'
        ? 0.8
        : input.sourceType === 'moderator'
          ? 0.76
          : 0.64;

  const confirmationBoost = Math.min(input.recentConfirmations * 0.06, 0.18);
  const reportPenalty = input.recentReports * 0.14;
  const proofBoost = Math.min(input.proofCount * 0.04, 0.12);
  const contributorBoost = clamp(input.contributorTrustScore, 0, 1) * 0.09;
  const stalenessPenalty = Math.max(0, (input.hoursSinceLastVerified - 12) / 72) * 0.28;
  const moderatorBoost = input.moderatorBoost ?? 0;

  const confidenceScore = clamp(
    sourceBase + confirmationBoost + proofBoost + contributorBoost + moderatorBoost - reportPenalty - stalenessPenalty,
    0.05,
    0.99,
  );

  const trustBand: TrustBand =
    input.recentReports >= 2 && confidenceScore < 0.5
      ? 'disputed'
      : confidenceScore >= 0.9 && input.sourceType === 'founder'
      ? 'founder_verified'
      : confidenceScore >= 0.82 && input.sourceType === 'merchant'
        ? 'merchant_confirmed'
      : confidenceScore >= 0.74
        ? 'user_confirmed'
        : confidenceScore >= 0.55
          ? 'recently_updated'
          : 'needs_recheck';

  const visibilityState: VisibilityState =
    confidenceScore < 0.22 ? 'suppressed' : confidenceScore < 0.4 ? 'shadow_hidden' : 'visible';

  const freshUntilHours =
    trustBand === 'founder_verified'
      ? 30
      : trustBand === 'merchant_confirmed'
        ? 24
      : trustBand === 'user_confirmed'
        ? 16
      : trustBand === 'recently_updated'
        ? 8
      : trustBand === 'disputed'
        ? 3
      : 4;

  const recheckAfterHours =
    trustBand === 'founder_verified'
      ? 40
      : trustBand === 'merchant_confirmed'
        ? 32
      : trustBand === 'user_confirmed'
        ? 24
      : trustBand === 'recently_updated'
        ? 12
      : trustBand === 'disputed'
        ? 4
      : 6;

  return {
    confidenceScore,
    trustBand,
    visibilityState,
    freshUntilHours,
    recheckAfterHours,
  };
}
