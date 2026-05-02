export const karmaSnapshotResponseSchema = {
  type: 'object',
  properties: {
    points: { type: 'number' },
    pendingPoints: { type: 'number' },
    finalizedPoints: { type: 'number' },
    progress: { type: 'number' },
    verifiedContributor: { type: 'boolean' },
    badges: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          slug: { type: 'string' },
          title: { type: 'string' },
          description: { type: 'string', nullable: true },
          unlockedAt: { type: 'string' },
        },
      },
    },
    leaderboard: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          rank: { type: 'number' },
          userId: { type: 'string' },
          displayName: { type: 'string' },
          badgeTitle: { type: 'string', nullable: true },
          totalPoints: { type: 'number' },
          isCurrentUser: { type: 'boolean' },
        },
      },
    },
  },
} as const;
