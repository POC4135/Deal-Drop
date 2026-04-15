import type { MapListing } from '@dealdrop/shared-types';

export function clusterKey(listing: MapListing, precision = 2): string {
  return `${listing.latitude.toFixed(precision)}:${listing.longitude.toFixed(precision)}`;
}
