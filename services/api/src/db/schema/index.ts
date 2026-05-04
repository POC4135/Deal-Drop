import {
  boolean,
  customType,
  doublePrecision,
  index,
  integer,
  jsonb,
  pgEnum,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  varchar,
} from 'drizzle-orm/pg-core';

const geographyPoint = customType<{ data: string }>({
  dataType() {
    return 'geography(Point,4326)';
  },
});

export const roleEnum = pgEnum('role', ['user', 'moderator', 'admin']);
export const listingStatusEnum = pgEnum('listing_status', ['draft', 'active', 'stale', 'suppressed', 'archived']);
export const trustBandEnum = pgEnum('trust_band', [
  'founder_verified',
  'merchant_confirmed',
  'user_confirmed',
  'recently_updated',
  'needs_recheck',
  'disputed',
]);
export const visibilityStateEnum = pgEnum('visibility_state', ['visible', 'shadow_hidden', 'suppressed']);
export const contributionTypeEnum = pgEnum('contribution_type', [
  'new_listing',
  'listing_update',
  'confirm_valid',
  'report_expired',
]);
export const contributionStatusEnum = pgEnum('contribution_status', [
  'submitted',
  'needs_proof',
  'under_review',
  'approved',
  'rejected',
  'merged',
]);
export const moderationDecisionEnum = pgEnum('moderation_decision', [
  'approve',
  'reject',
  'request_proof',
  'merge_duplicate',
  'snooze',
]);
export const reportStatusEnum = pgEnum('report_status', ['open', 'resolved']);
export const ledgerStatusEnum = pgEnum('ledger_status', ['pending', 'finalized', 'reversed']);
export const leaderboardWindowEnum = pgEnum('leaderboard_window', ['daily', 'weekly', 'all_time']);
export const outboxStatusEnum = pgEnum('outbox_status', ['pending', 'published', 'failed']);
export const platformTypeEnum = pgEnum('platform_type', ['ios', 'android', 'web', 'unknown']);
export const notificationKindEnum = pgEnum('notification_kind', [
  'contribution_resolved',
  'points_finalized',
  'trust_status_changed',
  'listing_reported_stale',
  'moderation_update',
]);
export const notificationDeliveryStatusEnum = pgEnum('notification_delivery_status', [
  'queued',
  'sent',
  'delivered',
  'failed',
  'suppressed',
]);

export const users = pgTable(
  'users',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    email: varchar('email', { length: 255 }).notNull(),
    role: roleEnum('role').notNull().default('user'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    emailIdx: uniqueIndex('users_email_idx').on(table.email),
    roleIdx: index('users_role_idx').on(table.role),
  }),
);

export const userProfiles = pgTable('user_profiles', {
  userId: varchar('user_id', { length: 64 })
    .primaryKey()
    .references(() => users.id),
  displayName: varchar('display_name', { length: 120 }).notNull(),
  homeNeighborhood: varchar('home_neighborhood', { length: 120 }).notNull(),
  contributorTrustScore: doublePrecision('contributor_trust_score').notNull().default(0.5),
  verifiedContributor: boolean('verified_contributor').notNull().default(false),
  currentLevel: varchar('current_level', { length: 120 }).notNull().default('Newcomer'),
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const deviceSessions = pgTable(
  'device_sessions',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    userId: varchar('user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    platform: varchar('platform', { length: 32 }).notNull(),
    deviceLabel: varchar('device_label', { length: 128 }).notNull(),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull().defaultNow(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    sessionUserIdx: index('device_sessions_user_idx').on(table.userId, table.lastSeenAt),
  }),
);

export const venues = pgTable(
  'venues',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    slug: varchar('slug', { length: 160 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    rating: doublePrecision('rating').notNull().default(0),
    status: listingStatusEnum('status').notNull().default('active'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    archivedAt: timestamp('archived_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    venueSlugIdx: uniqueIndex('venues_slug_idx').on(table.slug),
    venueActiveIdx: index('venues_active_idx').on(table.status, table.updatedAt),
  }),
);

export const venueLocations = pgTable(
  'venue_locations',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    venueId: varchar('venue_id', { length: 64 })
      .notNull()
      .references(() => venues.id),
    neighborhoodName: varchar('neighborhood_name', { length: 120 }).notNull(),
    neighborhoodSlug: varchar('neighborhood_slug', { length: 120 }).notNull(),
    address: text('address').notNull(),
    latitude: doublePrecision('latitude').notNull(),
    longitude: doublePrecision('longitude').notNull(),
    point: geographyPoint('point').notNull(),
    verificationGeofenceRadiusMeters: integer('verification_geofence_radius_meters').notNull().default(120),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    venueLocationVenueIdx: uniqueIndex('venue_locations_venue_idx').on(table.venueId),
    venueLocationNeighborhoodIdx: index('venue_locations_neighborhood_idx').on(table.neighborhoodSlug, table.venueId),
  }),
);

export const listings = pgTable(
  'listings',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    venueId: varchar('venue_id', { length: 64 })
      .notNull()
      .references(() => venues.id),
    slug: varchar('slug', { length: 160 }).notNull(),
    title: varchar('title', { length: 255 }).notNull(),
    description: text('description').notNull(),
    categoryLabel: varchar('category_label', { length: 120 }).notNull(),
    scheduleSummary: varchar('schedule_summary', { length: 160 }).notNull(),
    conditions: text('conditions').notNull(),
    sourceNote: text('source_note').notNull(),
    cuisine: varchar('cuisine', { length: 120 }).notNull(),
    status: listingStatusEnum('status').notNull().default('draft'),
    trustBand: trustBandEnum('trust_band').notNull().default('recently_updated'),
    visibilityState: visibilityStateEnum('visibility_state').notNull().default('visible'),
    confidenceScore: doublePrecision('confidence_score').notNull().default(0.5),
    freshUntilAt: timestamp('fresh_until_at', { withTimezone: true }),
    recheckAfterAt: timestamp('recheck_after_at', { withTimezone: true }),
    publishedAt: timestamp('published_at', { withTimezone: true }),
    lastVerifiedAt: timestamp('last_verified_at', { withTimezone: true }),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    archivedAt: timestamp('archived_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    listingSlugIdx: uniqueIndex('listings_slug_idx').on(table.slug),
    listingFeedIdx: index('listings_feed_idx').on(table.status, table.trustBand, table.confidenceScore, table.updatedAt),
    listingVenueIdx: index('listings_venue_idx').on(table.venueId, table.status),
  }),
);

export const listingSchedules = pgTable(
  'listing_schedules',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    listingId: varchar('listing_id', { length: 64 })
      .notNull()
      .references(() => listings.id),
    dayOfWeek: integer('day_of_week').notNull(),
    startTimeLocal: varchar('start_time_local', { length: 16 }).notNull(),
    endTimeLocal: varchar('end_time_local', { length: 16 }).notNull(),
    timezone: varchar('timezone', { length: 64 }).notNull().default('America/New_York'),
    specialLabel: varchar('special_label', { length: 120 }),
  },
  (table) => ({
    listingScheduleIdx: index('listing_schedules_idx').on(table.listingId, table.dayOfWeek, table.startTimeLocal),
  }),
);

export const listingTags = pgTable(
  'listing_tags',
  {
    listingId: varchar('listing_id', { length: 64 })
      .notNull()
      .references(() => listings.id),
    tag: varchar('tag', { length: 120 }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.listingId, table.tag], name: 'listing_tags_pk' }),
    listingTagIdx: index('listing_tags_tag_idx').on(table.tag, table.listingId),
  }),
);

export const favorites = pgTable(
  'favorites',
  {
    userId: varchar('user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    listingId: varchar('listing_id', { length: 64 })
      .notNull()
      .references(() => listings.id),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.userId, table.listingId], name: 'favorites_pk' }),
    favoritesListingIdx: index('favorites_listing_idx').on(table.listingId, table.createdAt),
  }),
);

export const contributions = pgTable(
  'contributions',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    listingId: varchar('listing_id', { length: 64 }).references(() => listings.id),
    userId: varchar('user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    type: contributionTypeEnum('type').notNull(),
    status: contributionStatusEnum('status').notNull().default('submitted'),
    title: varchar('title', { length: 255 }),
    description: text('description'),
    scheduleSummary: varchar('schedule_summary', { length: 160 }),
    neighborhood: varchar('neighborhood', { length: 120 }),
    latitude: doublePrecision('latitude'),
    longitude: doublePrecision('longitude'),
    payload: jsonb('payload').notNull().default({}),
    duplicateOfListingId: varchar('duplicate_of_listing_id', { length: 64 }),
    idempotencyKey: varchar('idempotency_key', { length: 160 }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    contributionStatusIdx: index('contributions_status_idx').on(table.status, table.createdAt),
    contributionUserIdx: index('contributions_user_idx').on(table.userId, table.createdAt),
    contributionIdempotencyIdx: uniqueIndex('contributions_idempotency_idx').on(table.idempotencyKey),
  }),
);

export const contributionProofs = pgTable(
  'contribution_proofs',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    contributionId: varchar('contribution_id', { length: 64 })
      .notNull()
      .references(() => contributions.id),
    assetKey: text('asset_key').notNull(),
    contentType: varchar('content_type', { length: 120 }).notNull(),
    uploadedAt: timestamp('uploaded_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    contributionProofIdx: index('contribution_proofs_idx').on(table.contributionId, table.uploadedAt),
  }),
);

export const reports = pgTable(
  'reports',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    listingId: varchar('listing_id', { length: 64 })
      .notNull()
      .references(() => listings.id),
    userId: varchar('user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    reason: varchar('reason', { length: 120 }).notNull(),
    notes: text('notes'),
    status: reportStatusEnum('status').notNull().default('open'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    resolvedAt: timestamp('resolved_at', { withTimezone: true }),
  },
  (table) => ({
    reportStatusIdx: index('reports_status_idx').on(table.status, table.createdAt),
  }),
);

export const moderationActions = pgTable(
  'moderation_actions',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    contributionId: varchar('contribution_id', { length: 64 }).references(() => contributions.id),
    reportId: varchar('report_id', { length: 64 }).references(() => reports.id),
    moderatorUserId: varchar('moderator_user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    decision: moderationDecisionEnum('decision').notNull(),
    notes: text('notes'),
    mergedIntoListingId: varchar('merged_into_listing_id', { length: 64 }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    moderationActionIdx: index('moderation_actions_idx').on(table.moderatorUserId, table.createdAt),
  }),
);

export const verificationEvents = pgTable('verification_events', {
  id: varchar('id', { length: 64 }).primaryKey(),
  listingId: varchar('listing_id', { length: 64 })
    .notNull()
    .references(() => listings.id),
  userId: varchar('user_id', { length: 64 }).references(() => users.id),
  sourceType: varchar('source_type', { length: 32 }).notNull(),
  weight: doublePrecision('weight').notNull().default(1),
  proofProvided: boolean('proof_provided').notNull().default(false),
  metadata: jsonb('metadata').notNull().default({}),
  happenedAt: timestamp('happened_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const trustSignals = pgTable('trust_signals', {
  id: varchar('id', { length: 64 }).primaryKey(),
  listingId: varchar('listing_id', { length: 64 })
    .notNull()
    .references(() => listings.id),
  signalType: varchar('signal_type', { length: 64 }).notNull(),
  signalWeight: doublePrecision('signal_weight').notNull(),
  sourceContributionId: varchar('source_contribution_id', { length: 64 }).references(() => contributions.id),
  sourceReportId: varchar('source_report_id', { length: 64 }).references(() => reports.id),
  metadata: jsonb('metadata').notNull().default({}),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const confidenceSnapshots = pgTable(
  'confidence_snapshots',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    listingId: varchar('listing_id', { length: 64 })
      .notNull()
      .references(() => listings.id),
    score: doublePrecision('score').notNull(),
    trustBand: trustBandEnum('trust_band').notNull(),
    visibilityState: visibilityStateEnum('visibility_state').notNull(),
    recentConfirmations: integer('recent_confirmations').notNull().default(0),
    negativeSignals: integer('negative_signals').notNull().default(0),
    freshUntilAt: timestamp('fresh_until_at', { withTimezone: true }).notNull(),
    recheckAfterAt: timestamp('recheck_after_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    confidenceSnapshotIdx: index('confidence_snapshots_listing_idx').on(table.listingId, table.createdAt),
  }),
);

export const pointsLedger = pgTable('points_ledger', {
  id: varchar('id', { length: 64 }).primaryKey(),
  userId: varchar('user_id', { length: 64 })
    .notNull()
    .references(() => users.id),
  reason: varchar('reason', { length: 120 }).notNull(),
  status: ledgerStatusEnum('status').notNull(),
  pointsDelta: integer('points_delta').notNull(),
  contributionId: varchar('contribution_id', { length: 64 }).references(() => contributions.id),
  verificationEventId: varchar('verification_event_id', { length: 64 }),
  metadata: jsonb('metadata').notNull().default({}),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const streaks = pgTable('streaks', {
  userId: varchar('user_id', { length: 64 })
    .primaryKey()
    .references(() => users.id),
  currentStreakDays: integer('current_streak_days').notNull().default(0),
  longestStreakDays: integer('longest_streak_days').notNull().default(0),
  lastQualifiedDate: timestamp('last_qualified_date', { withTimezone: true }),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const badges = pgTable('badges', {
  id: varchar('id', { length: 64 }).primaryKey(),
  code: varchar('code', { length: 120 }).notNull(),
  title: varchar('title', { length: 120 }).notNull(),
  description: text('description').notNull(),
  minPoints: integer('min_points').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const leaderboardSnapshots = pgTable(
  'leaderboard_snapshots',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    window: leaderboardWindowEnum('window').notNull(),
    snapshotDate: timestamp('snapshot_date', { withTimezone: true }).notNull(),
    userId: varchar('user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    rank: integer('rank').notNull(),
    points: integer('points').notNull(),
    levelTitle: varchar('level_title', { length: 120 }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    leaderboardIdx: index('leaderboard_snapshots_idx').on(table.window, table.snapshotDate, table.rank),
  }),
);

export const notificationPreferences = pgTable('notification_preferences', {
  userId: varchar('user_id', { length: 64 })
    .primaryKey()
    .references(() => users.id),
  contributionResolved: boolean('contribution_resolved').notNull().default(true),
  pointsFinalized: boolean('points_finalized').notNull().default(true),
  trustStatusChanged: boolean('trust_status_changed').notNull().default(true),
  marketingAnnouncements: boolean('marketing_announcements').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const notifications = pgTable(
  'notifications',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    userId: varchar('user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    kind: notificationKindEnum('kind').notNull(),
    title: text('title').notNull(),
    body: text('body').notNull(),
    referenceType: varchar('reference_type', { length: 64 }),
    referenceId: varchar('reference_id', { length: 64 }),
    deepLink: text('deep_link'),
    metadata: jsonb('metadata').notNull().default({}),
    readAt: timestamp('read_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    notificationsUserCreatedIdx: index('notifications_user_created_idx').on(table.userId, table.createdAt),
    notificationsUserReadIdx: index('notifications_user_read_idx').on(table.userId, table.readAt),
  }),
);

export const deviceRegistrations = pgTable(
  'device_registrations',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    userId: varchar('user_id', { length: 64 })
      .notNull()
      .references(() => users.id),
    platform: platformTypeEnum('platform').notNull(),
    deviceIdentifier: varchar('device_identifier', { length: 160 }).notNull(),
    pushToken: text('push_token').notNull(),
    appVersion: varchar('app_version', { length: 64 }),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull().defaultNow(),
    disabledAt: timestamp('disabled_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    deviceRegistrationsUserDeviceIdx: uniqueIndex('device_registrations_user_device_idx').on(
      table.userId,
      table.deviceIdentifier,
    ),
    deviceRegistrationsUserDisabledIdx: index('device_registrations_user_disabled_idx').on(
      table.userId,
      table.disabledAt,
    ),
  }),
);

export const notificationDeliveries = pgTable(
  'notification_deliveries',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    notificationId: varchar('notification_id', { length: 64 })
      .notNull()
      .references(() => notifications.id),
    deviceId: varchar('device_id', { length: 64 })
      .notNull()
      .references(() => deviceRegistrations.id),
    channel: varchar('channel', { length: 64 }).notNull(),
    status: notificationDeliveryStatusEnum('status').notNull().default('queued'),
    providerMessageId: varchar('provider_message_id', { length: 255 }),
    attemptedAt: timestamp('attempted_at', { withTimezone: true }),
    deliveredAt: timestamp('delivered_at', { withTimezone: true }),
    failedAt: timestamp('failed_at', { withTimezone: true }),
    failureReason: text('failure_reason'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    notificationDeliveriesNotificationIdx: index('notification_deliveries_notification_idx').on(table.notificationId),
    notificationDeliveriesDeviceIdx: index('notification_deliveries_device_idx').on(table.deviceId),
    notificationDeliveriesStatusIdx: index('notification_deliveries_status_idx').on(table.status, table.createdAt),
  }),
);

export const telemetryEvents = pgTable(
  'telemetry_events',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    userId: varchar('user_id', { length: 64 }).references(() => users.id),
    deviceId: varchar('device_id', { length: 64 }).references(() => deviceRegistrations.id),
    sessionId: varchar('session_id', { length: 160 }),
    eventName: varchar('event_name', { length: 160 }).notNull(),
    eventPayload: jsonb('event_payload').notNull().default({}),
    appVersion: varchar('app_version', { length: 64 }),
    platform: platformTypeEnum('platform'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    telemetryEventsCreatedIdx: index('telemetry_events_created_idx').on(table.createdAt),
    telemetryEventsNameCreatedIdx: index('telemetry_events_name_created_idx').on(table.eventName, table.createdAt),
    telemetryEventsUserCreatedIdx: index('telemetry_events_user_created_idx').on(table.userId, table.createdAt),
  }),
);

export const auditLogs = pgTable('audit_logs', {
  id: varchar('id', { length: 64 }).primaryKey(),
  actorUserId: varchar('actor_user_id', { length: 64 })
    .notNull()
    .references(() => users.id),
  action: varchar('action', { length: 160 }).notNull(),
  entityType: varchar('entity_type', { length: 64 }).notNull(),
  entityId: varchar('entity_id', { length: 64 }).notNull(),
  requestId: varchar('request_id', { length: 120 }).notNull(),
  metadata: jsonb('metadata').notNull().default({}),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const outboxEvents = pgTable(
  'outbox_events',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    eventType: varchar('event_type', { length: 160 }).notNull(),
    aggregateType: varchar('aggregate_type', { length: 64 }).notNull(),
    aggregateId: varchar('aggregate_id', { length: 64 }).notNull(),
    payload: jsonb('payload').notNull(),
    status: outboxStatusEnum('status').notNull().default('pending'),
    idempotencyKey: varchar('idempotency_key', { length: 160 }).notNull(),
    attempts: integer('attempts').notNull().default(0),
    occurredAt: timestamp('occurred_at', { withTimezone: true }).notNull(),
    publishedAt: timestamp('published_at', { withTimezone: true }),
  },
  (table) => ({
    outboxStatusIdx: index('outbox_pending_idx').on(table.status, table.occurredAt),
    outboxIdempotencyIdx: uniqueIndex('outbox_idempotency_idx').on(table.idempotencyKey),
  }),
);

export const idempotencyKeys = pgTable('idempotency_keys', {
  idempotencyKey: varchar('idempotency_key', { length: 160 }).primaryKey(),
  scope: varchar('scope', { length: 120 }).notNull(),
  requestHash: varchar('request_hash', { length: 160 }).notNull(),
  responseBody: jsonb('response_body'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

export const searchDocuments = pgTable(
  'search_documents',
  {
    id: varchar('id', { length: 64 }).primaryKey(),
    listingId: varchar('listing_id', { length: 64 })
      .notNull()
      .references(() => listings.id),
    venueId: varchar('venue_id', { length: 64 })
      .notNull()
      .references(() => venues.id),
    neighborhoodSlug: varchar('neighborhood_slug', { length: 120 }).notNull(),
    title: text('title').notNull(),
    body: text('body').notNull(),
    searchVector: text('search_vector').notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    searchListingIdx: uniqueIndex('search_documents_listing_idx').on(table.listingId),
    searchNeighborhoodIdx: index('search_documents_neighborhood_idx').on(table.neighborhoodSlug, table.updatedAt),
  }),
);
