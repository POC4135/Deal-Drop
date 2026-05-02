import {
  boolean,
  index,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import {
  notificationDeliveryStatusEnum,
  notificationKindEnum,
  platformTypeEnum,
} from './enums';
import { users } from './identity';

// User-level notification toggles — persisted server-side so preferences
// are enforced at dispatch time, not only in the mobile UI.
export const notificationPreferences = pgTable('notification_preferences', {
  userId: uuid('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  contributionResolved: boolean('contribution_resolved').default(true).notNull(),
  pointsFinalized: boolean('points_finalized').default(true).notNull(),
  trustStatusChanged: boolean('trust_status_changed').default(true).notNull(),
  marketingAnnouncements: boolean('marketing_announcements').default(false).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

// Durable notification inbox. Read/unread state is first-class.
export const notifications = pgTable(
  'notifications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    kind: notificationKindEnum('kind').notNull(),
    title: text('title').notNull(),
    body: text('body').notNull(),
    // Polymorphic reference for deep-linking (listing / contribution / etc).
    referenceType: text('reference_type'),
    referenceId: uuid('reference_id'),
    // App navigation hint passed to the mobile router.
    deepLink: text('deep_link'),
    metadata: jsonb('metadata'),
    readAt: timestamp('read_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_notifications_user_created').on(t.userId, t.createdAt),
    index('idx_notifications_user_read').on(t.userId, t.readAt),
  ],
);

// Device push token registry. One row per (user, device) pair.
// Token is replaced in-place when the OS rotates it.
export const deviceRegistrations = pgTable(
  'device_registrations',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    platform: platformTypeEnum('platform').notNull(),
    // Stable app-side identifier (e.g. UUID generated once at install).
    deviceIdentifier: text('device_identifier').notNull(),
    pushToken: text('push_token').notNull(),
    appVersion: text('app_version'),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull(),
    // Set when the token is revoked or the user signs out on the device.
    disabledAt: timestamp('disabled_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    uniqueIndex('uq_device_registrations_user_device').on(t.userId, t.deviceIdentifier),
    index('idx_device_registrations_user_disabled').on(t.userId, t.disabledAt),
  ],
);

// Push delivery attempt log. Tracked per notification × device for
// retry visibility and failure analysis.
export const notificationDeliveries = pgTable(
  'notification_deliveries',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    notificationId: uuid('notification_id')
      .notNull()
      .references(() => notifications.id, { onDelete: 'cascade' }),
    deviceId: uuid('device_id')
      .notNull()
      .references(() => deviceRegistrations.id, { onDelete: 'cascade' }),
    // push / inbox / etc.
    channel: text('channel').notNull(),
    status: notificationDeliveryStatusEnum('status').default('queued').notNull(),
    // FCM / APNS message id.
    providerMessageId: text('provider_message_id'),
    attemptedAt: timestamp('attempted_at', { withTimezone: true }),
    deliveredAt: timestamp('delivered_at', { withTimezone: true }),
    failedAt: timestamp('failed_at', { withTimezone: true }),
    failureReason: text('failure_reason'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_notification_deliveries_notification').on(t.notificationId),
    index('idx_notification_deliveries_device').on(t.deviceId),
    index('idx_notification_deliveries_status').on(t.status, t.createdAt),
  ],
);
