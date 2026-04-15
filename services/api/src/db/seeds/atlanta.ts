import type {
  AdminQueueItem,
  ContributionStatus,
  NotificationRecord,
  PointsLedgerEntry,
  Profile,
  TrustBand,
  UserPreferences,
  VenueDetail,
} from '@dealdrop/shared-types';

export type SeedUser = Profile & {
  neighborhoodSlugs: string[];
  password: string;
};

export type SeedVenue = VenueDetail & {
  slug: string;
};

export type SeedListing = {
  id: string;
  slug: string;
  venueId: string;
  venueName: string;
  title: string;
  neighborhood: string;
  categoryLabel: string;
  scheduleLabel: string;
  trustBand: TrustBand;
  freshnessText: string;
  valueNote: string;
  distanceMiles: number;
  rating: number;
  cuisine: string;
  latitude: number;
  longitude: number;
  tags: string[];
  saved?: boolean;
  venueAddress: string;
  description: string;
  conditions: string;
  sourceNote: string;
  offers: Array<{
    id: string;
    title: string;
    originalPrice: number;
    dealPrice: number;
    currency: string;
  }>;
  confidenceScore: number;
  freshUntilAt: string;
  recheckAfterAt: string;
  proofCount: number;
  status: 'active' | 'stale' | 'suppressed';
  liveCategory: 'live_now' | 'tonight' | 'nearby' | 'student';
  proofAssetKeys: string[];
  recentConfirmations: number;
  negativeSignals: number;
  sourceType: 'founder' | 'merchant' | 'user' | 'moderator';
  lastVerifiedAt: string;
};

export type SeedContribution = {
  id: string;
  listingId: string;
  userId: string;
  type: 'new_listing' | 'listing_update' | 'confirm_valid' | 'report_expired';
  status: ContributionStatus;
  createdAt: string;
  summary: string;
  neighborhood: string;
  pointsDelta?: number;
  pointsStatus?: 'pending' | 'finalized' | 'reversed';
};

export type SeedReport = {
  id: string;
  listingId: string;
  userId: string;
  reason: string;
  createdAt: string;
  status: 'open' | 'resolved';
};

export type LaunchSeedDataset = {
  users: SeedUser[];
  venues: SeedVenue[];
  listings: SeedListing[];
  contributions: SeedContribution[];
  reports: SeedReport[];
  pointsLedger: PointsLedgerEntry[];
  adminQueues: AdminQueueItem[];
  favoriteIdsByUser: Record<string, string[]>;
  notificationsByUser: Record<string, NotificationRecord[]>;
  preferencesByUser: Record<string, UserPreferences>;
  deviceRegistrations: Array<{
    userId: string;
    deviceId: string;
    platform: 'ios' | 'android' | 'web' | 'macos' | 'windows' | 'linux';
    pushToken: string | null;
    locale: string;
    notificationsEnabled: boolean;
  }>;
  telemetryEvents: Array<{
    name: string;
    happenedAt: string;
    screen?: string;
    properties: Record<string, unknown>;
  }>;
};

export const atlantaSeed: LaunchSeedDataset = {
  users: [
    {
      id: 'usr_alex',
      email: 'alex@dealdrop.app',
      displayName: 'Alex Morgan',
      homeNeighborhood: 'West Midtown',
      role: 'user',
      verifiedContributor: true,
      neighborhoodSlugs: ['west-midtown', 'colony-square'],
      password: 'dealdrop123',
    },
    {
      id: 'usr_maya',
      email: 'maya@dealdrop.app',
      displayName: 'Maya Brooks',
      homeNeighborhood: 'Ponce',
      role: 'moderator',
      verifiedContributor: true,
      neighborhoodSlugs: ['ponce', 'beltline-east'],
      password: 'dealdrop123',
    },
    {
      id: 'usr_jon',
      email: 'jon@dealdrop.app',
      displayName: 'Jon Patel',
      homeNeighborhood: 'North Avenue',
      role: 'admin',
      verifiedContributor: true,
      neighborhoodSlugs: ['north-avenue', 'midtown'],
      password: 'dealdrop123',
    },
    {
      id: 'usr_sam',
      email: 'sam@dealdrop.app',
      displayName: 'Sam Rivera',
      homeNeighborhood: 'Colony Square',
      role: 'user',
      verifiedContributor: false,
      neighborhoodSlugs: ['colony-square', 'midtown'],
      password: 'dealdrop123',
    },
  ],
  venues: [
    {
      id: 'ven_taqueria_del_sol',
      slug: 'taqueria-del-sol',
      name: 'Taqueria del Sol',
      neighborhood: 'West Midtown',
      address: '1200 Howell Mill Rd NW, Atlanta, GA 30318',
      latitude: 33.7867,
      longitude: -84.4112,
      rating: 4.7,
      listingIds: ['lst_taco_tuesday'],
      tags: ['cheap-eats', 'tacos', 'students'],
      activeListingCount: 1,
    },
    {
      id: 'ven_sakura_ramen',
      slug: 'sakura-ramen-house',
      name: 'Sakura Ramen House',
      neighborhood: 'Midtown',
      address: '933 Peachtree St NE, Atlanta, GA 30309',
      latitude: 33.7815,
      longitude: -84.3873,
      rating: 4.9,
      listingIds: ['lst_bogo_ramen'],
      tags: ['tonight', 'drinks', 'groups'],
      activeListingCount: 1,
    },
    {
      id: 'ven_bella_napoli',
      slug: 'bella-napoli',
      name: 'Bella Napoli',
      neighborhood: 'Ponce',
      address: '650 North Ave NE, Atlanta, GA 30308',
      latitude: 33.7721,
      longitude: -84.3632,
      rating: 4.5,
      listingIds: ['lst_slice_combo'],
      tags: ['late-night', 'beltline', 'pizza'],
      activeListingCount: 1,
    },
    {
      id: 'ven_holy_guac',
      slug: 'holy-guac',
      name: 'Holy Guac',
      neighborhood: 'North Avenue',
      address: '685 North Ave NE, Atlanta, GA 30308',
      latitude: 33.7714,
      longitude: -84.3639,
      rating: 4.8,
      listingIds: ['lst_two_dollar_taco'],
      tags: ['cheap-eats', 'student', 'live-now'],
      activeListingCount: 1,
    },
    {
      id: 'ven_neon_ramen',
      slug: 'neon-ramen',
      name: 'Neon Ramen',
      neighborhood: 'Colony Square',
      address: '1197 Peachtree St NE, Atlanta, GA 30361',
      latitude: 33.7863,
      longitude: -84.3838,
      rating: 4.6,
      listingIds: ['lst_gyoza_bundle'],
      tags: ['tonight', 'groups'],
      activeListingCount: 1,
    },
    {
      id: 'ven_beltline_bar',
      slug: 'beltline-bar',
      name: 'Beltline Bar',
      neighborhood: 'Beltline East',
      address: '725 Ponce De Leon Ave NE, Atlanta, GA 30306',
      latitude: 33.7728,
      longitude: -84.3661,
      rating: 4.4,
      listingIds: ['lst_happy_hour_pitcher'],
      tags: ['drinks', 'happy-hour', 'beltline'],
      activeListingCount: 1,
    },
  ],
  listings: [
    {
      id: 'lst_taco_tuesday',
      slug: 'taco-tuesday-special',
      venueId: 'ven_taqueria_del_sol',
      venueName: 'Taqueria del Sol',
      title: 'Taco Tuesday Special',
      neighborhood: 'West Midtown',
      categoryLabel: 'Cheap eats',
      scheduleLabel: 'Live now • Tue 4PM-10PM',
      trustBand: 'founder_verified',
      freshnessText: 'Updated 42 mins ago',
      valueNote: 'Street tacos from $4.99 with rotating house fillings.',
      distanceMiles: 0.3,
      rating: 4.7,
      cuisine: 'Mexican',
      latitude: 33.7867,
      longitude: -84.4112,
      tags: ['cheap-eats', 'students', 'live-now'],
      saved: false,
      venueAddress: '1200 Howell Mill Rd NW, Atlanta, GA 30318',
      description: 'Founder-added lunch and dinner special near the Howell Mill corridor.',
      conditions: 'Dine-in only. While supplies last.',
      sourceNote: 'Founder-added from menu board and in-store confirmation.',
      offers: [
        { id: 'off_taco', title: 'Taco Tuesday Special', originalPrice: 9.99, dealPrice: 4.99, currency: 'USD' },
        { id: 'off_burrito', title: 'Burrito Bowl Combo', originalPrice: 13.99, dealPrice: 7.99, currency: 'USD' },
      ],
      confidenceScore: 0.94,
      freshUntilAt: '2026-04-15T03:00:00.000Z',
      recheckAfterAt: '2026-04-15T15:00:00.000Z',
      proofCount: 2,
      status: 'active',
      liveCategory: 'live_now',
      proofAssetKeys: ['proofs/taqueria/menu-board-1.jpg'],
      recentConfirmations: 5,
      negativeSignals: 0,
      sourceType: 'founder',
      lastVerifiedAt: '2026-04-14T21:18:00.000Z',
    },
    {
      id: 'lst_bogo_ramen',
      slug: 'bogo-ramen-bowls',
      venueId: 'ven_sakura_ramen',
      venueName: 'Sakura Ramen House',
      title: 'BOGO ramen bowls',
      neighborhood: 'Midtown',
      categoryLabel: 'Tonight',
      scheduleLabel: 'Tonight • 6PM-9PM',
      trustBand: 'user_confirmed',
      freshnessText: '3 recent confirmations',
      valueNote: 'Strong group value with late-evening availability.',
      distanceMiles: 0.8,
      rating: 4.9,
      cuisine: 'Japanese',
      latitude: 33.7815,
      longitude: -84.3873,
      tags: ['tonight', 'groups', 'ramen'],
      saved: true,
      venueAddress: '933 Peachtree St NE, Atlanta, GA 30309',
      description: 'High-confidence Midtown dinner special with repeat confirmations.',
      conditions: 'Valid on signature tonkotsu bowls for dine-in guests.',
      sourceNote: 'User confirmation weighted by prior accuracy score.',
      offers: [
        { id: 'off_tonkotsu', title: 'Tonkotsu Ramen', originalPrice: 14.99, dealPrice: 8.99, currency: 'USD' },
      ],
      confidenceScore: 0.81,
      freshUntilAt: '2026-04-15T01:30:00.000Z',
      recheckAfterAt: '2026-04-15T09:00:00.000Z',
      proofCount: 1,
      status: 'active',
      liveCategory: 'tonight',
      proofAssetKeys: ['proofs/sakura/receipt.jpg'],
      recentConfirmations: 3,
      negativeSignals: 0,
      sourceType: 'user',
      lastVerifiedAt: '2026-04-14T20:48:00.000Z',
    },
    {
      id: 'lst_slice_combo',
      slug: 'late-night-slice-and-soda',
      venueId: 'ven_bella_napoli',
      venueName: 'Bella Napoli',
      title: 'Late-night slice and soda',
      neighborhood: 'Ponce',
      categoryLabel: 'Fresh this week',
      scheduleLabel: 'Late night • Daily after 9PM',
      trustBand: 'disputed',
      freshnessText: 'Last verified yesterday',
      valueNote: 'Fast pickup option near Beltline traffic.',
      distanceMiles: 1.2,
      rating: 4.5,
      cuisine: 'Italian',
      latitude: 33.7721,
      longitude: -84.3632,
      tags: ['late-night', 'beltline', 'pizza'],
      saved: false,
      venueAddress: '650 North Ave NE, Atlanta, GA 30308',
      description: 'Still popular, but conflicting reports reduced trust and triggered recheck.',
      conditions: 'Applies to cheese or pepperoni slices only.',
      sourceNote: 'Recent conflict reports lowered confidence.',
      offers: [
        { id: 'off_slice', title: 'Slice + Drink', originalPrice: 8.5, dealPrice: 5.0, currency: 'USD' },
      ],
      confidenceScore: 0.43,
      freshUntilAt: '2026-04-14T08:00:00.000Z',
      recheckAfterAt: '2026-04-14T23:30:00.000Z',
      proofCount: 0,
      status: 'stale',
      liveCategory: 'tonight',
      proofAssetKeys: [],
      recentConfirmations: 1,
      negativeSignals: 2,
      sourceType: 'user',
      lastVerifiedAt: '2026-04-13T23:07:00.000Z',
    },
    {
      id: 'lst_two_dollar_taco',
      slug: 'two-dollar-taco-tuesday',
      venueId: 'ven_holy_guac',
      venueName: 'Holy Guac',
      title: '$2 Taco Tuesday',
      neighborhood: 'North Avenue',
      categoryLabel: 'Top rated',
      scheduleLabel: 'Live now • Tue all day',
      trustBand: 'user_confirmed',
      freshnessText: 'High-confidence today',
      valueNote: 'Excellent quick group stop close to campus density.',
      distanceMiles: 0.6,
      rating: 4.8,
      cuisine: 'Mexican',
      latitude: 33.7714,
      longitude: -84.3639,
      tags: ['cheap-eats', 'student', 'live-now'],
      saved: true,
      venueAddress: '685 North Ave NE, Atlanta, GA 30308',
      description: 'Campus-adjacent value listing with consistent same-day confirmations.',
      conditions: 'Limit four tacos per guest.',
      sourceNote: 'Multiple weighted confirmations plus historical stability.',
      offers: [
        { id: 'off_holy_guac', title: 'Any Taco', originalPrice: 4.5, dealPrice: 2.0, currency: 'USD' },
      ],
      confidenceScore: 0.86,
      freshUntilAt: '2026-04-15T00:00:00.000Z',
      recheckAfterAt: '2026-04-15T07:00:00.000Z',
      proofCount: 1,
      status: 'active',
      liveCategory: 'live_now',
      proofAssetKeys: ['proofs/holy-guac/menu.jpg'],
      recentConfirmations: 4,
      negativeSignals: 0,
      sourceType: 'user',
      lastVerifiedAt: '2026-04-14T19:26:00.000Z',
    },
    {
      id: 'lst_gyoza_bundle',
      slug: 'free-gyoza-with-bowl',
      venueId: 'ven_neon_ramen',
      venueName: 'Neon Ramen',
      title: 'Free gyoza with bowl',
      neighborhood: 'Colony Square',
      categoryLabel: 'Group-friendly',
      scheduleLabel: 'Tonight • Mon-Thu 5PM-8PM',
      trustBand: 'founder_verified',
      freshnessText: 'Founder verified',
      valueNote: 'Good fallback when groups split between ramen styles.',
      distanceMiles: 0.5,
      rating: 4.6,
      cuisine: 'Japanese',
      latitude: 33.7863,
      longitude: -84.3838,
      tags: ['tonight', 'groups'],
      saved: false,
      venueAddress: '1197 Peachtree St NE, Atlanta, GA 30361',
      description: 'Colony Square dinner value positioned for office and campus overlap.',
      conditions: 'One order of gyoza per bowl purchased.',
      sourceNote: 'Founder-added with same-day menu verification.',
      offers: [
        { id: 'off_gyoza', title: 'Signature Bowl + Gyoza', originalPrice: 18, dealPrice: 12, currency: 'USD' },
      ],
      confidenceScore: 0.91,
      freshUntilAt: '2026-04-15T00:30:00.000Z',
      recheckAfterAt: '2026-04-15T16:00:00.000Z',
      proofCount: 2,
      status: 'active',
      liveCategory: 'tonight',
      proofAssetKeys: ['proofs/neon-ramen/special.jpg'],
      recentConfirmations: 2,
      negativeSignals: 0,
      sourceType: 'founder',
      lastVerifiedAt: '2026-04-14T16:19:00.000Z',
    },
    {
      id: 'lst_happy_hour_pitcher',
      slug: 'beltline-happy-hour-pitcher',
      venueId: 'ven_beltline_bar',
      venueName: 'Beltline Bar',
      title: 'Half-off pitcher happy hour',
      neighborhood: 'Beltline East',
      categoryLabel: 'Drink deals',
      scheduleLabel: 'Tonight • Wed-Fri 5PM-7PM',
      trustBand: 'merchant_confirmed',
      freshnessText: 'Recently updated today',
      valueNote: 'Popular after-work and student meetup stop with drink specials.',
      distanceMiles: 1.1,
      rating: 4.4,
      cuisine: 'Bar',
      latitude: 33.7728,
      longitude: -84.3661,
      tags: ['drinks', 'happy-hour', 'beltline'],
      saved: false,
      venueAddress: '725 Ponce De Leon Ave NE, Atlanta, GA 30306',
      description: 'Drink-led listing supporting future age-gated and ID-aware verification.',
      conditions: '21+ only. Valid on house lager pitcher until 7PM.',
      sourceNote: 'Recently updated via staff confirmation and same-day photo.',
      offers: [
        { id: 'off_pitcher', title: 'House Lager Pitcher', originalPrice: 18, dealPrice: 9, currency: 'USD' },
      ],
      confidenceScore: 0.69,
      freshUntilAt: '2026-04-14T23:30:00.000Z',
      recheckAfterAt: '2026-04-15T06:00:00.000Z',
      proofCount: 1,
      status: 'active',
      liveCategory: 'tonight',
      proofAssetKeys: ['proofs/beltline-bar/happy-hour.jpg'],
      recentConfirmations: 2,
      negativeSignals: 1,
      sourceType: 'merchant',
      lastVerifiedAt: '2026-04-14T18:11:00.000Z',
    },
  ],
  contributions: [
    {
      id: 'con_001',
      listingId: 'lst_bogo_ramen',
      userId: 'usr_alex',
      type: 'confirm_valid',
      status: 'approved',
      createdAt: '2026-04-14T20:48:00.000Z',
      summary: 'Confirmed dinner promo is active at register.',
      neighborhood: 'Midtown',
    },
    {
      id: 'con_002',
      listingId: 'lst_slice_combo',
      userId: 'usr_sam',
      type: 'listing_update',
      status: 'under_review',
      createdAt: '2026-04-14T21:01:00.000Z',
      summary: 'Claimed the combo is no longer valid after 10PM.',
      neighborhood: 'Ponce',
    },
    {
      id: 'con_003',
      listingId: 'lst_happy_hour_pitcher',
      userId: 'usr_maya',
      type: 'listing_update',
      status: 'submitted',
      createdAt: '2026-04-14T19:20:00.000Z',
      summary: 'Attached photo for updated drink pricing board.',
      neighborhood: 'Beltline East',
    },
  ],
  reports: [
    {
      id: 'rep_001',
      listingId: 'lst_slice_combo',
      userId: 'usr_sam',
      reason: 'expired',
      createdAt: '2026-04-14T20:59:00.000Z',
      status: 'open',
    },
    {
      id: 'rep_002',
      listingId: 'lst_happy_hour_pitcher',
      userId: 'usr_alex',
      reason: 'details_incorrect',
      createdAt: '2026-04-14T18:25:00.000Z',
      status: 'open',
    },
  ],
  pointsLedger: [
    { id: 'pts_001', userId: 'usr_alex', reason: 'confirmation_approved', pointsDelta: 14, status: 'finalized', createdAt: '2026-04-14T20:55:00.000Z' },
    { id: 'pts_002', userId: 'usr_maya', reason: 'moderation_resolution', pointsDelta: 22, status: 'finalized', createdAt: '2026-04-14T21:10:00.000Z' },
    { id: 'pts_003', userId: 'usr_jon', reason: 'founder_seed_verification', pointsDelta: 18, status: 'finalized', createdAt: '2026-04-14T17:05:00.000Z' },
    { id: 'pts_004', userId: 'usr_alex', reason: 'pending_photo_proof', pointsDelta: 5, status: 'pending', createdAt: '2026-04-14T21:00:00.000Z' },
    { id: 'pts_005', userId: 'usr_sam', reason: 'report_submitted', pointsDelta: 3, status: 'pending', createdAt: '2026-04-14T21:01:00.000Z' },
    { id: 'pts_006', userId: 'usr_maya', reason: 'stale_listing_review', pointsDelta: 17, status: 'finalized', createdAt: '2026-04-13T17:01:00.000Z' },
  ],
  adminQueues: [
    {
      id: 'adm_con_002',
      entityId: 'con_002',
      type: 'contribution',
      title: 'Bella Napoli requires stale-review decision',
      subtitle: 'Conflict between latest user update and previous confirmation.',
      neighborhood: 'Ponce',
      trustBand: 'disputed',
      createdAt: '2026-04-14T21:01:00.000Z',
      priority: 'high',
      status: 'pending',
    },
    {
      id: 'adm_rep_001',
      entityId: 'rep_001',
      type: 'report',
      title: 'Expired report on Late-night slice and soda',
      subtitle: 'Two open reports are actively reducing trust.',
      neighborhood: 'Ponce',
      trustBand: 'disputed',
      createdAt: '2026-04-14T20:59:00.000Z',
      priority: 'high',
      status: 'open',
    },
    {
      id: 'adm_stale_001',
      entityId: 'lst_slice_combo',
      type: 'stale_listing',
      title: 'Bella Napoli has crossed its recheck SLA',
      subtitle: 'Freshness window expired and requires moderation touch.',
      neighborhood: 'Ponce',
      trustBand: 'needs_recheck',
      createdAt: '2026-04-14T23:30:00.000Z',
      priority: 'high',
      status: 'due',
    },
  ],
  favoriteIdsByUser: {
    usr_alex: ['lst_bogo_ramen', 'lst_two_dollar_taco'],
    usr_maya: ['lst_happy_hour_pitcher'],
    usr_jon: ['lst_taco_tuesday'],
    usr_sam: ['lst_slice_combo'],
  },
  notificationsByUser: {
    usr_alex: [
      {
        id: 'ntf_001',
        kind: 'points_finalized',
        title: '14 points finalized',
        body: 'Your Midtown ramen confirmation cleared review and counted toward your streak.',
        createdAt: '2026-04-14T21:05:00.000Z',
        readAt: null,
        deepLink: '/karma',
      },
      {
        id: 'ntf_002',
        kind: 'trust_status_changed',
        title: 'Bella Napoli moved to disputed',
        body: 'Conflicting reports lowered confidence on the late-night slice deal.',
        createdAt: '2026-04-14T21:02:00.000Z',
        readAt: null,
        deepLink: '/listing/lst_slice_combo',
      },
    ],
    usr_maya: [
      {
        id: 'ntf_003',
        kind: 'moderation_update',
        title: 'Moderation queue spiked',
        body: 'Three stale listings now need a decision before morning commute traffic.',
        createdAt: '2026-04-14T22:15:00.000Z',
        readAt: '2026-04-14T22:22:00.000Z',
        deepLink: '/account/notifications',
      },
    ],
    usr_jon: [],
    usr_sam: [
      {
        id: 'ntf_004',
        kind: 'contribution_resolved',
        title: 'Your report is under review',
        body: 'The Bella Napoli stale report is in the moderation queue now.',
        createdAt: '2026-04-14T21:03:00.000Z',
        readAt: null,
        deepLink: '/post',
      },
    ],
  },
  preferencesByUser: {
    usr_alex: {
      contributionResolved: true,
      pointsFinalized: true,
      trustStatusChanged: true,
      marketingAnnouncements: false,
    },
    usr_maya: {
      contributionResolved: true,
      pointsFinalized: true,
      trustStatusChanged: true,
      marketingAnnouncements: false,
    },
    usr_jon: {
      contributionResolved: true,
      pointsFinalized: true,
      trustStatusChanged: true,
      marketingAnnouncements: false,
    },
    usr_sam: {
      contributionResolved: true,
      pointsFinalized: true,
      trustStatusChanged: false,
      marketingAnnouncements: false,
    },
  },
  deviceRegistrations: [],
  telemetryEvents: [],
};
