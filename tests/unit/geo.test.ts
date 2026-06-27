/**
 * Unit tests for the geo utilities — pure, deterministic math.
 * Source: services/api/src/lib/geo.ts
 */
import { describe, expect, it } from 'vitest';

import { haversineDistanceMiles, isPointInBounds } from '../../services/api/src/lib/geo.js';

describe('haversineDistanceMiles', () => {
  it('returns 0 for identical points', () => {
    expect(haversineDistanceMiles(33.78, -84.4, 33.78, -84.4)).toBe(0);
  });

  it('is symmetric', () => {
    const ab = haversineDistanceMiles(33.7867, -84.4112, 33.7815, -84.3873);
    const ba = haversineDistanceMiles(33.7815, -84.3873, 33.7867, -84.4112);
    expect(ab).toBeCloseTo(ba, 10);
  });

  it('approximates a known distance (Atlanta block ~1.4mi)', () => {
    const miles = haversineDistanceMiles(33.7867, -84.4112, 33.7815, -84.3873);
    expect(miles).toBeGreaterThan(1.3);
    expect(miles).toBeLessThan(1.6);
  });

  it('handles antipodal-ish large separations without NaN', () => {
    const miles = haversineDistanceMiles(33.78, -84.4, -33.78, 95.6);
    expect(Number.isFinite(miles)).toBe(true);
    expect(miles).toBeGreaterThan(8000);
  });
});

describe('isPointInBounds', () => {
  const bounds = { north: 33.79, south: 33.76, east: -84.35, west: -84.42 };

  it('includes a point inside the box', () => {
    expect(isPointInBounds(33.78, -84.39, bounds.north, bounds.south, bounds.east, bounds.west)).toBe(true);
  });

  it('is inclusive on the boundary edges', () => {
    expect(isPointInBounds(bounds.north, bounds.east, bounds.north, bounds.south, bounds.east, bounds.west)).toBe(true);
    expect(isPointInBounds(bounds.south, bounds.west, bounds.north, bounds.south, bounds.east, bounds.west)).toBe(true);
  });

  it('excludes points outside each edge', () => {
    expect(isPointInBounds(33.80, -84.39, bounds.north, bounds.south, bounds.east, bounds.west)).toBe(false); // north
    expect(isPointInBounds(33.75, -84.39, bounds.north, bounds.south, bounds.east, bounds.west)).toBe(false); // south
    expect(isPointInBounds(33.78, -84.34, bounds.north, bounds.south, bounds.east, bounds.west)).toBe(false); // east
    expect(isPointInBounds(33.78, -84.43, bounds.north, bounds.south, bounds.east, bounds.west)).toBe(false); // west
  });
});
