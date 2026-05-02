import {
  boolean,
  date,
  index,
  integer,
  numeric,
  pgTable,
  primaryKey,
  smallint,
  text,
  time,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';
import {
  listingCategoryEnum,
  listingStatusEnum,
  sourceTypeEnum,
  trustBandEnum,
} from './enums';
import { users } from './identity';
import { venues } from './venues';

export const listings = pgTable(
  'listings',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    venueId: uuid('venue_id')
      .notNull()
      .references(() => venues.id, { onDelete: 'restrict' }),
    title: text('title').notNull(),
    description: text('description'),
    category: listingCategoryEnum('category').notNull(),
    status: listingStatusEnum('status').default('draft').notNull(),
    sourceType: sourceTypeEnum('source_type').notNull(),
    sourceReference: text('source_reference'),
    trustBand: trustBandEnum('trust_band').default('recently_updated').notNull(),
    // Cached snapshot updated by trust-scorer worker.
    confidenceScore: numeric('confidence_score', { precision: 5, scale: 2 }),
    confirmationCount: integer('confirmation_count').default(0).notNull(),
    lastConfirmedAt: timestamp('last_confirmed_at', { withTimezone: true }),
    lastReportedAt: timestamp('last_reported_at', { withTimezone: true }),
    // Updated on any trust-impacting event.
    freshnessAt: timestamp('freshness_at', { withTimezone: true }),
    expiresAt: timestamp('expires_at', { withTimezone: true }),
    ageRestricted: boolean('age_restricted').default(false).notNull(),
    studentOnly: boolean('student_only').default(false).notNull(),
    createdBy: uuid('created_by').references(() => users.id, { onDelete: 'set null' }),
    updatedBy: uuid('updated_by').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
    archivedAt: timestamp('archived_at', { withTimezone: true }),
  },
  (t) => [
    index('idx_listings_venue_status').on(t.venueId, t.status),
    index('idx_listings_trust_status').on(t.trustBand, t.status),
    index('idx_listings_category_status').on(t.category, t.status),
    index('idx_listings_last_confirmed').on(t.lastConfirmedAt),
    index('idx_listings_freshness').on(t.freshnessAt),
  ],
);

// One row per tag — kept normalized for clean filtering.
export const listingTags = pgTable(
  'listing_tags',
  {
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    tag: text('tag').notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.listingId, t.tag] }),
    index('idx_listing_tags_tag').on(t.tag),
  ],
);

// Structured schedule model required for "live now" and "tonight" feed sections.
export const listingSchedules = pgTable(
  'listing_schedules',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    // 0 = Sunday … 6 = Saturday
    dayOfWeek: smallint('day_of_week').notNull(),
    startTime: time('start_time').notNull(),
    endTime: time('end_time').notNull(),
    timezone: text('timezone').default('America/New_York').notNull(),
    // Optional campaign window.
    validFrom: date('valid_from'),
    validTo: date('valid_to'),
    isRecurring: boolean('is_recurring').default(true).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_listing_schedules_listing_id').on(t.listingId),
    index('idx_listing_schedules_day_time').on(t.dayOfWeek, t.startTime, t.endTime),
  ],
);
