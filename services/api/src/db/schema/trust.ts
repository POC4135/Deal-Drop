import {
  date,
  index,
  jsonb,
  numeric,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { trustBandEnum } from './enums';
import { users } from './identity';
import { listings } from './listings';

// Canonical "confirm valid" fact table.
// One row per user per listing per calendar day — enforced by unique constraint.
export const confirmations = pgTable(
  'confirmations',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    // date (not timestamp) enables the daily idempotency constraint simply.
    confirmedOn: date('confirmed_on').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    uniqueIndex('uq_confirmations_listing_user_day').on(
      t.listingId,
      t.userId,
      t.confirmedOn,
    ),
    index('idx_confirmations_listing_created').on(t.listingId, t.createdAt),
    index('idx_confirmations_user_created').on(t.userId, t.createdAt),
  ],
);

// Unified verification event stream consumed by the trust-scorer worker.
// Immutable — never updated or deleted.
export const verificationEvents = pgTable(
  'verification_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    // Null for system-generated events (e.g. stale-sweeper).
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
    // confirm_valid / report_expired / moderator_validation / stale_flag / etc.
    eventType: text('event_type').notNull(),
    // Which table the event originated from (for replay tracing).
    sourceTable: text('source_table'),
    sourceId: uuid('source_id'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_verification_events_listing').on(t.listingId, t.createdAt),
    index('idx_verification_events_type').on(t.eventType, t.createdAt),
  ],
);

// Atomic evidence units used to compute trust scores.
// Each signal has a weight so the scorer can combine them deterministically.
export const trustSignals = pgTable(
  'trust_signals',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    // founder_seed / merchant_confirmation / user_confirm / expired_report / override
    signalType: text('signal_type').notNull(),
    // system / user / moderator / merchant
    sourceType: text('source_type').notNull(),
    sourceId: uuid('source_id'),
    weight: numeric('weight', { precision: 8, scale: 3 }).notNull(),
    metadata: jsonb('metadata'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_trust_signals_listing').on(t.listingId, t.createdAt),
    index('idx_trust_signals_type').on(t.signalType, t.createdAt),
  ],
);

// Durable snapshot of trust state after each scorer run.
// Used for history, explainability, and audit. Immutable.
export const confidenceSnapshots = pgTable(
  'confidence_snapshots',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    confidenceScore: numeric('confidence_score', { precision: 5, scale: 2 }).notNull(),
    trustBand: trustBandEnum('trust_band').notNull(),
    // Human-readable summary for UI explainability ("Confirmed by 12 locals").
    reasonSummary: text('reason_summary'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_confidence_snapshots_listing').on(t.listingId, t.createdAt),
  ],
);
