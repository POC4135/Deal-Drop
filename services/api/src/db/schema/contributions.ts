import {
  index,
  jsonb,
  pgTable,
  text,
  timestamp,
  uuid,
  bigint,
} from 'drizzle-orm/pg-core';
import {
  contributionStatusEnum,
  contributionTypeEnum,
  proofStatusEnum,
} from './enums';
import { users } from './identity';
import { listings } from './listings';

export const contributions = pgTable(
  'contributions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    // Null when type = 'new_listing' (venue doesn't exist yet).
    listingId: uuid('listing_id').references(() => listings.id, {
      onDelete: 'set null',
    }),
    type: contributionTypeEnum('type').notNull(),
    status: contributionStatusEnum('status').default('submitted').notNull(),
    // Normalized payload varies by type; validated by API layer via Zod.
    payload: jsonb('payload').notNull(),
    // Self-referential: set when a moderator merges a duplicate.
    duplicateOf: uuid('duplicate_of'),
    reviewerId: uuid('reviewer_id').references(() => users.id, {
      onDelete: 'set null',
    }),
    reviewedAt: timestamp('reviewed_at', { withTimezone: true }),
    moderationNotes: text('moderation_notes'),
    submittedAt: timestamp('submitted_at', { withTimezone: true }).defaultNow().notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_contributions_user_submitted').on(t.userId, t.submittedAt),
    index('idx_contributions_status_submitted').on(t.status, t.submittedAt),
    index('idx_contributions_listing_submitted').on(t.listingId, t.submittedAt),
    index('idx_contributions_type_status').on(t.type, t.status),
  ],
);

// Proof assets (photos, receipts) attached to a contribution.
export const contributionProofs = pgTable(
  'contribution_proofs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    contributionId: uuid('contribution_id')
      .notNull()
      .references(() => contributions.id, { onDelete: 'cascade' }),
    // S3 object key.
    storageKey: text('storage_key').notNull(),
    mimeType: text('mime_type'),
    fileSizeBytes: bigint('file_size_bytes', { mode: 'number' }),
    checksum: text('checksum'),
    status: proofStatusEnum('status').default('pending_upload').notNull(),
    uploadedBy: uuid('uploaded_by')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_contribution_proofs_contribution').on(t.contributionId),
  ],
);

// Explicit report record — kept separate from contributions for cleaner
// moderation queue and reporting analytics.
export const reports = pgTable(
  'reports',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    listingId: uuid('listing_id')
      .notNull()
      .references(() => listings.id, { onDelete: 'cascade' }),
    reason: text('reason'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_reports_listing_created').on(t.listingId, t.createdAt),
    index('idx_reports_user_created').on(t.userId, t.createdAt),
  ],
);

// Durable audit trail for every moderation decision. Never deleted.
export const moderationActions = pgTable(
  'moderation_actions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    // Polymorphic reference — targetType indicates which table targetId belongs to.
    targetType: text('target_type').notNull(),
    targetId: uuid('target_id').notNull(),
    // approve / reject / merge / override / flag / etc.
    actionType: text('action_type').notNull(),
    actorUserId: uuid('actor_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    notes: text('notes'),
    // Snapshot of state before/after for audit replay.
    beforeState: jsonb('before_state'),
    afterState: jsonb('after_state'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_moderation_actions_target').on(t.targetType, t.targetId, t.createdAt),
    index('idx_moderation_actions_actor').on(t.actorUserId, t.createdAt),
  ],
);
