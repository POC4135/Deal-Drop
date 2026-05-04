import type { AdminQueueItem, ListingDetail, Profile, VenueDetail } from '@dealdrop/shared-types';

const trustSummaryFor = (listing: {
  trustBand: ListingDetail['trustBand'];
  confidenceScore: number;
  freshUntilAt: string;
  recheckAfterAt: string;
  proofCount: number;
}): ListingDetail['trustSummary'] => ({
  band: listing.trustBand,
  explanation: 'Admin fixture trust summary.',
  confidenceScore: listing.confidenceScore,
  freshUntilAt: listing.freshUntilAt,
  recheckAfterAt: listing.recheckAfterAt,
  proofCount: listing.proofCount,
  recentConfirmations: listing.proofCount,
  disputeCount: listing.trustBand === 'needs_recheck' ? 1 : 0,
});

export const dashboardMetrics = [
  { label: 'Submission queue', value: '28 pending', note: '4 duplicate merge reviews waiting', tone: 'accent' },
  { label: 'Issue reports', value: '11 open', note: '2 are suppressing hot listings', tone: 'rose' },
  { label: 'Stale listings', value: '37 due', note: 'Ponce and Beltline need rechecks first', tone: 'warn' },
] as const;

export const venues: VenueDetail[] = [
  {
    id: 'ven_taqueria_del_sol',
    name: 'Taqueria del Sol',
    neighborhood: 'West Midtown',
    address: '1200 Howell Mill Rd NW, Atlanta, GA 30318',
    latitude: 33.7867,
    longitude: -84.4112,
    rating: 4.7,
    listingIds: ['lst_taco_tuesday'],
    tags: ['cheap-eats', 'students', 'live-now'],
    activeListingCount: 1,
  },
  {
    id: 'ven_sakura_ramen',
    name: 'Sakura Ramen House',
    neighborhood: 'Midtown',
    address: '933 Peachtree St NE, Atlanta, GA 30309',
    latitude: 33.7815,
    longitude: -84.3873,
    rating: 4.9,
    listingIds: ['lst_bogo_ramen'],
    tags: ['tonight', 'groups'],
    activeListingCount: 1,
  },
  {
    id: 'ven_beltline_bar',
    name: 'Beltline Bar',
    neighborhood: 'Beltline East',
    address: '725 Ponce De Leon Ave NE, Atlanta, GA 30306',
    latitude: 33.7728,
    longitude: -84.3661,
    rating: 4.4,
    listingIds: ['lst_happy_hour_pitcher'],
    tags: ['drinks', 'happy-hour'],
    activeListingCount: 1,
  },
];

export const listings: ListingDetail[] = [
  {
    id: 'lst_taco_tuesday',
    venueId: 'ven_taqueria_del_sol',
    venueName: 'Taqueria del Sol',
    title: 'Taco Tuesday Special',
    neighborhood: 'West Midtown',
    categoryLabel: 'Cheap eats',
    scheduleLabel: 'Live now • Tue 4PM-10PM',
    trustBand: 'founder_verified',
    freshnessText: 'Updated 42 mins ago',
    valueNote: 'Street tacos from $4.99 with rotating fillings.',
    affordabilityLabel: 'Under $10',
    distanceMiles: 0.3,
    rating: 4.7,
    cuisine: 'Mexican',
    latitude: 33.7867,
    longitude: -84.4112,
    tags: ['cheap-eats', 'students', 'live-now'],
    saved: false,
    venueAddress: '1200 Howell Mill Rd NW, Atlanta, GA 30318',
    description: 'Founder-added lunch and dinner special near Howell Mill.',
    conditions: 'Dine-in only. While supplies last.',
    sourceNote: 'Founder-added from menu board and in-store confirmation.',
    offers: [{ id: 'off_1', title: 'Taco Tuesday Special', originalPrice: 9.99, dealPrice: 4.99, currency: 'USD' }],
    confidenceScore: 0.94,
    lastUpdatedAt: '2026-04-14T21:18:00.000Z',
    freshUntilAt: '2026-04-15T03:00:00.000Z',
    recheckAfterAt: '2026-04-15T15:00:00.000Z',
    proofCount: 2,
    trustSummary: trustSummaryFor({
      trustBand: 'founder_verified',
      confidenceScore: 0.94,
      freshUntilAt: '2026-04-15T03:00:00.000Z',
      recheckAfterAt: '2026-04-15T15:00:00.000Z',
      proofCount: 2,
    }),
  },
  {
    id: 'lst_slice_combo',
    venueId: 'ven_bella_napoli',
    venueName: 'Bella Napoli',
    title: 'Late-night slice and soda',
    neighborhood: 'Ponce',
    categoryLabel: 'Fresh this week',
    scheduleLabel: 'Late night • Daily after 9PM',
    trustBand: 'needs_recheck',
    freshnessText: 'Last verified yesterday',
    valueNote: 'Fast pickup option near Beltline traffic.',
    affordabilityLabel: 'Under $10',
    distanceMiles: 1.2,
    rating: 4.5,
    cuisine: 'Italian',
    latitude: 33.7721,
    longitude: -84.3632,
    tags: ['late-night', 'beltline', 'pizza'],
    saved: false,
    venueAddress: '650 North Ave NE, Atlanta, GA 30308',
    description: 'Conflicting reports reduced confidence and triggered recheck.',
    conditions: 'Applies to cheese or pepperoni slices only.',
    sourceNote: 'Recent conflict reports lowered confidence.',
    offers: [{ id: 'off_2', title: 'Slice + Drink', originalPrice: 8.5, dealPrice: 5, currency: 'USD' }],
    confidenceScore: 0.43,
    lastUpdatedAt: '2026-04-13T19:20:00.000Z',
    freshUntilAt: '2026-04-14T08:00:00.000Z',
    recheckAfterAt: '2026-04-14T23:30:00.000Z',
    proofCount: 0,
    trustSummary: trustSummaryFor({
      trustBand: 'needs_recheck',
      confidenceScore: 0.43,
      freshUntilAt: '2026-04-14T08:00:00.000Z',
      recheckAfterAt: '2026-04-14T23:30:00.000Z',
      proofCount: 0,
    }),
  },
  {
    id: 'lst_happy_hour_pitcher',
    venueId: 'ven_beltline_bar',
    venueName: 'Beltline Bar',
    title: 'Half-off pitcher happy hour',
    neighborhood: 'Beltline East',
    categoryLabel: 'Drink deals',
    scheduleLabel: 'Tonight • Wed-Fri 5PM-7PM',
    trustBand: 'recently_updated',
    freshnessText: 'Recently updated today',
    valueNote: 'Popular after-work and student meetup stop.',
    affordabilityLabel: 'Under $15',
    distanceMiles: 1.1,
    rating: 4.4,
    cuisine: 'Bar',
    latitude: 33.7728,
    longitude: -84.3661,
    tags: ['drinks', 'happy-hour'],
    saved: false,
    venueAddress: '725 Ponce De Leon Ave NE, Atlanta, GA 30306',
    description: 'Drink-led listing positioned for later age-gated verification support.',
    conditions: '21+ only. Valid on house lager pitcher until 7PM.',
    sourceNote: 'Updated with moderator-attached photo proof.',
    offers: [{ id: 'off_3', title: 'House Lager Pitcher', originalPrice: 18, dealPrice: 9, currency: 'USD' }],
    confidenceScore: 0.69,
    lastUpdatedAt: '2026-04-14T16:05:00.000Z',
    freshUntilAt: '2026-04-14T23:30:00.000Z',
    recheckAfterAt: '2026-04-15T06:00:00.000Z',
    proofCount: 1,
    trustSummary: trustSummaryFor({
      trustBand: 'recently_updated',
      confidenceScore: 0.69,
      freshUntilAt: '2026-04-14T23:30:00.000Z',
      recheckAfterAt: '2026-04-15T06:00:00.000Z',
      proofCount: 1,
    }),
  },
];

export const moderationQueue: AdminQueueItem[] = [
  {
    id: 'adm_con_002',
    entityId: 'con_002',
    type: 'contribution',
    title: 'Bella Napoli requires stale-review decision',
    subtitle: 'Conflict between latest user update and previous confirmation.',
    neighborhood: 'Ponce',
    trustBand: 'needs_recheck',
    createdAt: '2026-04-14T21:01:00.000Z',
    priority: 'high',
    status: 'pending',
  },
  {
    id: 'adm_con_003',
    entityId: 'con_003',
    type: 'contribution',
    title: 'Beltline Bar photo proof ready for verification',
    subtitle: 'Moderator-submitted update attached a pricing-board image.',
    neighborhood: 'Beltline East',
    trustBand: 'recently_updated',
    createdAt: '2026-04-14T19:20:00.000Z',
    priority: 'medium',
    status: 'pending',
  },
];

export const reportQueue: AdminQueueItem[] = [
  {
    id: 'adm_rep_001',
    entityId: 'rep_001',
    type: 'report',
    title: 'Expired report on Late-night slice and soda',
    subtitle: 'Two open reports are actively reducing trust.',
    neighborhood: 'Ponce',
    trustBand: 'needs_recheck',
    createdAt: '2026-04-14T20:59:00.000Z',
    priority: 'high',
    status: 'open',
  },
];

export const staleQueue: AdminQueueItem[] = [
  {
    id: 'adm_stale_001',
    entityId: 'lst_slice_combo',
    type: 'stale_listing',
    title: 'Bella Napoli crossed its recheck SLA',
    subtitle: 'Freshness window expired without a new high-confidence confirmation.',
    neighborhood: 'Ponce',
    trustBand: 'needs_recheck',
    createdAt: '2026-04-14T23:30:00.000Z',
    priority: 'high',
    status: 'due',
  },
];

export const contributors: Array<
  Profile & {
    trustScore: number;
    currentStreakDays: number;
    approvalAccuracy: number;
  }
> = [
  {
    id: 'usr_alex',
    email: 'alex@dealdrop.app',
    displayName: 'Alex Morgan',
    homeNeighborhood: 'West Midtown',
    role: 'user',
    verifiedContributor: true,
    trustScore: 0.83,
    currentStreakDays: 5,
    approvalAccuracy: 0.92,
  },
  {
    id: 'usr_sam',
    email: 'sam@dealdrop.app',
    displayName: 'Sam Rivera',
    homeNeighborhood: 'Colony Square',
    role: 'user',
    verifiedContributor: false,
    trustScore: 0.42,
    currentStreakDays: 1,
    approvalAccuracy: 0.58,
  },
];

export const auditEntries = [
  {
    id: 'aud_001',
    action: 'moderation.merge_duplicate',
    entityType: 'contribution',
    entityId: 'con_002',
    actor: 'Maya Brooks',
    createdAt: '2026-04-14T21:12:00.000Z',
  },
  {
    id: 'aud_002',
    action: 'listing.stale_scan_flagged',
    entityType: 'listing',
    entityId: 'lst_slice_combo',
    actor: 'System',
    createdAt: '2026-04-14T23:30:00.000Z',
  },
];
