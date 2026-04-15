import type { KarmaSummary, LeaderboardEntry, LeaderboardWindow, PointsLedgerEntry } from '@dealdrop/shared-types';

export type BadgeDefinition = {
  code: string;
  title: string;
  description: string;
  minPoints: number;
};

export function deriveLevel(points: number): string {
  if (points >= 400) {
    return 'Neighborhood Anchor';
  }
  if (points >= 220) {
    return 'Freshness Captain';
  }
  if (points >= 100) {
    return 'Verified Contributor';
  }
  if (points >= 35) {
    return 'Deal Scout';
  }
  return 'Newcomer';
}

export function computePendingPoints(entries: PointsLedgerEntry[]): number {
  return entries.filter((entry) => entry.status === 'pending').reduce((sum, entry) => sum + entry.pointsDelta, 0);
}

export function computeFinalizedPoints(entries: PointsLedgerEntry[]): number {
  return entries
    .filter((entry) => entry.status === 'finalized')
    .reduce((sum, entry) => sum + entry.pointsDelta, 0);
}

export function computeCurrentStreak(checkpoints: string[]): number {
  const normalized = [...new Set(checkpoints.map((value) => value.slice(0, 10)))].sort().reverse();
  if (normalized.length === 0) {
    return 0;
  }

  let streak = 1;
  for (let index = 1; index < normalized.length; index += 1) {
    const previous = new Date(normalized[index - 1]);
    const current = new Date(normalized[index]);
    const deltaDays = Math.round((previous.getTime() - current.getTime()) / (1000 * 60 * 60 * 24));
    if (deltaDays !== 1) {
      break;
    }
    streak += 1;
  }

  return streak;
}

export function computeLeaderboard(
  entries: PointsLedgerEntry[],
  users: Array<{ id: string; displayName: string; verifiedContributor: boolean }>,
  window: LeaderboardWindow,
): LeaderboardEntry[] {
  const now = new Date('2026-04-14T23:59:59.000Z');
  const lookbackDays = window === 'daily' ? 1 : window === 'weekly' ? 7 : 3650;
  const cutoff = now.getTime() - lookbackDays * 24 * 60 * 60 * 1000;

  const totals = new Map<string, number>();
  for (const entry of entries) {
    if (entry.status !== 'finalized') {
      continue;
    }

    if (new Date(entry.createdAt).getTime() < cutoff) {
      continue;
    }

    totals.set(entry.userId, (totals.get(entry.userId) ?? 0) + entry.pointsDelta);
  }

  return users
    .map((user) => ({
      userId: user.id,
      displayName: user.displayName,
      verifiedContributor: user.verifiedContributor,
      title: deriveLevel(totals.get(user.id) ?? 0),
      points: totals.get(user.id) ?? 0,
    }))
    .sort((left, right) => right.points - left.points || left.displayName.localeCompare(right.displayName))
    .map((entry, index) => ({
      rank: index + 1,
      ...entry,
    }));
}

export function buildKarmaSummary(input: {
  userId: string;
  entries: PointsLedgerEntry[];
  users: Array<{ id: string; displayName: string; verifiedContributor: boolean }>;
  activityDates: string[];
  badges: BadgeDefinition[];
  window: LeaderboardWindow;
}): KarmaSummary {
  const points = computeFinalizedPoints(input.entries);
  const pendingPoints = computePendingPoints(input.entries);
  const user = input.users.find((candidate) => candidate.id === input.userId);

  return {
    userId: input.userId,
    points,
    pendingPoints,
    verifiedContributor: user?.verifiedContributor ?? false,
    currentStreakDays: computeCurrentStreak(input.activityDates),
    level: deriveLevel(points),
    nextLevelPoints:
      points >= 400 ? 0 : points >= 220 ? 400 - points : points >= 100 ? 220 - points : points >= 35 ? 100 - points : 35 - points,
    impactUsersHelped: Math.max(3, points + pendingPoints),
    approvedContributions: input.entries.filter((entry) => entry.userId === input.userId && entry.status === 'finalized').length,
    pendingContributions: input.entries.filter((entry) => entry.userId === input.userId && entry.status === 'pending').length,
    badges: input.badges.map((badge) => ({
      code: badge.code,
      title: badge.title,
      description: badge.description,
      unlocked: points >= badge.minPoints,
    })),
    leaderboardWindow: input.window,
    leaderboard: computeLeaderboard(input.entries, input.users, input.window),
  };
}
