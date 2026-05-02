import { pgEnum } from 'drizzle-orm/pg-core';

// ─── Identity ────────────────────────────────────────────────────────────────

export const userRoleEnum = pgEnum('user_role', ['user', 'moderator', 'admin']);

export const accountStatusEnum = pgEnum('account_status', [
  'active',
  'suspended',
  'deleted',
]);

export const platformTypeEnum = pgEnum('platform_type', [
  'ios',
  'android',
  'web',
  'unknown',
]);

// ─── Listings ─────────────────────────────────────────────────────────────────

export const listingStatusEnum = pgEnum('listing_status', [
  'draft',
  'active',
  'archived',
  'soft_deleted',
]);

export const sourceTypeEnum = pgEnum('source_type', [
  'founder_entered',
  'public_capture',
  'user_submitted',
  'merchant_submitted',
  'admin_corrected',
]);

export const listingCategoryEnum = pgEnum('listing_category', [
  'cheap_eats',
  'food_deal',
  'drink_deal',
  'student_offer',
  'special',
  'happy_hour',
]);

export const trustBandEnum = pgEnum('trust_band', [
  'founder_verified',
  'merchant_confirmed',
  'user_confirmed',
  'recently_updated',
  'needs_recheck',
  'disputed',
]);

// ─── Contributions ────────────────────────────────────────────────────────────

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

export const proofStatusEnum = pgEnum('proof_status', [
  'pending_upload',
  'uploaded',
  'validated',
  'rejected',
]);

// ─── Gamification ─────────────────────────────────────────────────────────────

export const pointsStateEnum = pgEnum('points_state', [
  'pending',
  'finalized',
  'reversed',
]);

export const karmaEventTypeEnum = pgEnum('karma_event_type', [
  'contribution_submitted',
  'contribution_approved',
  'contribution_rejected',
  'confirmation_recorded',
  'report_recorded',
  'bonus_awarded',
  'reversal',
  'admin_adjustment',
]);

export const leaderboardWindowEnum = pgEnum('leaderboard_window', [
  'daily',
  'weekly',
  'all_time',
]);

// ─── Notifications ────────────────────────────────────────────────────────────

export const notificationKindEnum = pgEnum('notification_kind', [
  'contribution_resolved',
  'points_finalized',
  'trust_status_changed',
  'listing_reported_stale',
  'moderation_update',
]);

export const notificationDeliveryStatusEnum = pgEnum(
  'notification_delivery_status',
  ['queued', 'sent', 'delivered', 'failed', 'suppressed'],
);

// ─── Audit / Ops ──────────────────────────────────────────────────────────────

export const auditEntityTypeEnum = pgEnum('audit_entity_type', [
  'user',
  'venue',
  'listing',
  'contribution',
  'notification',
  'device',
  'trust_snapshot',
  'karma_event',
]);

export const outboxStatusEnum = pgEnum('outbox_status', [
  'pending',
  'published',
  'failed',
]);
