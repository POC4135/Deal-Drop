import { buildCacheKey, cacheTtls, eventTypes } from '@dealdrop/config';
import type {
  AdminQueueItem,
  AuthResponse,
  ContributionCreate,
  ContributionHistoryResponse,
  ContributionRecord,
  ContributionUpdate,
  DeviceRegistration,
  FeedResponse,
  FiltersMetadata,
  KarmaSummary,
  LeaderboardEntry,
  LeaderboardWindow,
  ListingCard,
  ListingDetail,
  MapListing,
  NotificationRecord,
  NotificationsResponse,
  Profile,
  ReportExpired,
  SearchResult,
  TelemetryEvent,
  UserPreferences,
  VenueDetail,
} from '@dealdrop/shared-types';
import { ulid } from 'ulid';

import { atlantaSeed, type LaunchSeedDataset } from '../db/seeds/atlanta.js';
import { InMemoryCacheStore, type CacheStore } from '../lib/cache.js';
import { InMemoryEventStore, type EventStore } from '../lib/events.js';
import { haversineDistanceMiles, isPointInBounds } from '../lib/geo.js';
import { applyCursorPagination } from '../lib/pagination.js';
import { buildKarmaSummary, computeLeaderboard } from '../modules/gamification/engine.js';
import { computeConfidence } from '../modules/trust/engine.js';

type FeedQuery = {
  latitude?: number;
  longitude?: number;
  cursor?: string;
  limit: number;
};

type NearbyQuery = FeedQuery & { radiusMiles: number };
type MapBoundsQuery = {
  north: number;
  south: number;
  east: number;
  west: number;
  zoom?: number;
  trustBand?: string;
};

export class DealDropPlatform {
  constructor(
    private readonly seed: LaunchSeedDataset = atlantaSeed,
    private readonly cache: CacheStore = new InMemoryCacheStore(),
    private readonly events: EventStore = new InMemoryEventStore(),
  ) {}

  authenticate(input: {
    email: string;
    password: string;
    displayName?: string;
    homeNeighborhood?: string;
    mode: 'sign_in' | 'sign_up';
  }): AuthResponse {
    const normalizedEmail = input.email.trim().toLowerCase();
    let profile = this.seed.users.find((user) => user.email.toLowerCase() === normalizedEmail);

    if (!profile && input.mode === 'sign_in') {
      throw new Error('invalid_credentials');
    }

    if (profile && input.mode === 'sign_in' && profile.password !== input.password) {
      throw new Error('invalid_credentials');
    }

    if (profile && input.mode === 'sign_up') {
      throw new Error('email_already_exists');
    }

    if (!profile) {
      profile = {
        id: `usr_${ulid().toLowerCase()}`,
        email: normalizedEmail,
        displayName: input.displayName?.trim() || normalizedEmail.split('@')[0] || 'DealDrop User',
        homeNeighborhood: input.homeNeighborhood ?? 'Midtown',
        role: 'user',
        verifiedContributor: false,
        neighborhoodSlugs: [slugify(input.homeNeighborhood ?? 'Midtown')],
        password: input.password,
      };
      this.seed.users.unshift(profile);
      this.seed.favoriteIdsByUser[profile.id] = [];
      this.seed.notificationsByUser[profile.id] = [];
      this.seed.preferencesByUser[profile.id] = {
        contributionResolved: true,
        pointsFinalized: true,
        trustStatusChanged: true,
        marketingAnnouncements: false,
      };
    }

    return {
      session: {
        userId: profile.id,
        email: profile.email,
        displayName: profile.displayName,
        role: profile.role,
        verifiedContributor: profile.verifiedContributor,
      },
      profile,
    };
  }

  getFiltersMetadata(): FiltersMetadata {
    return {
      neighborhoods: [...new Set(this.seed.listings.map((listing) => listing.neighborhood))].sort(),
      cuisines: [...new Set(this.seed.listings.map((listing) => listing.cuisine))].sort(),
      tags: [...new Set(this.seed.listings.flatMap((listing) => listing.tags))].sort(),
      trustBands: [
        'founder_verified',
        'merchant_confirmed',
        'user_confirmed',
        'recently_updated',
        'needs_recheck',
        'disputed',
      ],
    };
  }

  getProfile(userId: string): Profile {
    return this.seed.users.find((user) => user.id === userId) ?? this.seed.users[0];
  }

  getPreferences(userId: string): UserPreferences {
    return (
      this.seed.preferencesByUser[userId] ?? {
        contributionResolved: true,
        pointsFinalized: true,
        trustStatusChanged: true,
        marketingAnnouncements: false,
      }
    );
  }

  updatePreferences(userId: string, input: UserPreferences): UserPreferences {
    this.seed.preferencesByUser[userId] = input;
    return input;
  }

  getNotifications(userId: string): NotificationsResponse {
    const items = (this.seed.notificationsByUser[userId] ?? []).sort((left, right) =>
      right.createdAt.localeCompare(left.createdAt),
    );
    return {
      items,
      unreadCount: items.filter((item) => !item.readAt).length,
    };
  }

  markNotificationRead(userId: string, notificationId: string): NotificationRecord | undefined {
    const notification = (this.seed.notificationsByUser[userId] ?? []).find((item) => item.id === notificationId);
    if (!notification) {
      return undefined;
    }
    notification.readAt ??= new Date().toISOString();
    return notification;
  }

  getContributionHistory(userId: string): ContributionHistoryResponse {
    return {
      items: this.seed.contributions
        .filter((contribution) => contribution.userId === userId)
        .sort((left, right) => right.createdAt.localeCompare(left.createdAt))
        .map((contribution) => this.toContributionRecord(contribution)),
    };
  }

  getSavedListings(userId: string): ListingCard[] {
    const favoriteIds = new Set(this.seed.favoriteIdsByUser[userId] ?? []);
    return this.seed.listings
      .filter((listing) => favoriteIds.has(listing.id))
      .map((listing) => this.toListingCard(listing, userId));
  }

  getListingDetail(listingId: string, userId?: string): ListingDetail | undefined {
    const listing = this.seed.listings.find((candidate) => candidate.id === listingId);
    if (!listing) {
      return undefined;
    }
    return this.toListingDetail(listing, userId);
  }

  getVenueDetail(venueId: string): VenueDetail | undefined {
    return this.seed.venues.find((venue) => venue.id === venueId);
  }

  async getFeedHome(query: FeedQuery, userId?: string): Promise<FeedResponse> {
    const cacheKey = buildCacheKey('feed-home', query.latitude, query.longitude, query.limit, query.cursor, userId);
    const cached = await this.cache.get<FeedResponse>(cacheKey);
    if (cached) {
      return cached;
    }

    const sorted = this.sortListingsByDistance(this.visibleListings(), query.latitude, query.longitude);
    const page = applyCursorPagination(sorted, query.cursor, query.limit);
    const response: FeedResponse = {
      sections: [
        this.buildFeedSection('live-now', 'Live now', 'Fresh, high-confidence finds around you', page.items, userId, (listing) => listing.liveCategory === 'live_now'),
        this.buildFeedSection('tonight', 'Tonight', 'Dinner, happy-hour, and late-evening value', page.items, userId, (listing) => listing.liveCategory === 'tonight'),
        this.buildFeedSection('cheap-eats', 'Cheap eats', 'Under-$10 plays near campus and commuter traffic', page.items, userId, (listing) => listing.tags.includes('cheap-eats')),
        this.buildFeedSection('fresh-this-week', 'Fresh this week', 'Listings that were verified recently enough to move fast', page.items, userId, (listing) => listing.trustBand !== 'needs_recheck' && listing.trustBand !== 'disputed'),
      ],
      nextCursor: page.nextCursor,
    };

    await this.cache.set(cacheKey, response, cacheTtls.feedHomeSeconds);
    return response;
  }

  async getLiveNow(latitude?: number, longitude?: number, cursor?: string, limit = 20, userId?: string): Promise<{ items: ListingCard[]; nextCursor: string | null }> {
    return this.getListingCollection('live_now', latitude, longitude, cursor, limit, cacheTtls.liveNowSeconds, userId);
  }

  async getTonight(latitude?: number, longitude?: number, cursor?: string, limit = 20, userId?: string): Promise<{ items: ListingCard[]; nextCursor: string | null }> {
    return this.getListingCollection('tonight', latitude, longitude, cursor, limit, cacheTtls.tonightSeconds, userId);
  }

  async getNearby(query: NearbyQuery, userId?: string): Promise<{ items: ListingCard[]; nextCursor: string | null }> {
    const cacheKey = buildCacheKey('nearby', query.latitude, query.longitude, query.radiusMiles, query.cursor, query.limit, userId);
    const cached = await this.cache.get<{ items: ListingCard[]; nextCursor: string | null }>(cacheKey);
    if (cached) {
      return cached;
    }

    const withDistance = this.sortListingsByDistance(this.visibleListings(), query.latitude, query.longitude).filter((listing) =>
      query.latitude === undefined || query.longitude === undefined
        ? true
        : haversineDistanceMiles(query.latitude, query.longitude, listing.latitude, listing.longitude) <= query.radiusMiles,
    );
    const page = applyCursorPagination(withDistance, query.cursor, query.limit);
    const response = {
      items: page.items.map((listing) => this.toListingCard(listing, userId)),
      nextCursor: page.nextCursor,
    };
    await this.cache.set(cacheKey, response, cacheTtls.nearbySeconds);
    return response;
  }

  async getMapBounds(query: MapBoundsQuery, userId?: string): Promise<MapListing[]> {
    const cacheKey = buildCacheKey('map-bounds', query.north, query.south, query.east, query.west, query.zoom, query.trustBand, userId);
    const cached = await this.cache.get<MapListing[]>(cacheKey);
    if (cached) {
      return cached;
    }

    const items = this.visibleListings()
      .filter((listing) => isPointInBounds(listing.latitude, listing.longitude, query.north, query.south, query.east, query.west))
      .filter((listing) => (query.trustBand ? listing.trustBand === query.trustBand : true))
      .map((listing) => ({
        listingId: listing.id,
        venueId: listing.venueId,
        venueName: listing.venueName,
        latitude: listing.latitude,
        longitude: listing.longitude,
        trustBand: listing.trustBand,
        title: listing.title,
        neighborhood: listing.neighborhood,
        confidenceScore: listing.confidenceScore,
        affordabilityLabel: this.affordabilityLabel(listing),
        saved: this.favoriteIdsFor(userId).has(listing.id),
      }));

    await this.cache.set(cacheKey, items, cacheTtls.mapBoundsSeconds);
    return items;
  }

  async search(
    query: {
      q?: string;
      neighborhood?: string;
      cursor?: string;
      limit: number;
      trustBand?: string;
      sort?: string;
    },
    userId?: string,
  ): Promise<SearchResult> {
    const cacheKey = buildCacheKey('search', query.q ?? 'all', query.neighborhood ?? 'all', query.cursor, query.limit, query.trustBand, query.sort, userId);
    const cached = await this.cache.get<SearchResult>(cacheKey);
    if (cached) {
      return cached;
    }

    const normalized = (query.q ?? '').trim().toLowerCase();
    let matchedListings = this.visibleListings().filter((listing) => {
      const haystack = [listing.title, listing.venueName, listing.neighborhood, listing.cuisine, ...listing.tags].join(' ').toLowerCase();
      const neighborhoodMatch = query.neighborhood ? listing.neighborhood === query.neighborhood : true;
      const trustMatch = query.trustBand ? listing.trustBand === query.trustBand : true;
      return neighborhoodMatch && trustMatch && (normalized.length === 0 || haystack.includes(normalized));
    });

    if (query.sort === 'distance') {
      matchedListings = [...matchedListings].sort((left, right) => left.distanceMiles - right.distanceMiles);
    } else if (query.sort === 'confidence') {
      matchedListings = [...matchedListings].sort((left, right) => right.confidenceScore - left.confidenceScore);
    }

    const page = applyCursorPagination(matchedListings, query.cursor, query.limit);
    const response: SearchResult = {
      listings: page.items.map((listing) => this.toListingCard(listing, userId)),
      venues: this.seed.venues.filter((venue) => page.items.some((listing) => listing.venueId === venue.id)),
      neighborhoods: [...new Set(page.items.map((listing) => listing.neighborhood))],
      suggestions: this.buildSuggestions(normalized),
      nextCursor: page.nextCursor,
    };
    await this.cache.set(cacheKey, response, cacheTtls.searchSeconds);
    return response;
  }

  async getKarma(userId: string, window: LeaderboardWindow = 'weekly'): Promise<KarmaSummary> {
    const userEntries = this.seed.pointsLedger.filter((entry) => entry.userId === userId);
    const activityDates = userEntries.map((entry) => entry.createdAt);
    return buildKarmaSummary({
      userId,
      entries: this.seed.pointsLedger,
      users: this.seed.users.map((user) => ({
        id: user.id,
        displayName: user.displayName,
        verifiedContributor: user.verifiedContributor,
      })),
      activityDates,
      badges: [
        { code: 'first-proof', title: 'First Proof', description: 'Upload your first accepted proof.', minPoints: 10 },
        { code: 'week-streak', title: 'Seven Day Run', description: 'Contribute on seven consecutive days.', minPoints: 40 },
        { code: 'trust-anchor', title: 'Trust Anchor', description: 'Maintain high-accuracy confirmations.', minPoints: 140 },
      ],
      window,
    });
  }

  getLeaderboard(window: LeaderboardWindow = 'weekly'): LeaderboardEntry[] {
    return computeLeaderboard(
      this.seed.pointsLedger,
      this.seed.users.map((user) => ({
        id: user.id,
        displayName: user.displayName,
        verifiedContributor: user.verifiedContributor,
      })),
      window,
    );
  }

  async addFavorite(userId: string, listingId: string): Promise<void> {
    this.getRequiredListing(listingId);
    const favorites = this.seed.favoriteIdsByUser[userId] ?? [];
    if (!favorites.includes(listingId)) {
      favorites.unshift(listingId);
      this.seed.favoriteIdsByUser[userId] = favorites;
    }
    await this.events.append({
      type: 'favorite.created',
      occurredAt: new Date().toISOString(),
      aggregateType: 'listing',
      aggregateId: listingId,
      payload: { userId, listingId },
    });
    await this.invalidateUserReadCaches();
  }

  async removeFavorite(userId: string, listingId: string): Promise<void> {
    this.seed.favoriteIdsByUser[userId] = (this.seed.favoriteIdsByUser[userId] ?? []).filter((candidate) => candidate !== listingId);
    await this.events.append({
      type: 'favorite.deleted',
      occurredAt: new Date().toISOString(),
      aggregateType: 'listing',
      aggregateId: listingId,
      payload: { userId, listingId },
    });
    await this.invalidateUserReadCaches();
  }

  async syncFavorites(userId: string, listingIds: string[]): Promise<ListingCard[]> {
    const current = new Set(this.seed.favoriteIdsByUser[userId] ?? []);
    for (const listingId of listingIds) {
      if (this.seed.listings.some((listing) => listing.id === listingId)) {
        current.add(listingId);
      }
    }
    this.seed.favoriteIdsByUser[userId] = [...current];
    await this.invalidateUserReadCaches();
    return this.getSavedListings(userId);
  }

  async createContribution(userId: string, payload: ContributionCreate): Promise<{ contributionId: string; duplicateCandidateIds: string[] }> {
    const contributionId = ulid();
    this.seed.contributions.unshift({
      id: contributionId,
      listingId: 'pending',
      userId,
      type: 'new_listing',
      status: 'submitted',
      createdAt: new Date().toISOString(),
      summary: payload.title,
      neighborhood: payload.neighborhood,
      pointsDelta: 10,
      pointsStatus: 'pending',
    });
    this.seed.pointsLedger.unshift({
      id: `pts_${ulid().toLowerCase()}`,
      userId,
      reason: 'new_listing_submission',
      pointsDelta: 10,
      status: 'pending',
      createdAt: new Date().toISOString(),
    });
    this.pushNotification(userId, {
      kind: 'contribution_resolved',
      title: 'Contribution submitted',
      body: `${payload.title} is now in the moderation queue.`,
      deepLink: '/post',
    });
    await this.events.append({
      type: eventTypes.contributionSubmitted,
      occurredAt: new Date().toISOString(),
      aggregateType: 'contribution',
      aggregateId: contributionId,
      payload,
    });

    const duplicateCandidateIds = this.seed.venues
      .filter((venue) => venue.name.toLowerCase().includes(payload.venueName.toLowerCase()) || venue.neighborhood === payload.neighborhood)
      .map((venue) => venue.id)
      .slice(0, 3);

    return { contributionId, duplicateCandidateIds };
  }

  async updateContribution(userId: string, payload: ContributionUpdate): Promise<{ contributionId: string }> {
    const contributionId = ulid();
    const listing = this.getRequiredListing(payload.listingId);
    this.seed.contributions.unshift({
      id: contributionId,
      listingId: payload.listingId,
      userId,
      type: 'listing_update',
      status: 'submitted',
      createdAt: new Date().toISOString(),
      summary: payload.title ?? payload.scheduleSummary ?? 'Listing update submitted',
      neighborhood: listing.neighborhood,
      pointsDelta: 6,
      pointsStatus: 'pending',
    });
    this.seed.pointsLedger.unshift({
      id: `pts_${ulid().toLowerCase()}`,
      userId,
      reason: 'listing_update_submission',
      pointsDelta: 6,
      status: 'pending',
      createdAt: new Date().toISOString(),
    });
    await this.events.append({
      type: eventTypes.contributionSubmitted,
      occurredAt: new Date().toISOString(),
      aggregateType: 'contribution',
      aggregateId: contributionId,
      payload,
    });
    return { contributionId };
  }

  async confirmListing(userId: string, listingId: string): Promise<{ confidenceScore: number; trustBand: string }> {
    const listing = this.getRequiredListing(listingId);
    listing.recentConfirmations += 1;
    listing.lastVerifiedAt = new Date().toISOString();
    const confidence = computeConfidence({
      sourceType: listing.sourceType,
      recentConfirmations: listing.recentConfirmations,
      recentReports: listing.negativeSignals,
      contributorTrustScore: this.getProfile(userId).verifiedContributor ? 0.8 : 0.45,
      proofCount: listing.proofCount,
      hoursSinceLastVerified: 1,
    });
    listing.confidenceScore = confidence.confidenceScore;
    listing.trustBand = confidence.trustBand;
    listing.freshnessText = `${listing.recentConfirmations} recent confirmations`;
    this.seed.contributions.unshift({
      id: `con_${ulid().toLowerCase()}`,
      listingId,
      userId,
      type: 'confirm_valid',
      status: 'approved',
      createdAt: new Date().toISOString(),
      summary: `Confirmed ${listing.title} is still active.`,
      neighborhood: listing.neighborhood,
      pointsDelta: 12,
      pointsStatus: 'finalized',
    });
    this.seed.pointsLedger.unshift({
      id: `pts_${ulid().toLowerCase()}`,
      userId,
      reason: 'confirmation_approved',
      pointsDelta: 12,
      status: 'finalized',
      createdAt: new Date().toISOString(),
    });
    this.pushNotification(userId, {
      kind: 'points_finalized',
      title: '12 points added',
      body: `Your confirmation on ${listing.venueName} increased trust and finalized immediately.`,
      deepLink: '/karma',
    });
    await this.events.append({
      type: eventTypes.verificationRecorded,
      occurredAt: new Date().toISOString(),
      aggregateType: 'listing',
      aggregateId: listingId,
      payload: { userId, listingId },
    });
    return { confidenceScore: listing.confidenceScore, trustBand: listing.trustBand };
  }

  async reportExpired(userId: string, listingId: string, payload: ReportExpired): Promise<{ reportId: string }> {
    const reportId = ulid();
    const listing = this.getRequiredListing(listingId);
    listing.negativeSignals += 1;
    if (listing.negativeSignals >= 2) {
      listing.trustBand = 'disputed';
    } else {
      listing.trustBand = 'needs_recheck';
    }
    this.seed.reports.unshift({
      id: reportId,
      listingId,
      userId,
      reason: payload.reason,
      createdAt: new Date().toISOString(),
      status: 'open',
    });
    this.seed.contributions.unshift({
      id: `con_${ulid().toLowerCase()}`,
      listingId,
      userId,
      type: 'report_expired',
      status: 'under_review',
      createdAt: new Date().toISOString(),
      summary: payload.notes ?? `Reported ${listing.title} as expired.`,
      neighborhood: listing.neighborhood,
      pointsDelta: 4,
      pointsStatus: 'pending',
    });
    this.seed.pointsLedger.unshift({
      id: `pts_${ulid().toLowerCase()}`,
      userId,
      reason: 'report_submitted',
      pointsDelta: 4,
      status: 'pending',
      createdAt: new Date().toISOString(),
    });
    this.pushNotification(userId, {
      kind: 'listing_reported_stale',
      title: 'Report submitted',
      body: `We queued your stale report for ${listing.venueName}.`,
      deepLink: '/post',
    });
    await this.events.append({
      type: 'report.created',
      occurredAt: new Date().toISOString(),
      aggregateType: 'report',
      aggregateId: reportId,
      payload: { listingId, ...payload },
    });
    return { reportId };
  }

  async presignProofUpload(userId: string, contentType: string): Promise<{ assetKey: string; uploadUrl: string }> {
    const assetKey = `proofs/${userId}/${ulid()}.${contentType.includes('png') ? 'png' : 'jpg'}`;
    return {
      assetKey,
      uploadUrl: `https://uploads.dealdrop.local/${assetKey}?signature=local-dev-placeholder`,
    };
  }

  registerDevice(userId: string, payload: DeviceRegistration): DeviceRegistration {
    this.seed.deviceRegistrations = this.seed.deviceRegistrations.filter((registration) => registration.deviceId !== payload.deviceId);
    this.seed.deviceRegistrations.unshift({ userId, ...payload });
    return payload;
  }

  unregisterDevice(userId: string, deviceId: string): void {
    this.seed.deviceRegistrations = this.seed.deviceRegistrations.filter(
      (registration) => !(registration.userId === userId && registration.deviceId === deviceId),
    );
  }

  trackTelemetry(events: TelemetryEvent[]): { accepted: number } {
    this.seed.telemetryEvents.push(
      ...events.map((event) => ({
        name: event.name,
        screen: event.screen,
        happenedAt: event.happenedAt,
        properties: event.properties,
      })),
    );
    return { accepted: events.length };
  }

  getAdminMetrics(): {
    openContributionCount: number;
    openReportCount: number;
    staleListingCount: number;
    highRiskListings: ListingCard[];
  } {
    return {
      openContributionCount: this.seed.contributions.filter((item) => item.status === 'submitted' || item.status === 'under_review').length,
      openReportCount: this.seed.reports.filter((report) => report.status === 'open').length,
      staleListingCount: this.seed.listings.filter((listing) => listing.status === 'stale' || listing.trustBand === 'disputed').length,
      highRiskListings: this.seed.listings
        .filter((listing) => listing.trustBand === 'needs_recheck' || listing.trustBand === 'disputed' || listing.confidenceScore < 0.55)
        .map((listing) => this.toListingCard(listing)),
    };
  }

  getModerationQueue(): AdminQueueItem[] {
    return this.seed.adminQueues.filter((item) => item.type === 'contribution');
  }

  getReportsQueue(): AdminQueueItem[] {
    return this.seed.adminQueues.filter((item) => item.type === 'report');
  }

  getStaleQueue(): AdminQueueItem[] {
    return this.seed.adminQueues.filter((item) => item.type === 'stale_listing');
  }

  getContributorReview(userId: string): { profile: Profile; recentContributions: LaunchSeedDataset['contributions']; trustScore: number } {
    const profile = this.getProfile(userId);
    return {
      profile,
      recentContributions: this.seed.contributions.filter((contribution) => contribution.userId === userId),
      trustScore: profile.verifiedContributor ? 0.83 : 0.42,
    };
  }

  async listEvents() {
    return this.events.list();
  }

  listAdminVenues(): VenueDetail[] {
    return this.seed.venues;
  }

  listAdminListings(): ListingDetail[] {
    return this.seed.listings.map((listing) => this.toListingDetail(listing));
  }

  upsertVenue(input: {
    id?: string;
    name: string;
    neighborhood: string;
    address: string;
    latitude: number;
    longitude: number;
  }): VenueDetail {
    const existing = input.id ? this.seed.venues.find((venue) => venue.id === input.id) : undefined;
    if (existing) {
      existing.name = input.name;
      existing.neighborhood = input.neighborhood;
      existing.address = input.address;
      existing.latitude = input.latitude;
      existing.longitude = input.longitude;
      return existing;
    }

    const venue: VenueDetail = {
      id: input.id ?? `ven_${ulid().toLowerCase()}`,
      name: input.name,
      neighborhood: input.neighborhood,
      address: input.address,
      latitude: input.latitude,
      longitude: input.longitude,
      rating: 0,
      listingIds: [],
      tags: [],
      activeListingCount: 0,
    };
    this.seed.venues.unshift({ ...venue, slug: slugify(input.name) });
    return venue;
  }

  upsertListing(input: Partial<ListingDetail> & { title: string; venueId: string; neighborhood: string }): ListingDetail {
    const existing = input.id ? this.seed.listings.find((listing) => listing.id === input.id) : undefined;
    if (existing) {
      existing.title = input.title;
      existing.description = input.description ?? existing.description;
      existing.conditions = input.conditions ?? existing.conditions;
      existing.categoryLabel = input.categoryLabel ?? existing.categoryLabel;
      existing.scheduleLabel = input.scheduleLabel ?? existing.scheduleLabel;
      existing.neighborhood = input.neighborhood;
      existing.latitude = input.latitude ?? existing.latitude;
      existing.longitude = input.longitude ?? existing.longitude;
      existing.confidenceScore = input.confidenceScore ?? existing.confidenceScore;
      existing.trustBand = input.trustBand ?? existing.trustBand;
      return this.toListingDetail(existing);
    }

    const venue = this.getVenueDetail(input.venueId);
    const listing: LaunchSeedDataset['listings'][number] = {
      id: input.id ?? `lst_${ulid().toLowerCase()}`,
      slug: slugify(input.title),
      venueId: input.venueId,
      venueName: venue?.name ?? 'Unknown venue',
      title: input.title,
      neighborhood: input.neighborhood,
      categoryLabel: input.categoryLabel ?? 'Fresh find',
      scheduleLabel: input.scheduleLabel ?? 'Pending schedule',
      trustBand: input.trustBand ?? 'recently_updated',
      freshnessText: input.freshnessText ?? 'Pending review',
      valueNote: input.valueNote ?? 'Draft listing pending moderation.',
      distanceMiles: input.distanceMiles ?? 0,
      rating: input.rating ?? 0,
      cuisine: input.cuisine ?? 'Unknown',
      latitude: input.latitude ?? venue?.latitude ?? 33.776,
      longitude: input.longitude ?? venue?.longitude ?? -84.389,
      tags: input.tags ?? [],
      venueAddress: input.venueAddress ?? venue?.address ?? '',
      description: input.description ?? '',
      conditions: input.conditions ?? '',
      sourceNote: input.sourceNote ?? 'Admin-created listing',
      offers: input.offers ?? [],
      confidenceScore: input.confidenceScore ?? 0.55,
      freshUntilAt: input.freshUntilAt ?? new Date(Date.now() + 6 * 60 * 60 * 1000).toISOString(),
      recheckAfterAt: input.recheckAfterAt ?? new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString(),
      proofCount: input.proofCount ?? 0,
      status: 'active',
      liveCategory: 'nearby',
      proofAssetKeys: [],
      recentConfirmations: 0,
      negativeSignals: 0,
      sourceType: 'moderator',
      lastVerifiedAt: new Date().toISOString(),
    };
    this.seed.listings.unshift(listing);
    return this.toListingDetail(listing);
  }

  private async getListingCollection(
    liveCategory: LaunchSeedDataset['listings'][number]['liveCategory'],
    latitude?: number,
    longitude?: number,
    cursor?: string,
    limit = 20,
    ttlSeconds = 90,
    userId?: string,
  ): Promise<{ items: ListingCard[]; nextCursor: string | null }> {
    const cacheKey = buildCacheKey(`listing-collection-${liveCategory}`, latitude, longitude, cursor, limit, userId);
    const cached = await this.cache.get<{ items: ListingCard[]; nextCursor: string | null }>(cacheKey);
    if (cached) {
      return cached;
    }

    const sorted = this.sortListingsByDistance(
      this.visibleListings().filter((listing) => listing.liveCategory === liveCategory),
      latitude,
      longitude,
    );
    const page = applyCursorPagination(sorted, cursor, limit);
    const response = { items: page.items.map((listing) => this.toListingCard(listing, userId)), nextCursor: page.nextCursor };
    await this.cache.set(cacheKey, response, ttlSeconds);
    return response;
  }

  private buildFeedSection(
    id: string,
    title: string,
    subtitle: string,
    source: LaunchSeedDataset['listings'],
    userId: string | undefined,
    predicate: (listing: LaunchSeedDataset['listings'][number]) => boolean,
  ) {
    return {
      id,
      title,
      subtitle,
      items: source.filter(predicate).slice(0, 6).map((listing) => this.toListingCard(listing, userId)),
    };
  }

  private sortListingsByDistance(listings: LaunchSeedDataset['listings'], latitude?: number, longitude?: number): LaunchSeedDataset['listings'] {
    if (latitude === undefined || longitude === undefined) {
      return [...listings].sort((left, right) => left.neighborhood.localeCompare(right.neighborhood));
    }

    return [...listings].sort((left, right) => {
      const leftDistance = haversineDistanceMiles(latitude, longitude, left.latitude, left.longitude);
      const rightDistance = haversineDistanceMiles(latitude, longitude, right.latitude, right.longitude);
      return leftDistance - rightDistance || right.confidenceScore - left.confidenceScore;
    });
  }

  private getRequiredListing(listingId: string) {
    const listing = this.seed.listings.find((candidate) => candidate.id === listingId);
    if (!listing) {
      throw new Error(`Listing ${listingId} not found`);
    }
    return listing;
  }

  private visibleListings() {
    return this.seed.listings.filter((listing) => listing.status !== 'suppressed');
  }

  private favoriteIdsFor(userId?: string) {
    return new Set(userId ? this.seed.favoriteIdsByUser[userId] ?? [] : []);
  }

  private toListingCard(listing: LaunchSeedDataset['listings'][number], userId?: string): ListingCard {
    return {
      id: listing.id,
      venueId: listing.venueId,
      venueName: listing.venueName,
      title: listing.title,
      neighborhood: listing.neighborhood,
      categoryLabel: listing.categoryLabel,
      scheduleLabel: listing.scheduleLabel,
      trustBand: listing.trustBand,
      freshnessText: listing.freshnessText,
      valueNote: listing.valueNote,
      affordabilityLabel: this.affordabilityLabel(listing),
      distanceMiles: listing.distanceMiles,
      rating: listing.rating,
      cuisine: listing.cuisine,
      latitude: listing.latitude,
      longitude: listing.longitude,
      confidenceScore: listing.confidenceScore,
      lastUpdatedAt: listing.lastVerifiedAt,
      tags: listing.tags,
      saved: this.favoriteIdsFor(userId).has(listing.id),
    };
  }

  private toListingDetail(listing: LaunchSeedDataset['listings'][number], userId?: string): ListingDetail {
    return {
      ...this.toListingCard(listing, userId),
      venueAddress: listing.venueAddress,
      description: listing.description,
      conditions: listing.conditions,
      sourceNote: listing.sourceNote,
      offers: listing.offers,
      freshUntilAt: listing.freshUntilAt,
      recheckAfterAt: listing.recheckAfterAt,
      proofCount: listing.proofCount,
      trustSummary: {
        band: listing.trustBand,
        explanation: this.describeTrust(listing),
        confidenceScore: listing.confidenceScore,
        freshUntilAt: listing.freshUntilAt,
        recheckAfterAt: listing.recheckAfterAt,
        proofCount: listing.proofCount,
        recentConfirmations: listing.recentConfirmations,
        disputeCount: listing.negativeSignals,
      },
    };
  }

  private toContributionRecord(contribution: LaunchSeedDataset['contributions'][number]): ContributionRecord {
    const listing = this.seed.listings.find((candidate) => candidate.id === contribution.listingId);
    return {
      id: contribution.id,
      listingId: contribution.listingId,
      listingTitle: listing?.title ?? 'Pending listing',
      venueName: listing?.venueName ?? contribution.summary,
      neighborhood: contribution.neighborhood,
      type: contribution.type,
      status: contribution.status,
      createdAt: contribution.createdAt,
      summary: contribution.summary,
      pointsDelta: contribution.pointsDelta ?? 0,
      pointsStatus: contribution.pointsStatus ?? 'pending',
    };
  }

  private describeTrust(listing: LaunchSeedDataset['listings'][number]): string {
    switch (listing.trustBand) {
      case 'founder_verified':
        return 'Verified directly by the founding team with recent source evidence.';
      case 'merchant_confirmed':
        return 'Confirmed by venue staff and backed by recent merchant-supplied details.';
      case 'user_confirmed':
        return 'Backed by multiple strong community confirmations.';
      case 'recently_updated':
        return 'Fresh enough to be useful, but still benefits from new confirmations.';
      case 'needs_recheck':
        return 'Confidence is slipping and this listing should be treated cautiously.';
      case 'disputed':
        return 'Recent reports conflict with the latest known details.';
    }
  }

  private affordabilityLabel(listing: LaunchSeedDataset['listings'][number]): string {
    const cheapest = listing.offers.reduce((value, offer) => Math.min(value, offer.dealPrice), Number.POSITIVE_INFINITY);
    if (cheapest <= 5) {
      return 'Under $5';
    }
    if (cheapest <= 10) {
      return 'Under $10';
    }
    if (cheapest <= 15) {
      return 'Under $15';
    }
    return '$15+';
  }

  private buildSuggestions(query: string): string[] {
    if (!query) {
      return [];
    }
    const suggestionPool = [
      ...this.seed.listings.map((listing) => listing.venueName),
      ...this.seed.listings.map((listing) => listing.title),
      ...this.seed.venues.map((venue) => venue.neighborhood),
    ];
    return [...new Set(suggestionPool.filter((value) => value.toLowerCase().includes(query)).slice(0, 6))];
  }

  private pushNotification(
    userId: string,
    input: {
      kind: NotificationRecord['kind'];
      title: string;
      body: string;
      deepLink?: string;
    },
  ) {
    const notification: NotificationRecord = {
      id: `ntf_${ulid().toLowerCase()}`,
      kind: input.kind,
      title: input.title,
      body: input.body,
      createdAt: new Date().toISOString(),
      readAt: null,
      deepLink: input.deepLink ?? null,
    };
    this.seed.notificationsByUser[userId] ??= [];
    this.seed.notificationsByUser[userId].unshift(notification);
  }

  private async invalidateUserReadCaches(): Promise<void> {
    await this.cache.invalidatePrefix('dealdrop:v1:feed-home');
    await this.cache.invalidatePrefix('dealdrop:v1:nearby');
    await this.cache.invalidatePrefix('dealdrop:v1:search');
    await this.cache.invalidatePrefix('dealdrop:v1:map-bounds');
    await this.cache.invalidatePrefix('dealdrop:v1:live-now');
    await this.cache.invalidatePrefix('dealdrop:v1:tonight');
  }
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}
