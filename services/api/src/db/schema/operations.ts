import {
  index,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { auditEntityTypeEnum, outboxStatusEnum } from './enums';
import { users } from './identity';

// Write-endpoint replay protection. Every mutable endpoint that is
// exposed to mobile retries must consume/store a key here before
// performing side effects. Keys expire after a configurable TTL.
export const idempotencyKeys = pgTable(
  'idempotency_keys',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    // Client-generated key (UUID v4 recommended).
    key: text('key').unique().notNull(),
    // Endpoint or workflow scope (e.g. "contributions.create").
    scope: text('scope').notNull(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
    // Hash of the full request body for mismatch detection.
    requestHash: text('request_hash').notNull(),
    // Hash of the response body stored after first successful execution.
    responseHash: text('response_hash'),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_idempotency_keys_scope_expires').on(t.scope, t.expiresAt),
  ],
);

// Privileged action log. Written by the API layer on every admin/moderator
// action and sensitive mutation. Never deleted.
export const auditLogs = pgTable(
  'audit_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    // Null for system-initiated actions.
    actorUserId: uuid('actor_user_id').references(() => users.id, {
      onDelete: 'set null',
    }),
    entityType: auditEntityTypeEnum('entity_type').notNull(),
    entityId: uuid('entity_id').notNull(),
    // create / update / delete / approve / reject / override / etc.
    actionType: text('action_type').notNull(),
    metadata: jsonb('metadata'),
    // Propagated from the inbound HTTP request for cross-service tracing.
    requestId: text('request_id'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_audit_logs_entity').on(t.entityType, t.entityId, t.createdAt),
    index('idx_audit_logs_actor').on(t.actorUserId, t.createdAt),
  ],
);

// Transactional outbox for reliable async worker handoff.
// Written in the same DB transaction as the business state change,
// then relayed to EventBridge/SQS by the outbox-relay process.
// Immutable once published.
export const outboxEvents = pgTable(
  'outbox_events',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    // listing / contribution / user / confirmation / report / etc.
    aggregateType: text('aggregate_type').notNull(),
    aggregateId: uuid('aggregate_id').notNull(),
    // trust.updated / contribution.approved / confirmation.recorded / etc.
    eventType: text('event_type').notNull(),
    payload: jsonb('payload').notNull(),
    status: outboxStatusEnum('status').default('pending').notNull(),
    publishedAt: timestamp('published_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    // Relay polls this index for pending events ordered by creation time.
    index('idx_outbox_events_status_created').on(t.status, t.createdAt),
    index('idx_outbox_events_aggregate').on(
      t.aggregateType,
      t.aggregateId,
      t.createdAt,
    ),
  ],
);
