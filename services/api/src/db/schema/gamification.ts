import {
  index,
  integer,
  jsonb,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import {
  karmaEventTypeEnum,
  leaderboardWindowEnum,
  pointsStateEnum,
} from './enums';
import { users } from './identity';
import { contributions } from './contributions';
import { confirmations, } from './trust';
import { reports } from './contributions';

// Immutable points ledger. Never updated — reversals are new rows with
// negative points and a reference to the original event.
export const karmaEvents = pgTable(
  'karma_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    eventType: karmaEventTypeEnum('event_type').notNull(),
    state: pointsStateEnum('state').default('pending').notNull(),
    points: integer('points').notNull(),
    contributionId: uuid('contribution_id').references(() => contributions.id, {
      onDelete: 'set null',
    }),
    confirmationId: uuid('confirmation_id').references(() => confirmations.id, {
      onDelete: 'set null',
    }),
    reportId: uuid('report_id').references(() => reports.id, {
      onDelete: 'set null',
    }),
    // Points back to the event being reversed, for reversal rows.
    reversedByEventId: uuid('reversed_by_event_id'),
    metadata: jsonb('metadata'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_karma_events_user_created').on(t.userId, t.createdAt),
    index('idx_karma_events_state_created').on(t.state, t.createdAt),
    index('idx_karma_events_contribution').on(t.contributionId),
    index('idx_karma_events_confirmation').on(t.confirmationId),
    index('idx_karma_events_report').on(t.reportId),
  ],
);

// Materialized summary — updated by gamification-projector worker after each
// finalized karma event. Read by profile and leaderboard endpoints.
export const karmaSnapshots = pgTable('karma_snapshots', {
  userId: uuid('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  totalPoints: integer('total_points').default(0).notNull(),
  pendingPoints: integer('pending_points').default(0).notNull(),
  finalizedPoints: integer('finalized_points').default(0).notNull(),
  currentTier: text('current_tier'),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

// Badge catalog. Managed by admin; slugs are stable identifiers.
export const badges = pgTable('badges', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: text('slug').unique().notNull(),
  title: text('title').notNull(),
  description: text('description'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

// Durable badge award history per user.
export const badgeUnlocks = pgTable(
  'badge_unlocks',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    badgeId: uuid('badge_id')
      .notNull()
      .references(() => badges.id, { onDelete: 'cascade' }),
    unlockedAt: timestamp('unlocked_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.userId, t.badgeId] }),
  ],
);

// Streak state per user — updated by gamification-projector worker.
export const streakCheckpoints = pgTable('streak_checkpoints', {
  userId: uuid('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  currentStreak: integer('current_streak').default(0).notNull(),
  longestStreak: integer('longest_streak').default(0).notNull(),
  lastQualifiedAt: timestamp('last_qualified_at', { withTimezone: true }),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

// Pre-computed leaderboard rows. One row per (window, snapshot_at, rank).
// Refreshed by the leaderboard-refresher worker on each cycle.
export const leaderboardSnapshots = pgTable(
  'leaderboard_snapshots',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    window: leaderboardWindowEnum('window').notNull(),
    snapshotAt: timestamp('snapshot_at', { withTimezone: true }).notNull(),
    rank: integer('rank').notNull(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    // Denormalized for fast reads without joining users.
    displayName: text('display_name').notNull(),
    totalPoints: integer('total_points').notNull(),
    badgeTitle: text('badge_title'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    uniqueIndex('uq_leaderboard_window_snapshot_rank').on(
      t.window,
      t.snapshotAt,
      t.rank,
    ),
    index('idx_leaderboard_window_snapshot').on(t.window, t.snapshotAt),
    index('idx_leaderboard_window_user').on(t.window, t.userId, t.snapshotAt),
  ],
);
