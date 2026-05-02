import {
  index,
  jsonb,
  pgTable,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';
import { platformTypeEnum } from './enums';
import { users } from './identity';
import { deviceRegistrations } from './notifications';

// Durable landing table for app analytics events.
// This table is a candidate for time-based partitioning once volume warrants it.
// A retention policy (e.g. drop partitions older than 90 days) should be
// configured before production rollout.
//
// Core product flows must NOT depend on this table — if telemetry fails,
// the app must continue to function.
export const telemetryEvents = pgTable(
  'telemetry_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    // Nullable: anonymous sessions before sign-in.
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
    deviceId: uuid('device_id').references(() => deviceRegistrations.id, {
      onDelete: 'set null',
    }),
    sessionId: uuid('session_id'),
    eventName: text('event_name').notNull(),
    // Validated payload shape enforced by Zod at the API boundary.
    eventPayload: jsonb('event_payload').notNull(),
    appVersion: text('app_version'),
    platform: platformTypeEnum('platform'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_telemetry_events_created').on(t.createdAt),
    index('idx_telemetry_events_name_created').on(t.eventName, t.createdAt),
    index('idx_telemetry_events_user_created').on(t.userId, t.createdAt),
  ],
);
