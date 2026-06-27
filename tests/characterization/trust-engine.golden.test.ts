/**
 * Characterization (golden master) for the trust/confidence engine.
 *
 * `computeConfidence` is pure and deterministic — no clock, no randomness — so it
 * is an ideal golden-master target. We pin:
 *   1. A representative input grid → snapshot of the full output (score, band,
 *      visibility, freshness windows). This catches ANY change to the scoring or
 *      banding math, including currently-"wrong" behavior.
 *   2. A handful of explicit boundary assertions that document the intent of
 *      specific branches, so a reviewer can see what each region means.
 *
 * Source under test: services/api/src/modules/trust/engine.ts
 */
import { describe, expect, it } from 'vitest';

import {
  computeConfidence,
  type ConfidenceComputationInput,
} from '../../services/api/src/modules/trust/engine.js';

const SOURCE_TYPES: ConfidenceComputationInput['sourceType'][] = [
  'founder',
  'merchant',
  'user',
  'moderator',
];

// A focused grid: every source type crossed with the inputs that flip a branch —
// confirmation boost (0 vs capped at 3), the report ladder that drives disputes
// and visibility (0/1/2/4), proof cap (0 vs 4), contributor trust (0 vs 1), and
// the staleness penalty boundaries (1h fresh / 36h / 96h). Kept deliberately
// compact so the golden master stays human-reviewable in a diff.
const CONFIRMATIONS = [0, 3];
const REPORTS = [0, 1, 2, 4];
const PROOFS = [0, 4];
const TRUST = [0, 1];
const HOURS = [1, 36, 96];

function buildGrid(): Array<{ input: ConfidenceComputationInput; output: ReturnType<typeof computeConfidence> }> {
  const rows: Array<{ input: ConfidenceComputationInput; output: ReturnType<typeof computeConfidence> }> = [];
  for (const sourceType of SOURCE_TYPES) {
    for (const recentConfirmations of CONFIRMATIONS) {
      for (const recentReports of REPORTS) {
        for (const proofCount of PROOFS) {
          for (const contributorTrustScore of TRUST) {
            for (const hoursSinceLastVerified of HOURS) {
              const input: ConfidenceComputationInput = {
                sourceType,
                recentConfirmations,
                recentReports,
                proofCount,
                contributorTrustScore,
                hoursSinceLastVerified,
              };
              rows.push({ input, output: computeConfidence(input) });
            }
          }
        }
      }
    }
  }
  return rows;
}

describe('trust engine — golden master', () => {
  it('pins computeConfidence across the representative input grid', () => {
    // One compact line per case: a stable input signature mapped to the derived
    // outputs. Far more reviewable than a deep object dump, and still flags any
    // change to the score (rounded to 4dp), band, visibility, or freshness math.
    const golden: Record<string, string> = {};
    for (const { input, output } of buildGrid()) {
      const key = [
        input.sourceType,
        `c${input.recentConfirmations}`,
        `r${input.recentReports}`,
        `p${input.proofCount}`,
        `t${input.contributorTrustScore}`,
        `h${input.hoursSinceLastVerified}`,
      ].join('|');
      golden[key] = [
        `score=${output.confidenceScore.toFixed(4)}`,
        `band=${output.trustBand}`,
        `vis=${output.visibilityState}`,
        `fresh=${output.freshUntilHours}`,
        `recheck=${output.recheckAfterHours}`,
      ].join(' ');
    }
    expect(golden).toMatchSnapshot();
  });

  it('clamps the confidence score to the documented [0.05, 0.99] range', () => {
    let min = Infinity;
    let max = -Infinity;
    for (const { output } of buildGrid()) {
      min = Math.min(min, output.confidenceScore);
      max = Math.max(max, output.confidenceScore);
    }
    expect(min).toBeGreaterThanOrEqual(0.05);
    expect(max).toBeLessThanOrEqual(0.99);
  });
});

describe('trust engine — boundary behaviors (documented intent)', () => {
  it('marks a listing disputed when reports >= 2 and confidence < 0.5', () => {
    const result = computeConfidence({
      sourceType: 'user',
      recentConfirmations: 0,
      recentReports: 3,
      contributorTrustScore: 0,
      proofCount: 0,
      hoursSinceLastVerified: 48,
    });
    expect(result.confidenceScore).toBeLessThan(0.5);
    expect(result.trustBand).toBe('disputed');
  });

  it('grants founder_verified only to high-confidence founder sources', () => {
    const result = computeConfidence({
      sourceType: 'founder',
      recentConfirmations: 3,
      recentReports: 0,
      contributorTrustScore: 1,
      proofCount: 4,
      hoursSinceLastVerified: 1,
    });
    expect(result.confidenceScore).toBeGreaterThanOrEqual(0.9);
    expect(result.trustBand).toBe('founder_verified');
    expect(result.freshUntilHours).toBe(30);
    expect(result.recheckAfterHours).toBe(40);
  });

  it('suppresses visibility below 0.22 and shadow-hides below 0.4', () => {
    const suppressed = computeConfidence({
      sourceType: 'user',
      recentConfirmations: 0,
      recentReports: 4,
      contributorTrustScore: 0,
      proofCount: 0,
      hoursSinceLastVerified: 96,
    });
    expect(suppressed.confidenceScore).toBeLessThan(0.22);
    expect(suppressed.visibilityState).toBe('suppressed');

    const shadow = computeConfidence({
      sourceType: 'user',
      recentConfirmations: 0,
      recentReports: 2,
      contributorTrustScore: 0,
      proofCount: 0,
      hoursSinceLastVerified: 36,
    });
    expect(shadow.confidenceScore).toBeGreaterThanOrEqual(0.22);
    expect(shadow.confidenceScore).toBeLessThan(0.4);
    expect(shadow.visibilityState).toBe('shadow_hidden');
  });

  it('applies no staleness penalty at or before the 12-hour grace window', () => {
    const fresh = computeConfidence({
      sourceType: 'merchant',
      recentConfirmations: 0,
      recentReports: 0,
      contributorTrustScore: 0,
      proofCount: 0,
      hoursSinceLastVerified: 12,
    });
    const stale = computeConfidence({
      sourceType: 'merchant',
      recentConfirmations: 0,
      recentReports: 0,
      contributorTrustScore: 0,
      proofCount: 0,
      hoursSinceLastVerified: 84,
    });
    expect(fresh.confidenceScore).toBeGreaterThan(stale.confidenceScore);
  });
});
