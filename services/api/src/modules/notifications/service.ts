import type { NotificationKind } from '@dealdrop/shared-types';

export function notificationTemplate(kind: NotificationKind): string {
  switch (kind) {
    case 'contribution_resolved':
      return 'Your contribution has been reviewed.';
    case 'points_finalized':
      return 'Your pending points were finalized.';
    case 'trust_status_changed':
      return 'A listing trust state changed.';
    case 'listing_reported_stale':
      return 'A saved listing may need recheck.';
    case 'moderation_update':
      return 'A moderator action changed one of your submissions.';
  }
}
