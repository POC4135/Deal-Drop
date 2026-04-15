import type { VenueDetail } from '@dealdrop/shared-types';

export function sortVenuesForAdmin(venues: VenueDetail[]): VenueDetail[] {
  return [...venues].sort((left, right) => left.neighborhood.localeCompare(right.neighborhood) || left.name.localeCompare(right.name));
}
