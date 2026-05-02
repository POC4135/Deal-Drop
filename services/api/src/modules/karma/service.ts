import { desc, eq, sql } from 'drizzle-orm';
import { db } from '../../db/client';
import { badges, badgeUnlocks, karmaSnapshots, leaderboardSnapshots, users } from '../../db/schema/index';

const POINTS_PER_CYCLE = 10_000; // monthly giveaway threshold

export type KarmaSnapshotResult = {
  points: number;
  pendingPoints: number;
  finalizedPoints: number;
  progress: number;
  verifiedContributor: boolean;
  badges: Array<{
    slug: string;
    title: string;
    description: string | null;
    unlockedAt: string;
  }>;
  leaderboard: Array<{
    rank: number;
    userId: string;
    displayName: string;
    badgeTitle: string | null;
    totalPoints: number;
    isCurrentUser: boolean;
  }>;
};

export async function getKarmaSnapshot(userId: string): Promise<KarmaSnapshotResult | null> {
  // Check user exists
  const [user] = await db
    .select({ verifiedContributor: users.verifiedContributor })
    .from(users)
    .where(eq(users.id, userId))
    .limit(1);

  if (!user) return null;

  // Karma snapshot (may not exist for brand new users)
  const [snap] = await db
    .select({
      totalPoints: karmaSnapshots.totalPoints,
      pendingPoints: karmaSnapshots.pendingPoints,
      finalizedPoints: karmaSnapshots.finalizedPoints,
    })
    .from(karmaSnapshots)
    .where(eq(karmaSnapshots.userId, userId))
    .limit(1);

  const total = snap?.totalPoints ?? 0;
  const pending = snap?.pendingPoints ?? 0;
  const finalized = snap?.finalizedPoints ?? 0;
  const progress = Math.min((total % POINTS_PER_CYCLE) / POINTS_PER_CYCLE, 1);

  // Unlocked badges
  const unlockedBadges = await db
    .select({
      slug: badges.slug,
      title: badges.title,
      description: badges.description,
      unlockedAt: badgeUnlocks.unlockedAt,
    })
    .from(badgeUnlocks)
    .innerJoin(badges, eq(badgeUnlocks.badgeId, badges.id))
    .where(eq(badgeUnlocks.userId, userId));

  // Latest weekly leaderboard snapshot
  const latestSnapshot = await db
    .select({ snapshotAt: leaderboardSnapshots.snapshotAt })
    .from(leaderboardSnapshots)
    .where(sql`${leaderboardSnapshots.window}::text = 'weekly'`)
    .orderBy(desc(leaderboardSnapshots.snapshotAt))
    .limit(1);

  let leaderboard: KarmaSnapshotResult['leaderboard'] = [];

  if (latestSnapshot.length > 0) {
    const { snapshotAt } = latestSnapshot[0];

    const topRows = await db
      .select({
        rank: leaderboardSnapshots.rank,
        userId: leaderboardSnapshots.userId,
        displayName: leaderboardSnapshots.displayName,
        badgeTitle: leaderboardSnapshots.badgeTitle,
        totalPoints: leaderboardSnapshots.totalPoints,
      })
      .from(leaderboardSnapshots)
      .where(
        sql`${leaderboardSnapshots.window}::text = 'weekly'
          AND ${leaderboardSnapshots.snapshotAt} = ${snapshotAt}
          AND ${leaderboardSnapshots.rank} <= 10`,
      )
      .orderBy(leaderboardSnapshots.rank);

    leaderboard = topRows.map((r) => ({
      ...r,
      badgeTitle: r.badgeTitle ?? null,
      isCurrentUser: r.userId === userId,
    }));

    // If current user is not in top 10, append their row
    const inTop = leaderboard.some((r) => r.userId === userId);
    if (!inTop) {
      const [myRow] = await db
        .select({
          rank: leaderboardSnapshots.rank,
          userId: leaderboardSnapshots.userId,
          displayName: leaderboardSnapshots.displayName,
          badgeTitle: leaderboardSnapshots.badgeTitle,
          totalPoints: leaderboardSnapshots.totalPoints,
        })
        .from(leaderboardSnapshots)
        .where(
          sql`${leaderboardSnapshots.window}::text = 'weekly'
            AND ${leaderboardSnapshots.snapshotAt} = ${snapshotAt}
            AND ${leaderboardSnapshots.userId} = ${userId}::uuid`,
        )
        .limit(1);

      if (myRow) {
        leaderboard.push({ ...myRow, badgeTitle: myRow.badgeTitle ?? null, isCurrentUser: true });
      }
    }
  }

  return {
    points: total,
    pendingPoints: pending,
    finalizedPoints: finalized,
    progress,
    verifiedContributor: user.verifiedContributor,
    badges: unlockedBadges.map((b) => ({
      ...b,
      description: b.description ?? null,
      unlockedAt: b.unlockedAt.toISOString(),
    })),
    leaderboard,
  };
}
