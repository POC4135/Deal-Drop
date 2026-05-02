import {
  boolean,
  index,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { accountStatusEnum, platformTypeEnum, userRoleEnum } from './enums';

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    // Subject from Cognito (or stub in dev). Unique per provider.
    authProviderSubject: text('auth_provider_subject').unique().notNull(),
    // Stored lowercase at write time; unique constraint enforces dedup.
    email: text('email').unique().notNull(),
    displayName: text('display_name').notNull(),
    avatarUrl: text('avatar_url'),
    role: userRoleEnum('role').default('user').notNull(),
    status: accountStatusEnum('status').default('active').notNull(),
    verifiedContributor: boolean('verified_contributor').default(false).notNull(),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_users_role_status').on(t.role, t.status),
  ],
);

export const userProfiles = pgTable('user_profiles', {
  userId: uuid('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  bio: text('bio'),
  homeNeighborhood: text('home_neighborhood'),
  defaultCity: text('default_city'),
  marketingOptIn: boolean('marketing_opt_in').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const deviceSessions = pgTable(
  'device_sessions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    deviceIdentifier: text('device_identifier').notNull(),
    platform: platformTypeEnum('platform').notNull(),
    appVersion: text('app_version'),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_device_sessions_user_last_seen').on(t.userId, t.lastSeenAt),
    uniqueIndex('uq_device_sessions_user_device').on(t.userId, t.deviceIdentifier),
  ],
);
