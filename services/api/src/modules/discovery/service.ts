import type { FeedSection, ListingCard } from '@dealdrop/shared-types';

export function buildFeedSection(id: string, title: string, subtitle: string, items: ListingCard[]): FeedSection {
  return { id, title, subtitle, items };
}
