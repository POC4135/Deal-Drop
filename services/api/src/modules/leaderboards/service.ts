import type { LeaderboardEntry } from '@dealdrop/shared-types';

export function topThree(entries: LeaderboardEntry[]): LeaderboardEntry[] {
  return entries.slice(0, 3);
}
