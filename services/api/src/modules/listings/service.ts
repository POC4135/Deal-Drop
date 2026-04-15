import type { ListingDetail } from '@dealdrop/shared-types';

export function isFreshListing(listing: ListingDetail, now = new Date()): boolean {
  return new Date(listing.freshUntilAt).getTime() >= now.getTime();
}
