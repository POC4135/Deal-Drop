import type { AdminQueueItem, ListingCard, ListingDetail, VenueDetail } from '@dealdrop/shared-types';

type DashboardMetrics = {
  openContributionCount: number;
  openReportCount: number;
  staleListingCount: number;
  highRiskListings: ListingCard[];
};

const apiBaseUrl = process.env.DEALDROP_API_BASE_URL ?? 'http://localhost:3000';

function authHeaders(): HeadersInit {
  if (process.env.DEALDROP_ADMIN_BEARER_TOKEN) {
    return { Authorization: `Bearer ${process.env.DEALDROP_ADMIN_BEARER_TOKEN}` };
  }
  return {
    'x-dev-user-id': 'usr_admin_web',
    'x-dev-email': 'admin@dealdrop.app',
    'x-dev-role': 'admin',
    'x-dev-name': 'Admin Operator',
    'x-dev-verified-contributor': 'true',
  };
}

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    ...init,
    cache: 'no-store',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...authHeaders(),
      ...init?.headers,
    },
  });
  if (response.status === 401 || response.status === 403) {
    throw new Error(`admin_auth_${response.status}`);
  }
  if (!response.ok) {
    throw new Error(`admin_api_${response.status}`);
  }
  if (response.status === 204) {
    return undefined as T;
  }
  return (await response.json()) as T;
}

export const adminApi = {
  dashboard: () => apiFetch<DashboardMetrics>('/v1/admin/dashboard'),
  moderationQueue: () => apiFetch<AdminQueueItem[]>('/v1/admin/queues/moderation'),
  reportsQueue: () => apiFetch<AdminQueueItem[]>('/v1/admin/queues/reports'),
  staleQueue: () => apiFetch<AdminQueueItem[]>('/v1/admin/queues/stale'),
  venues: () => apiFetch<VenueDetail[]>('/v1/admin/venues'),
  listings: () => apiFetch<ListingDetail[]>('/v1/admin/listings'),
  audit: () => apiFetch<Array<{ id: string; type: string; occurredAt: string; aggregateType: string; aggregateId: string }>>('/v1/admin/audit'),
  contributor: (userId: string) =>
    apiFetch<{ profile: { displayName: string }; trustScore: number; recentContributions: Array<{ id: string }> }>(`/v1/admin/contributors/${userId}`),
  createVenue: (body: { name: string; neighborhood: string; address: string; latitude: number; longitude: number }) =>
    apiFetch<VenueDetail>('/v1/admin/venues', { method: 'POST', body: JSON.stringify(body) }),
  createListing: (body: { title: string; venueId: string; neighborhood: string; categoryLabel?: string; scheduleLabel?: string; cuisine?: string; conditions?: string }) =>
    apiFetch<ListingDetail>('/v1/admin/listings', { method: 'POST', body: JSON.stringify(body) }),
};
