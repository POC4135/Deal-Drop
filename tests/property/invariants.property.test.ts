/**
 * Property-based / fuzz tests on pure functions that take untrusted-ish input.
 * Uses fast-check with a FIXED SEED so runs are fully deterministic (a failing
 * case reproduces identically). These assert invariants, not specific outputs.
 */
import { describe, expect, it } from 'vitest';
import fc from 'fast-check';

import { haversineDistanceMiles, isPointInBounds } from '../../services/api/src/lib/geo.js';
import { applyCursorPagination, decodeCursor, encodeCursor } from '../../services/api/src/lib/pagination.js';

const RUN = { seed: 0xdea1d309, numRuns: 300 } as const;

const lat = () => fc.double({ min: -90, max: 90, noNaN: true });
const lng = () => fc.double({ min: -180, max: 180, noNaN: true });

describe('geo invariants', () => {
  it('distance is non-negative and finite', () => {
    fc.assert(
      fc.property(lat(), lng(), lat(), lng(), (a, b, c, d) => {
        const miles = haversineDistanceMiles(a, b, c, d);
        return Number.isFinite(miles) && miles >= 0;
      }),
      RUN,
    );
  });

  it('distance is symmetric', () => {
    fc.assert(
      fc.property(lat(), lng(), lat(), lng(), (a, b, c, d) => {
        const ab = haversineDistanceMiles(a, b, c, d);
        const ba = haversineDistanceMiles(c, d, a, b);
        return Math.abs(ab - ba) < 1e-6;
      }),
      RUN,
    );
  });

  it('distance from a point to itself is zero', () => {
    fc.assert(
      fc.property(lat(), lng(), (a, b) => haversineDistanceMiles(a, b, a, b) === 0),
      RUN,
    );
  });

  it('isPointInBounds agrees with the four inequalities', () => {
    fc.assert(
      fc.property(lat(), lng(), lat(), lat(), lng(), lng(), (plat, plng, y1, y2, x1, x2) => {
        const north = Math.max(y1, y2);
        const south = Math.min(y1, y2);
        const east = Math.max(x1, x2);
        const west = Math.min(x1, x2);
        const expected = plat <= north && plat >= south && plng <= east && plng >= west;
        return isPointInBounds(plat, plng, north, south, east, west) === expected;
      }),
      RUN,
    );
  });
});

describe('pagination invariants', () => {
  it('cursor encode/decode round-trips any non-empty string', () => {
    fc.assert(
      fc.property(fc.string({ minLength: 1 }), (s) => decodeCursor(encodeCursor(s)) === s),
      RUN,
    );
  });

  it('an empty cursor is treated as "no cursor" (decodes to undefined)', () => {
    // encodeCursor('') === '' and decodeCursor('') short-circuits to undefined,
    // which the pagination layer interprets as "start from the top".
    expect(encodeCursor('')).toBe('');
    expect(decodeCursor('')).toBeUndefined();
  });

  it('a page never exceeds the requested limit and is a contiguous slice', () => {
    const arb = fc.record({
      size: fc.integer({ min: 0, max: 200 }),
      limit: fc.integer({ min: 1, max: 50 }),
    });
    fc.assert(
      fc.property(arb, ({ size, limit }) => {
        const items = Array.from({ length: size }, (_, i) => ({ id: `id_${i}` }));
        const page = applyCursorPagination(items, undefined, limit);
        if (page.items.length > limit) return false;
        // first page starts at the head
        return page.items.every((item, idx) => item.id === `id_${idx}`);
      }),
      RUN,
    );
  });

  it('walking pages by cursor visits every item exactly once', () => {
    fc.assert(
      fc.property(fc.integer({ min: 0, max: 137 }), fc.integer({ min: 1, max: 20 }), (size, limit) => {
        const items = Array.from({ length: size }, (_, i) => ({ id: `id_${i}` }));
        const seen: string[] = [];
        let cursor: string | undefined;
        // bound iterations to avoid infinite loops on a regression
        for (let guard = 0; guard <= size + 2; guard += 1) {
          const page = applyCursorPagination(items, cursor, limit);
          seen.push(...page.items.map((i) => i.id));
          if (!page.nextCursor) break;
          cursor = page.nextCursor;
        }
        return seen.length === size && new Set(seen).size === size;
      }),
      RUN,
    );
  });
});
