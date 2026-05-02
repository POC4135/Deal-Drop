import {
  index,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';
import { users } from './identity';
import { listings } from './listings';

export const favorites = pgTable(
  'favorites',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.userId, t.listingId] }),
    index('idx_favorites_user_created').on(t.userId, t.createdAt),
    index('idx_favorites_listing').on(t.listingId),
  ],
);

// Tracks guest-local bulk syncs after sign-in to prevent double-inserts
// when the app retries an offline favorites merge.
export const favoriteSyncBatches = pgTable('favorite_sync_batches', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  // Client-generated key scoped to one sync operation.
  idempotencyKey: text('idempotency_key').unique().notNull(),
  payloadHash: text('payload_hash').notNull(),
  processedAt: timestamp('processed_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
