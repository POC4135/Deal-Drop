import { describe, expect, it } from 'vitest';

import { DealDropPlatform } from '../../services/api/src/bootstrap/platform.js';
import { haversineDistanceMiles, isPointInBounds } from '../../services/api/src/lib/geo.js';

describe('geospatial support', () => {
  it('calculates distances in miles', () => {
    const miles = haversineDistanceMiles(33.7867, -84.4112, 33.7815, -84.3873);
    expect(miles).toBeGreaterThan(0.5);
  });

  it('filters listings inside map bounds', async () => {
    const platform = new DealDropPlatform();
    const listings = await platform.getMapBounds({
      north: 33.79,
      south: 33.76,
      east: -84.35,
      west: -84.42,
    });

    expect(listings.length).toBeGreaterThan(0);
    expect(
      listings.every((listing) =>
        isPointInBounds(listing.latitude, listing.longitude, 33.79, 33.76, -84.35, -84.42),
      ),
    ).toBe(true);
  });
});
