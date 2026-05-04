import { z } from 'zod';

export const roleSchema = z.enum(['user', 'moderator', 'admin']);
export type Role = z.infer<typeof roleSchema>;

export const trustBandSchema = z.enum([
  'founder_verified',
  'merchant_confirmed',
  'user_confirmed',
  'recently_updated',
  'needs_recheck',
  'disputed',
]);
export type TrustBand = z.infer<typeof trustBandSchema>;

export const visibilityStateSchema = z.enum(['visible', 'shadow_hidden', 'suppressed']);
export type VisibilityState = z.infer<typeof visibilityStateSchema>;

export const contributionStatusSchema = z.enum([
  'submitted',
  'needs_proof',
  'under_review',
  'approved',
  'rejected',
  'merged',
]);
export type ContributionStatus = z.infer<typeof contributionStatusSchema>;

export const moderationDecisionSchema = z.enum([
  'approve',
  'reject',
  'request_proof',
  'merge_duplicate',
  'snooze',
]);
export type ModerationDecision = z.infer<typeof moderationDecisionSchema>;

export const leaderboardWindowSchema = z.enum(['daily', 'weekly', 'all_time']);
export type LeaderboardWindow = z.infer<typeof leaderboardWindowSchema>;

export const notificationKindSchema = z.enum([
  'contribution_resolved',
  'points_finalized',
  'trust_status_changed',
  'listing_reported_stale',
  'moderation_update',
]);
export type NotificationKind = z.infer<typeof notificationKindSchema>;

export const geoPointSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
});
export type GeoPoint = z.infer<typeof geoPointSchema>;

export const listingOfferSchema = z.object({
  id: z.string(),
  title: z.string(),
  originalPrice: z.number(),
  dealPrice: z.number(),
  currency: z.string().default('USD'),
});
export type ListingOffer = z.infer<typeof listingOfferSchema>;

export const trustSummarySchema = z.object({
  band: trustBandSchema,
  explanation: z.string(),
  confidenceScore: z.number(),
  freshUntilAt: z.string().datetime(),
  recheckAfterAt: z.string().datetime(),
  proofCount: z.number(),
  recentConfirmations: z.number(),
  disputeCount: z.number(),
});
export type TrustSummary = z.infer<typeof trustSummarySchema>;

export const listingCardSchema = z.object({
  id: z.string(),
  venueId: z.string(),
  venueName: z.string(),
  title: z.string(),
  neighborhood: z.string(),
  categoryLabel: z.string(),
  scheduleLabel: z.string(),
  trustBand: trustBandSchema,
  freshnessText: z.string(),
  valueNote: z.string(),
  affordabilityLabel: z.string().default('Under $15'),
  distanceMiles: z.number(),
  rating: z.number(),
  cuisine: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  confidenceScore: z.number().default(0.5),
  lastUpdatedAt: z.string().datetime().nullable().default(null),
  tags: z.array(z.string()),
  saved: z.boolean().default(false),
});
export type ListingCard = z.infer<typeof listingCardSchema>;

export const listingDetailSchema = listingCardSchema.extend({
  venueAddress: z.string(),
  description: z.string(),
  conditions: z.string(),
  sourceNote: z.string(),
  offers: z.array(listingOfferSchema),
  freshUntilAt: z.string().datetime(),
  recheckAfterAt: z.string().datetime(),
  proofCount: z.number(),
  trustSummary: trustSummarySchema,
});
export type ListingDetail = z.infer<typeof listingDetailSchema>;

export const venueDetailSchema = z.object({
  id: z.string(),
  name: z.string(),
  neighborhood: z.string(),
  address: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  rating: z.number(),
  listingIds: z.array(z.string()),
  tags: z.array(z.string()),
  activeListingCount: z.number(),
});
export type VenueDetail = z.infer<typeof venueDetailSchema>;

export const mapListingSchema = z.object({
  listingId: z.string(),
  venueId: z.string(),
  venueName: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  trustBand: trustBandSchema,
  title: z.string(),
  neighborhood: z.string(),
  confidenceScore: z.number(),
  affordabilityLabel: z.string().default('Under $15'),
  saved: z.boolean().default(false),
});
export type MapListing = z.infer<typeof mapListingSchema>;

export const paginationCursorSchema = z.object({
  nextCursor: z.string().nullable(),
});
export type PaginationCursor = z.infer<typeof paginationCursorSchema>;

export const confidenceSnapshotSchema = z.object({
  listingId: z.string(),
  score: z.number(),
  trustBand: trustBandSchema,
  visibilityState: visibilityStateSchema,
  freshUntilAt: z.string().datetime(),
  recheckAfterAt: z.string().datetime(),
  recentConfirmations: z.number(),
  negativeSignals: z.number(),
});
export type ConfidenceSnapshot = z.infer<typeof confidenceSnapshotSchema>;

export const pointsLedgerEntrySchema = z.object({
  id: z.string(),
  userId: z.string(),
  reason: z.string(),
  pointsDelta: z.number(),
  status: z.enum(['pending', 'finalized', 'reversed']),
  createdAt: z.string().datetime(),
});
export type PointsLedgerEntry = z.infer<typeof pointsLedgerEntrySchema>;

export const leaderboardEntrySchema = z.object({
  rank: z.number(),
  userId: z.string(),
  displayName: z.string(),
  title: z.string(),
  points: z.number(),
  verifiedContributor: z.boolean(),
});
export type LeaderboardEntry = z.infer<typeof leaderboardEntrySchema>;

export const karmaBadgeSchema = z.object({
  code: z.string(),
  title: z.string(),
  description: z.string(),
  unlocked: z.boolean(),
});
export type KarmaBadge = z.infer<typeof karmaBadgeSchema>;

export const karmaSummarySchema = z.object({
  userId: z.string(),
  points: z.number(),
  pendingPoints: z.number(),
  verifiedContributor: z.boolean(),
  currentStreakDays: z.number(),
  level: z.string(),
  nextLevelPoints: z.number().default(0),
  impactUsersHelped: z.number().default(0),
  approvedContributions: z.number().default(0),
  pendingContributions: z.number().default(0),
  badges: z.array(karmaBadgeSchema),
  leaderboardWindow: leaderboardWindowSchema,
  leaderboard: z.array(leaderboardEntrySchema),
});
export type KarmaSummary = z.infer<typeof karmaSummarySchema>;

export const adminQueueItemSchema = z.object({
  id: z.string(),
  entityId: z.string(),
  type: z.enum(['contribution', 'report', 'stale_listing']),
  title: z.string(),
  subtitle: z.string(),
  neighborhood: z.string(),
  trustBand: trustBandSchema.optional(),
  createdAt: z.string().datetime(),
  priority: z.enum(['low', 'medium', 'high']),
  status: z.string(),
});
export type AdminQueueItem = z.infer<typeof adminQueueItemSchema>;

export const profileSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  displayName: z.string(),
  homeNeighborhood: z.string(),
  role: roleSchema,
  verifiedContributor: z.boolean(),
});
export type Profile = z.infer<typeof profileSchema>;

export const searchResultSchema = z.object({
  listings: z.array(listingCardSchema),
  venues: z.array(venueDetailSchema),
  neighborhoods: z.array(z.string()),
  suggestions: z.array(z.string()).default([]),
  nextCursor: z.string().nullable(),
});
export type SearchResult = z.infer<typeof searchResultSchema>;

export const feedSectionSchema = z.object({
  id: z.string(),
  title: z.string(),
  subtitle: z.string(),
  items: z.array(listingCardSchema),
});
export type FeedSection = z.infer<typeof feedSectionSchema>;

export const feedResponseSchema = z.object({
  sections: z.array(feedSectionSchema),
  nextCursor: z.string().nullable(),
});
export type FeedResponse = z.infer<typeof feedResponseSchema>;

export const filtersMetadataSchema = z.object({
  neighborhoods: z.array(z.string()),
  tags: z.array(z.string()),
  cuisines: z.array(z.string()),
  trustBands: z.array(trustBandSchema),
});
export type FiltersMetadata = z.infer<typeof filtersMetadataSchema>;

export const contributionCreateSchema = z.object({
  venueName: z.string(),
  neighborhood: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  title: z.string(),
  description: z.string(),
  conditions: z.string(),
  scheduleSummary: z.string(),
  tags: z.array(z.string()).default([]),
  proofAssetKeys: z.array(z.string()).default([]),
});
export type ContributionCreate = z.infer<typeof contributionCreateSchema>;

export const contributionUpdateSchema = z.object({
  listingId: z.string(),
  title: z.string().optional(),
  description: z.string().optional(),
  conditions: z.string().optional(),
  scheduleSummary: z.string().optional(),
  proofAssetKeys: z.array(z.string()).default([]),
});
export type ContributionUpdate = z.infer<typeof contributionUpdateSchema>;

export const contributionRecordSchema = z.object({
  id: z.string(),
  listingId: z.string(),
  listingTitle: z.string(),
  venueName: z.string(),
  neighborhood: z.string(),
  type: z.enum(['new_listing', 'listing_update', 'confirm_valid', 'report_expired']),
  status: contributionStatusSchema,
  createdAt: z.string().datetime(),
  summary: z.string(),
  pointsDelta: z.number().default(0),
  pointsStatus: z.enum(['pending', 'finalized', 'reversed']).default('pending'),
});
export type ContributionRecord = z.infer<typeof contributionRecordSchema>;

export const contributionHistoryResponseSchema = z.object({
  items: z.array(contributionRecordSchema),
});
export type ContributionHistoryResponse = z.infer<typeof contributionHistoryResponseSchema>;

export const reportExpiredSchema = z.object({
  reason: z.string(),
  notes: z.string().optional(),
});
export type ReportExpired = z.infer<typeof reportExpiredSchema>;

export const notificationRecordSchema = z.object({
  id: z.string(),
  kind: notificationKindSchema,
  title: z.string(),
  body: z.string(),
  createdAt: z.string().datetime(),
  readAt: z.string().datetime().nullable().default(null),
  deepLink: z.string().nullable().default(null),
});
export type NotificationRecord = z.infer<typeof notificationRecordSchema>;

export const notificationsResponseSchema = z.object({
  items: z.array(notificationRecordSchema),
  unreadCount: z.number(),
});
export type NotificationsResponse = z.infer<typeof notificationsResponseSchema>;

export const userPreferencesSchema = z.object({
  contributionResolved: z.boolean().default(true),
  pointsFinalized: z.boolean().default(true),
  trustStatusChanged: z.boolean().default(true),
  marketingAnnouncements: z.boolean().default(false),
});
export type UserPreferences = z.infer<typeof userPreferencesSchema>;

export const deviceRegistrationSchema = z.object({
  deviceId: z.string(),
  platform: z.enum(['ios', 'android', 'web', 'macos', 'windows', 'linux']),
  pushToken: z.string().nullable().default(null),
  locale: z.string().default('en-US'),
  notificationsEnabled: z.boolean().default(true),
});
export type DeviceRegistration = z.infer<typeof deviceRegistrationSchema>;

export const telemetryEventSchema = z.object({
  name: z.string(),
  screen: z.string().optional(),
  happenedAt: z.string().datetime(),
  properties: z.record(z.any()).default({}),
});
export type TelemetryEvent = z.infer<typeof telemetryEventSchema>;

export const authSessionSchema = z.object({
  userId: z.string(),
  email: z.string().email(),
  displayName: z.string(),
  role: roleSchema,
  verifiedContributor: z.boolean(),
});
export type AuthSession = z.infer<typeof authSessionSchema>;

export const authBootstrapSchema = z.object({
  displayName: z.string().min(2).optional(),
  homeNeighborhood: z.string().default('Midtown'),
});
export type AuthBootstrap = z.infer<typeof authBootstrapSchema>;

export const authResponseSchema = z.object({
  session: authSessionSchema,
  profile: profileSchema,
});
export type AuthResponse = z.infer<typeof authResponseSchema>;

export const verificationEventSchema = z.object({
  listingId: z.string(),
  happenedAt: z.string().datetime(),
  sourceType: z.enum(['founder', 'merchant', 'user', 'moderator']),
  weight: z.number(),
  proofProvided: z.boolean(),
});
export type VerificationEvent = z.infer<typeof verificationEventSchema>;

export const domainEventSchema = z.object({
  id: z.string(),
  type: z.string(),
  occurredAt: z.string().datetime(),
  aggregateType: z.string(),
  aggregateId: z.string(),
  payload: z.record(z.any()),
});
export type DomainEvent = z.infer<typeof domainEventSchema>;
