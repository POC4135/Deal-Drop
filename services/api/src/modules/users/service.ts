import type { Profile } from '@dealdrop/shared-types';

export function summarizeProfile(profile: Profile): string {
  return `${profile.displayName} (${profile.homeNeighborhood})`;
}
