import type { ListingDetail } from '@dealdrop/shared-types';

export function buildSearchText(listing: ListingDetail): string {
  return [listing.title, listing.venueName, listing.neighborhood, listing.cuisine, ...listing.tags].join(' ').toLowerCase();
}
