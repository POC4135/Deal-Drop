import { buildCacheKey, cacheTtls, eventTypes } from '@dealdrop/config';
import type {
  AdminQueueItem,
  AuthBootstrap,
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

import { getPool } from '../db/pool.js';
import { InMemoryCacheStore, type CacheStore } from '../lib/cache.js';
import { haversineDistanceMiles } from '../lib/geo.js';
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

type ListingRow = {
  id: string;
  venue_id: string;
  venue_name: string;
  venue_address: string;
  neighborhood: string;
  title: string;
  description: string;
  category_label: string;
  schedule_summary: string;
  conditions: string;
  source_note: string;
  cuisine: string;
  trust_band: ListingCard['trustBand'];
  confidence_score: number;
  fresh_until_at: Date | null;
  recheck_after_at: Date | null;
  last_verified_at: Date | null;
  latitude: number;
  longitude: number;
  rating: number;
  proof_count: number;
  recent_confirmations: number;
  negative_signals: number;
  tags: string[];
  offers: Array<{ id: string; title: string; originalPrice: number; dealPrice: number; currency: string }>;
};

type AuthContext = {
  userId: string;
  email: string;
  role: Profile['role'];
  displayName: string;
  verifiedContributor: boolean;
};

type SignedUpload = {
  uploadUrl: string;
  path: string;
  token?: string;
};

type SupabaseSignedUploadResponse = {
  signedURL?: string;
  signedUrl?: string;
  path?: string;
  token?: string;
};

export class PostgresDealDropPlatform {
  constructor(private readonly cache: CacheStore = new InMemoryCacheStore()) {}

  async authenticate(): Promise<AuthResponse> {
    throw new Error('password_auth_disabled');
  }

  async bootstrapAuthenticatedUser(auth: AuthContext, input: AuthBootstrap): Promise<AuthResponse> {
    const displayName = input.displayName?.trim() || auth.displayName || auth.email.split('@')[0] || 'DealDrop User';
    const homeNeighborhood = input.homeNeighborhood || 'Midtown';
    await getPool().query(
      `
        insert into users (id, email, role)
        values ($1, $2, $3)
        on conflict (id) do update set email = excluded.email, updated_at = now()
      `,
      [auth.userId, auth.email, auth.role],
    );
    await getPool().query(
      `
        insert into user_profiles (user_id, display_name, home_neighborhood, verified_contributor)
        values ($1, $2, $3, $4)
        on conflict (user_id) do update set
          display_name = excluded.display_name,
          home_neighborhood = excluded.home_neighborhood,
          updated_at = now()
      `,
      [auth.userId, displayName, homeNeighborhood, auth.verifiedContributor],
    );
    await getPool().query(
      `
        insert into notification_preferences (user_id)
        values ($1)
        on conflict (user_id) do nothing
      `,
      [auth.userId],
    );
    return {
      session: {
        userId: auth.userId,
        email: auth.email,
        displayName,
        role: auth.role,
        verifiedContributor: auth.verifiedContributor,
      },
      profile: await this.getProfile(auth.userId),
    };
  }

  async getFiltersMetadata(): Promise<FiltersMetadata> {
    const result = await getPool().query<{
      neighborhoods: string[];
      cuisines: string[];
      tags: string[];
    }>(`
      select
        coalesce(array_agg(distinct vl.neighborhood_name) filter (where vl.neighborhood_name is not null), '{}') as neighborhoods,
        coalesce(array_agg(distinct l.cuisine) filter (where l.cuisine is not null), '{}') as cuisines,
        coalesce(array_agg(distinct lt.tag) filter (where lt.tag is not null), '{}') as tags
      from listings l
      join venues v on v.id = l.venue_id
      join venue_locations vl on vl.venue_id = v.id
      left join listing_tags lt on lt.listing_id = l.id
      where l.status = 'active' and l.visibility_state = 'visible'
    `);
    return {
      neighborhoods: result.rows[0]?.neighborhoods ?? [],
      cuisines: result.rows[0]?.cuisines ?? [],
      tags: result.rows[0]?.tags ?? [],
      trustBands: ['founder_verified', 'merchant_confirmed', 'user_confirmed', 'recently_updated', 'needs_recheck', 'disputed'],
    };
  }

  async getProfile(userId: string): Promise<Profile> {
    const result = await getPool().query<{
      id: string;
      email: string;
      role: Profile['role'];
      display_name: string;
      home_neighborhood: string;
      verified_contributor: boolean;
    }>(
      `
        select u.id, u.email, u.role, p.display_name, p.home_neighborhood, p.verified_contributor
        from users u
        join user_profiles p on p.user_id = u.id
        where u.id = $1
      `,
      [userId],
    );
    const row = result.rows[0];
    if (!row) {
      throw Object.assign(new Error('profile_not_found'), { statusCode: 404 });
    }
    return {
      id: row.id,
      email: row.email,
      role: row.role,
      displayName: row.display_name,
      homeNeighborhood: row.home_neighborhood,
      verifiedContributor: row.verified_contributor,
    };
  }

  async getPreferences(userId: string): Promise<UserPreferences> {
    const result = await getPool().query<{
      contribution_resolved: boolean;
      points_finalized: boolean;
      trust_status_changed: boolean;
      marketing_announcements: boolean;
    }>(
      `
        select contribution_resolved, points_finalized, trust_status_changed, marketing_announcements
        from notification_preferences
        where user_id = $1
      `,
      [userId],
    );
    const row = result.rows[0];
    return {
      contributionResolved: row?.contribution_resolved ?? true,
      pointsFinalized: row?.points_finalized ?? true,
      trustStatusChanged: row?.trust_status_changed ?? true,
      marketingAnnouncements: row?.marketing_announcements ?? false,
    };
  }

  async updatePreferences(userId: string, input: UserPreferences): Promise<UserPreferences> {
    await getPool().query(
      `
        insert into notification_preferences (
          user_id, contribution_resolved, points_finalized, trust_status_changed, marketing_announcements, updated_at
        )
        values ($1, $2, $3, $4, $5, now())
        on conflict (user_id) do update set
          contribution_resolved = excluded.contribution_resolved,
          points_finalized = excluded.points_finalized,
          trust_status_changed = excluded.trust_status_changed,
          marketing_announcements = excluded.marketing_announcements,
          updated_at = now()
      `,
      [userId, input.contributionResolved, input.pointsFinalized, input.trustStatusChanged, input.marketingAnnouncements],
    );
    return input;
  }

  async getNotifications(userId: string): Promise<NotificationsResponse> {
    const result = await getPool().query<{
      id: string;
      kind: NotificationRecord['kind'];
      title: string;
      body: string;
      created_at: Date;
      read_at: Date | null;
      deep_link: string | null;
    }>(
      `
        select id, kind, title, body, created_at, read_at, deep_link
        from notifications
        where user_id = $1
        order by created_at desc
        limit 100
      `,
      [userId],
    );
    const items = result.rows.map((row) => ({
      id: row.id,
      kind: row.kind,
      title: row.title,
      body: row.body,
      createdAt: row.created_at.toISOString(),
      readAt: row.read_at?.toISOString() ?? null,
      deepLink: row.deep_link,
    }));
    return { items, unreadCount: items.filter((item) => !item.readAt).length };
  }

  async markNotificationRead(userId: string, notificationId: string): Promise<NotificationRecord | undefined> {
    const result = await getPool().query<{
      id: string;
      kind: NotificationRecord['kind'];
      title: string;
      body: string;
      created_at: Date;
      read_at: Date;
      deep_link: string | null;
    }>(
      `
        update notifications
        set read_at = coalesce(read_at, now())
        where user_id = $1 and id = $2
        returning id, kind, title, body, created_at, read_at, deep_link
      `,
      [userId, notificationId],
    );
    const row = result.rows[0];
    return row
      ? {
          id: row.id,
          kind: row.kind,
          title: row.title,
          body: row.body,
          createdAt: row.created_at.toISOString(),
          readAt: row.read_at.toISOString(),
          deepLink: row.deep_link,
        }
      : undefined;
  }

  async getContributionHistory(userId: string): Promise<ContributionHistoryResponse> {
    const result = await getPool().query<{
      id: string;
      listing_id: string | null;
      listing_title: string | null;
      venue_name: string | null;
      neighborhood: string | null;
      type: ContributionRecord['type'];
      status: ContributionRecord['status'];
      created_at: Date;
      title: string | null;
      points_delta: number | null;
      points_status: ContributionRecord['pointsStatus'] | null;
    }>(
      `
        select c.id, c.listing_id, l.title as listing_title, v.name as venue_name, c.neighborhood, c.type, c.status,
          c.created_at, c.title, pl.points_delta, pl.status as points_status
        from contributions c
        left join listings l on l.id = c.listing_id
        left join venues v on v.id = l.venue_id
        left join points_ledger pl on pl.contribution_id = c.id
        where c.user_id = $1
        order by c.created_at desc
      `,
      [userId],
    );
    return {
      items: result.rows.map((row) => ({
        id: row.id,
        listingId: row.listing_id ?? 'pending',
        listingTitle: row.listing_title ?? 'Pending listing',
        venueName: row.venue_name ?? row.title ?? 'Pending venue',
        neighborhood: row.neighborhood ?? 'Unknown',
        type: row.type,
        status: row.status,
        createdAt: row.created_at.toISOString(),
        summary: row.title ?? row.listing_title ?? 'Contribution submitted',
        pointsDelta: row.points_delta ?? 0,
        pointsStatus: row.points_status ?? 'pending',
      })),
    };
  }

  async getSavedListings(userId: string): Promise<ListingCard[]> {
    const listings = await this.listListingRows({ userId, onlyFavorites: true });
    return listings.map((listing) => this.toListingCard(listing, userId));
  }

  async getListingDetail(listingId: string, userId?: string): Promise<ListingDetail | undefined> {
    const listings = await this.listListingRows({ userId, listingId });
    return listings[0] ? this.toListingDetail(listings[0], userId) : undefined;
  }

  async getVenueDetail(venueId: string): Promise<VenueDetail | undefined> {
    const result = await getPool().query<{
      id: string;
      name: string;
      neighborhood_name: string;
      address: string;
      latitude: number;
      longitude: number;
      rating: number;
      listing_ids: string[];
      tags: string[];
      active_listing_count: number;
    }>(
      `
        select v.id, v.name, vl.neighborhood_name, vl.address, vl.latitude, vl.longitude, v.rating,
          coalesce(array_agg(distinct l.id) filter (where l.id is not null), '{}') as listing_ids,
          coalesce(array_agg(distinct lt.tag) filter (where lt.tag is not null), '{}') as tags,
          count(distinct l.id)::int as active_listing_count
        from venues v
        join venue_locations vl on vl.venue_id = v.id
        left join listings l on l.venue_id = v.id and l.status = 'active'
        left join listing_tags lt on lt.listing_id = l.id
        where v.id = $1
        group by v.id, v.name, vl.neighborhood_name, vl.address, vl.latitude, vl.longitude, v.rating
      `,
      [venueId],
    );
    const row = result.rows[0];
    return row
      ? {
          id: row.id,
          name: row.name,
          neighborhood: row.neighborhood_name,
          address: row.address,
          latitude: Number(row.latitude),
          longitude: Number(row.longitude),
          rating: Number(row.rating),
          listingIds: row.listing_ids,
          tags: row.tags,
          activeListingCount: row.active_listing_count,
        }
      : undefined;
  }

  async getFeedHome(query: FeedQuery, userId?: string): Promise<FeedResponse> {
    const cacheKey = buildCacheKey('pg-feed-home', query.latitude, query.longitude, query.limit, query.cursor, userId);
    const cached = await this.cache.get<FeedResponse>(cacheKey);
    if (cached) return cached;
    const rows = this.sortListingsByDistance(await this.listListingRows({ userId }), query.latitude, query.longitude);
    const page = applyCursorPagination(rows, query.cursor, query.limit);
    const response = {
      sections: [
        this.buildFeedSection('live-now', 'Live now', 'Fresh, high-confidence finds around you', page.items, userId),
        this.buildFeedSection('tonight', 'Tonight', 'Dinner, happy-hour, and late-evening value', page.items, userId),
        this.buildFeedSection('cheap-eats', 'Cheap eats', 'Under-$10 plays near campus and commuter traffic', page.items, userId),
        this.buildFeedSection('fresh-this-week', 'Fresh this week', 'Listings that were verified recently enough to move fast', page.items, userId),
      ],
      nextCursor: page.nextCursor,
    };
    await this.cache.set(cacheKey, response, cacheTtls.feedHomeSeconds);
    return response;
  }

  async getLiveNow(latitude?: number, longitude?: number, cursor?: string, limit = 20, userId?: string) {
    const rows = this.sortListingsByDistance(await this.listListingRows({ userId }), latitude, longitude);
    const page = applyCursorPagination(rows, cursor, limit);
    return { items: page.items.map((listing) => this.toListingCard(listing, userId)), nextCursor: page.nextCursor };
  }

  async getTonight(latitude?: number, longitude?: number, cursor?: string, limit = 20, userId?: string) {
    return this.getLiveNow(latitude, longitude, cursor, limit, userId);
  }

  async getNearby(query: NearbyQuery, userId?: string) {
    const rows = this.sortListingsByDistance(await this.listListingRows({ userId }), query.latitude, query.longitude).filter((listing) =>
      query.latitude === undefined || query.longitude === undefined
        ? true
        : haversineDistanceMiles(query.latitude, query.longitude, listing.latitude, listing.longitude) <= query.radiusMiles,
    );
    const page = applyCursorPagination(rows, query.cursor, query.limit);
    return { items: page.items.map((listing) => this.toListingCard(listing, userId)), nextCursor: page.nextCursor };
  }

  async getMapBounds(query: MapBoundsQuery, userId?: string): Promise<MapListing[]> {
    const rows = await this.listListingRows({ userId });
    return rows
      .filter((listing) => listing.latitude <= query.north && listing.latitude >= query.south && listing.longitude <= query.east && listing.longitude >= query.west)
      .filter((listing) => (query.trustBand ? listing.trust_band === query.trustBand : true))
      .map((listing) => ({
        listingId: listing.id,
        venueId: listing.venue_id,
        venueName: listing.venue_name,
        latitude: listing.latitude,
        longitude: listing.longitude,
        trustBand: listing.trust_band,
        title: listing.title,
        neighborhood: listing.neighborhood,
        confidenceScore: listing.confidence_score,
        affordabilityLabel: this.affordabilityLabel(listing),
        saved: false,
      }));
  }

  async search(query: { q?: string; neighborhood?: string; cursor?: string; limit: number; trustBand?: string; sort?: string }, userId?: string): Promise<SearchResult> {
    const normalized = (query.q ?? '').trim().toLowerCase();
    let rows = (await this.listListingRows({ userId })).filter((listing) => {
      const haystack = [listing.title, listing.venue_name, listing.neighborhood, listing.cuisine, ...listing.tags].join(' ').toLowerCase();
      return (!normalized || haystack.includes(normalized)) && (!query.neighborhood || listing.neighborhood === query.neighborhood) && (!query.trustBand || listing.trust_band === query.trustBand);
    });
    if (query.sort === 'confidence') rows = rows.sort((a, b) => b.confidence_score - a.confidence_score);
    const page = applyCursorPagination(rows, query.cursor, query.limit);
    const venueIds = [...new Set(page.items.map((listing) => listing.venue_id))];
    const venues = (await Promise.all(venueIds.map((id) => this.getVenueDetail(id)))).filter((venue): venue is VenueDetail => Boolean(venue));
    return {
      listings: page.items.map((listing) => this.toListingCard(listing, userId)),
      venues,
      neighborhoods: [...new Set(page.items.map((listing) => listing.neighborhood))],
      suggestions: normalized ? [...new Set(rows.flatMap((listing) => [listing.venue_name, listing.title]).filter((value) => value.toLowerCase().includes(normalized)).slice(0, 6))] : [],
      nextCursor: page.nextCursor,
    };
  }

  async getKarma(userId: string, window: LeaderboardWindow = 'weekly'): Promise<KarmaSummary> {
    const entries = await this.getLedgerEntries();
    const users = await this.getLeaderboardUsers();
    return buildKarmaSummary({ userId, entries, users, activityDates: entries.filter((entry) => entry.userId === userId).map((entry) => entry.createdAt), badges: [], window });
  }

  async getLeaderboard(window: LeaderboardWindow = 'weekly'): Promise<LeaderboardEntry[]> {
    return computeLeaderboard(await this.getLedgerEntries(), await this.getLeaderboardUsers(), window);
  }

  async addFavorite(userId: string, listingId: string): Promise<void> {
    await getPool().query('insert into favorites (user_id, listing_id) values ($1, $2) on conflict do nothing', [userId, listingId]);
    await this.appendOutbox('favorite.created', 'listing', listingId, { userId, listingId });
  }

  async removeFavorite(userId: string, listingId: string): Promise<void> {
    await getPool().query('delete from favorites where user_id = $1 and listing_id = $2', [userId, listingId]);
    await this.appendOutbox('favorite.deleted', 'listing', listingId, { userId, listingId });
  }

  async syncFavorites(userId: string, listingIds: string[]): Promise<ListingCard[]> {
    for (const listingId of [...new Set(listingIds)]) {
      await this.addFavorite(userId, listingId);
    }
    return this.getSavedListings(userId);
  }

  async createContribution(userId: string, payload: ContributionCreate): Promise<{ contributionId: string; duplicateCandidateIds: string[] }> {
    const contributionId = `con_${ulid().toLowerCase()}`;
    await getPool().query(
      `
        insert into contributions (
          id, user_id, type, status, title, description, schedule_summary,
          neighborhood, latitude, longitude, payload, google_place_id, google_place_payload
        )
        values ($1, $2, 'new_listing', 'submitted', $3, $4, $5, $6, $7, $8, $9, $10, $11)
      `,
      [
        contributionId,
        userId,
        payload.title,
        payload.description,
        payload.scheduleSummary,
        payload.neighborhood,
        payload.latitude,
        payload.longitude,
        payload,
        payload.googlePlace?.placeId ?? null,
        payload.googlePlace ?? {},
      ],
    );
    await this.addLedger(userId, contributionId, 'new_listing_submission', 10, 'pending');
    await this.pushNotification(userId, 'contribution_resolved', 'Contribution submitted', `${payload.title} is now in the moderation queue.`, '/post');
    await this.appendOutbox(eventTypes.contributionSubmitted, 'contribution', contributionId, payload);
    return { contributionId, duplicateCandidateIds: [] };
  }

  async updateContribution(userId: string, payload: ContributionUpdate): Promise<{ contributionId: string }> {
    const contributionId = `con_${ulid().toLowerCase()}`;
    await getPool().query(
      `
        insert into contributions (id, listing_id, user_id, type, status, title, description, schedule_summary, payload)
        values ($1, $2, $3, 'listing_update', 'submitted', $4, $5, $6, $7)
      `,
      [contributionId, payload.listingId, userId, payload.title, payload.description, payload.scheduleSummary, payload],
    );
    await this.addLedger(userId, contributionId, 'listing_update_submission', 6, 'pending');
    await this.appendOutbox(eventTypes.contributionSubmitted, 'contribution', contributionId, payload);
    return { contributionId };
  }

  async confirmListing(userId: string, listingId: string): Promise<{ confidenceScore: number; trustBand: string }> {
    const listing = (await this.listListingRows({ listingId }))[0];
    if (!listing) throw Object.assign(new Error('listing_not_found'), { statusCode: 404 });
    const confidence = computeConfidence({
      sourceType: 'user',
      recentConfirmations: listing.recent_confirmations + 1,
      recentReports: listing.negative_signals,
      contributorTrustScore: 0.5,
      proofCount: listing.proof_count,
      hoursSinceLastVerified: 1,
    });
    await getPool().query(
      'update listings set confidence_score = $1, trust_band = $2, last_verified_at = now(), updated_at = now() where id = $3',
      [confidence.confidenceScore, confidence.trustBand, listingId],
    );
    const contributionId = `con_${ulid().toLowerCase()}`;
    await getPool().query(
      "insert into contributions (id, listing_id, user_id, type, status, title, neighborhood) values ($1, $2, $3, 'confirm_valid', 'approved', $4, $5)",
      [contributionId, listingId, userId, `Confirmed ${listing.title}`, listing.neighborhood],
    );
    await this.addLedger(userId, contributionId, 'confirmation_approved', 12, 'finalized');
    await this.pushNotification(userId, 'points_finalized', '12 points added', `Your confirmation on ${listing.venue_name} increased trust.`, '/karma');
    await this.appendOutbox(eventTypes.verificationRecorded, 'listing', listingId, { userId, listingId });
    return { confidenceScore: confidence.confidenceScore, trustBand: confidence.trustBand };
  }

  async reportExpired(userId: string, listingId: string, payload: ReportExpired): Promise<{ reportId: string }> {
    const reportId = `rep_${ulid().toLowerCase()}`;
    await getPool().query(
      "insert into reports (id, listing_id, user_id, reason, notes, status) values ($1, $2, $3, $4, $5, 'open')",
      [reportId, listingId, userId, payload.reason, payload.notes],
    );
    const contributionId = `con_${ulid().toLowerCase()}`;
    await getPool().query(
      "insert into contributions (id, listing_id, user_id, type, status, title, payload) values ($1, $2, $3, 'report_expired', 'under_review', $4, $5)",
      [contributionId, listingId, userId, payload.notes ?? 'Reported expired', payload],
    );
    await getPool().query("update listings set trust_band = 'needs_recheck', updated_at = now() where id = $1 and trust_band <> 'disputed'", [listingId]);
    await this.addLedger(userId, contributionId, 'report_submitted', 4, 'pending');
    await this.pushNotification(userId, 'listing_reported_stale', 'Report submitted', 'We queued your stale report for moderator review.', '/post');
    await this.appendOutbox('report.created', 'report', reportId, { listingId, ...payload });
    return { reportId };
  }

  async presignProofUpload(userId: string, contentType: string): Promise<{ assetKey: string; uploadUrl: string; path: string; token?: string }> {
    const assetKey = `proofs/${userId}/${ulid().toLowerCase()}.${contentType.includes('png') ? 'png' : 'jpg'}`;
    const signedUpload = await this.createSignedProofUpload(assetKey);
    await getPool().query(
      "insert into contribution_proofs (id, contribution_id, asset_key, content_type, upload_url, status, metadata) values ($1, null, $2, $3, $4, 'pending_upload', $5)",
      [
        `prf_${ulid().toLowerCase()}`,
        assetKey,
        contentType,
        signedUpload.uploadUrl,
        {
          provider: process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY ? 'supabase_storage' : 'local_placeholder',
          path: signedUpload.path,
        },
      ],
    );
    return { assetKey, uploadUrl: signedUpload.uploadUrl, path: signedUpload.path, token: signedUpload.token };
  }

  private async createSignedProofUpload(assetKey: string): Promise<SignedUpload> {
    const supabaseUrl = process.env.SUPABASE_URL?.replace(/\/$/, '');
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    const bucket = process.env.SUPABASE_STORAGE_BUCKET ?? 'proofs';
    if (!supabaseUrl || !serviceRoleKey) {
      return {
        uploadUrl: `https://uploads.dealdrop.local/${assetKey}?signature=local-dev-placeholder`,
        path: assetKey,
      };
    }

    const response = await fetch(`${supabaseUrl}/storage/v1/object/upload/sign/${bucket}/${assetKey}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${serviceRoleKey}`,
        apikey: serviceRoleKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({}),
    });
    if (!response.ok) {
      throw new Error(`supabase_storage_sign_${response.status}`);
    }
    const payload = (await response.json()) as SupabaseSignedUploadResponse;
    const signedPath = payload.signedURL ?? payload.signedUrl;
    const normalizedSignedPath = signedPath?.startsWith('/object/')
      ? `/storage/v1${signedPath}`
      : signedPath?.startsWith('/')
        ? signedPath
        : signedPath
          ? `/storage/v1/${signedPath}`
          : undefined;
    const uploadUrl = signedPath?.startsWith('http')
      ? signedPath
      : normalizedSignedPath
        ? `${supabaseUrl}${normalizedSignedPath}`
        : `${supabaseUrl}/storage/v1/object/upload/sign/${bucket}/${assetKey}?token=${payload.token ?? ''}`;
    return {
      uploadUrl,
      path: payload.path ?? assetKey,
      token: payload.token,
    };
  }

  async registerDevice(userId: string, payload: DeviceRegistration): Promise<DeviceRegistration> {
    await getPool().query(
      `
        insert into device_registrations (id, user_id, platform, device_identifier, push_token, app_version, last_seen_at)
        values ($1, $2, $3, $4, $5, null, now())
        on conflict (user_id, device_identifier) do update set
          platform = excluded.platform,
          push_token = excluded.push_token,
          disabled_at = null,
          last_seen_at = now(),
          updated_at = now()
      `,
      [`dev_${ulid().toLowerCase()}`, userId, payload.platform, payload.deviceId, payload.pushToken],
    );
    return payload;
  }

  async unregisterDevice(userId: string, deviceId: string): Promise<void> {
    await getPool().query('update device_registrations set disabled_at = now(), updated_at = now() where user_id = $1 and device_identifier = $2', [userId, deviceId]);
  }

  async trackTelemetry(events: TelemetryEvent[]): Promise<{ accepted: number }> {
    for (const event of events) {
      await getPool().query(
        'insert into telemetry_events (id, event_name, event_payload, created_at) values ($1, $2, $3, $4)',
        [`tel_${ulid().toLowerCase()}`, event.name, { screen: event.screen, ...event.properties }, event.happenedAt],
      );
    }
    return { accepted: events.length };
  }

  async getAdminMetrics() {
    const result = await getPool().query<{
      open_contribution_count: number;
      open_report_count: number;
      stale_listing_count: number;
    }>(`
      select
        (select count(*)::int from contributions where status in ('submitted', 'under_review')) as open_contribution_count,
        (select count(*)::int from reports where status = 'open') as open_report_count,
        (select count(*)::int from listings where status = 'stale' or trust_band in ('needs_recheck', 'disputed')) as stale_listing_count
    `);
    return {
      openContributionCount: result.rows[0]?.open_contribution_count ?? 0,
      openReportCount: result.rows[0]?.open_report_count ?? 0,
      staleListingCount: result.rows[0]?.stale_listing_count ?? 0,
      highRiskListings: (await this.listListingRows({})).filter((listing) => listing.trust_band === 'needs_recheck' || listing.trust_band === 'disputed' || listing.confidence_score < 0.55).map((listing) => this.toListingCard(listing)),
    };
  }

  async getModerationQueue(): Promise<AdminQueueItem[]> {
    const result = await getPool().query('select id, id as entity_id, type, coalesce(title, type::text) as title, coalesce(neighborhood, $$Unknown$$) as neighborhood, status, created_at from contributions where status in ($$submitted$$, $$under_review$$) order by created_at asc limit 100');
    return result.rows.map((row) => this.toAdminQueueItem(row, 'contribution'));
  }

  async getReportsQueue(): Promise<AdminQueueItem[]> {
    const result = await getPool().query('select id, id as entity_id, $$report$$ as type, reason as title, $$Report requires review$$ as subtitle, $$Unknown$$ as neighborhood, status, created_at from reports where status = $$open$$ order by created_at asc limit 100');
    return result.rows.map((row) => this.toAdminQueueItem(row, 'report'));
  }

  async getStaleQueue(): Promise<AdminQueueItem[]> {
    const rows = (await this.listListingRows({})).filter((listing) => listing.trust_band === 'needs_recheck' || listing.trust_band === 'disputed');
    return rows.map((listing) => ({
      id: `stale_${listing.id}`,
      entityId: listing.id,
      type: 'stale_listing',
      title: listing.title,
      subtitle: `${listing.venue_name} needs freshness review.`,
      neighborhood: listing.neighborhood,
      trustBand: listing.trust_band,
      createdAt: (listing.recheck_after_at ?? new Date()).toISOString(),
      priority: listing.trust_band === 'disputed' ? 'high' : 'medium',
      status: 'due',
    }));
  }

  async getContributorReview(userId: string) {
    return {
      profile: await this.getProfile(userId),
      recentContributions: (await this.getContributionHistory(userId)).items,
      trustScore: 0.5,
    };
  }

  async listEvents() {
    const result = await getPool().query('select id, event_type as type, occurred_at, aggregate_type, aggregate_id, payload from outbox_events order by occurred_at desc limit 100');
    return result.rows.map((row) => ({
      id: row.id,
      type: row.type,
      occurredAt: row.occurred_at.toISOString(),
      aggregateType: row.aggregate_type,
      aggregateId: row.aggregate_id,
      payload: row.payload,
    }));
  }

  async listAdminVenues(): Promise<VenueDetail[]> {
    const result = await getPool().query<{ id: string }>('select id from venues order by updated_at desc');
    return (await Promise.all(result.rows.map((row) => this.getVenueDetail(row.id)))).filter((venue): venue is VenueDetail => Boolean(venue));
  }

  async listAdminListings(): Promise<ListingDetail[]> {
    return (await this.listListingRows({ includeInactive: true })).map((listing) => this.toListingDetail(listing));
  }

  async upsertVenue(input: { id?: string; name: string; neighborhood: string; address: string; latitude: number; longitude: number }): Promise<VenueDetail> {
    const id = input.id ?? `ven_${ulid().toLowerCase()}`;
    await getPool().query(
      `
        insert into venues (id, slug, name, rating, status)
        values ($1, $2, $3, 0, 'active')
        on conflict (id) do update set name = excluded.name, updated_at = now()
      `,
      [id, slugify(input.name), input.name],
    );
    await getPool().query(
      `
        insert into venue_locations (id, venue_id, neighborhood_name, neighborhood_slug, address, latitude, longitude, point)
        values ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_MakePoint($7, $6), 4326)::geography)
        on conflict (venue_id) do update set neighborhood_name = excluded.neighborhood_name, address = excluded.address, latitude = excluded.latitude, longitude = excluded.longitude, point = excluded.point
      `,
      [`loc_${id}`, id, input.neighborhood, slugify(input.neighborhood), input.address, input.latitude, input.longitude],
    );
    const venue = await this.getVenueDetail(id);
    if (!venue) throw new Error('venue_upsert_failed');
    return venue;
  }

  async upsertListing(input: Partial<ListingDetail> & { title: string; venueId: string; neighborhood: string }): Promise<ListingDetail> {
    const venue = await this.getVenueDetail(input.venueId);
    const id = input.id ?? `lst_${ulid().toLowerCase()}`;
    await getPool().query(
      `
        insert into listings (
          id, venue_id, slug, title, description, category_label, schedule_summary, conditions,
          source_note, cuisine, status, trust_band, visibility_state, confidence_score, fresh_until_at, recheck_after_at, published_at, last_verified_at
        )
        values ($1, $2, $3, $4, $5, $6, $7, $8, 'Admin-created listing', $9, 'active', $10, 'visible', $11, now() + interval '12 hours', now() + interval '24 hours', now(), now())
        on conflict (id) do update set
          title = excluded.title,
          category_label = excluded.category_label,
          schedule_summary = excluded.schedule_summary,
          cuisine = excluded.cuisine,
          confidence_score = excluded.confidence_score,
          trust_band = excluded.trust_band,
          updated_at = now()
      `,
      [
        id,
        input.venueId,
        slugify(input.title),
        input.title,
        input.description ?? input.valueNote ?? '',
        input.categoryLabel ?? 'Fresh find',
        input.scheduleLabel ?? 'Pending schedule',
        input.conditions ?? '',
        input.cuisine ?? 'Unknown',
        input.trustBand ?? 'recently_updated',
        input.confidenceScore ?? 0.55,
      ],
    );
    const listing = await this.getListingDetail(id);
    if (!listing) throw new Error(`listing_upsert_failed:${venue?.id ?? input.venueId}`);
    return listing;
  }

  private async listListingRows(filters: { userId?: string; listingId?: string; onlyFavorites?: boolean; includeInactive?: boolean }): Promise<ListingRow[]> {
    const conditions = [filters.includeInactive ? 'true' : "l.status = 'active' and l.visibility_state = 'visible'"];
    const params: unknown[] = [];
    if (filters.listingId) {
      params.push(filters.listingId);
      conditions.push(`l.id = $${params.length}`);
    }
    if (filters.onlyFavorites && filters.userId) {
      params.push(filters.userId);
      conditions.push(`exists (select 1 from favorites f where f.listing_id = l.id and f.user_id = $${params.length})`);
    }
    const result = await getPool().query<ListingRow>(
      `
        select l.id, l.venue_id, v.name as venue_name, vl.address as venue_address, vl.neighborhood_name as neighborhood,
          l.title, l.description, l.category_label, l.schedule_summary, l.conditions, l.source_note, l.cuisine,
          l.trust_band, l.confidence_score, l.fresh_until_at, l.recheck_after_at, l.last_verified_at,
          vl.latitude, vl.longitude, v.rating,
          coalesce((select count(*)::int from contribution_proofs cp join contributions c on c.id = cp.contribution_id where c.listing_id = l.id), 0) as proof_count,
          coalesce((select count(*)::int from contributions c where c.listing_id = l.id and c.type = 'confirm_valid'), 0) as recent_confirmations,
          coalesce((select count(*)::int from reports r where r.listing_id = l.id and r.status = 'open'), 0) as negative_signals,
          coalesce((select array_agg(lt.tag order by lt.tag) from listing_tags lt where lt.listing_id = l.id), '{}') as tags,
          coalesce((select json_agg(json_build_object('id', lo.id, 'title', lo.title, 'originalPrice', lo.original_price, 'dealPrice', lo.deal_price, 'currency', lo.currency) order by lo.deal_price) from listing_offers lo where lo.listing_id = l.id), '[]') as offers
        from listings l
        join venues v on v.id = l.venue_id
        join venue_locations vl on vl.venue_id = v.id
        where ${conditions.join(' and ')}
        order by l.updated_at desc
      `,
      params,
    );
    return result.rows.map((row) => ({
      ...row,
      confidence_score: Number(row.confidence_score),
      latitude: Number(row.latitude),
      longitude: Number(row.longitude),
      rating: Number(row.rating),
      proof_count: Number(row.proof_count),
      recent_confirmations: Number(row.recent_confirmations),
      negative_signals: Number(row.negative_signals),
      tags: row.tags ?? [],
      offers: row.offers ?? [],
    }));
  }

  private toListingCard(listing: ListingRow, userId?: string): ListingCard {
    void userId;
    return {
      id: listing.id,
      venueId: listing.venue_id,
      venueName: listing.venue_name,
      title: listing.title,
      neighborhood: listing.neighborhood,
      categoryLabel: listing.category_label,
      scheduleLabel: listing.schedule_summary,
      trustBand: listing.trust_band,
      freshnessText: listing.last_verified_at ? `Verified ${listing.last_verified_at.toISOString().slice(0, 10)}` : 'Needs verification',
      valueNote: listing.offers[0] ? `${listing.offers[0].title} from $${listing.offers[0].dealPrice}` : listing.category_label,
      affordabilityLabel: this.affordabilityLabel(listing),
      distanceMiles: 0,
      rating: listing.rating,
      cuisine: listing.cuisine,
      latitude: listing.latitude,
      longitude: listing.longitude,
      confidenceScore: listing.confidence_score,
      lastUpdatedAt: listing.last_verified_at?.toISOString() ?? null,
      tags: listing.tags,
      saved: false,
    };
  }

  private toListingDetail(listing: ListingRow, userId?: string): ListingDetail {
    return {
      ...this.toListingCard(listing, userId),
      venueAddress: listing.venue_address,
      description: listing.description,
      conditions: listing.conditions,
      sourceNote: listing.source_note,
      offers: listing.offers,
      freshUntilAt: (listing.fresh_until_at ?? new Date()).toISOString(),
      recheckAfterAt: (listing.recheck_after_at ?? new Date()).toISOString(),
      proofCount: listing.proof_count,
      trustSummary: {
        band: listing.trust_band,
        explanation: this.describeTrust(listing.trust_band),
        confidenceScore: listing.confidence_score,
        freshUntilAt: (listing.fresh_until_at ?? new Date()).toISOString(),
        recheckAfterAt: (listing.recheck_after_at ?? new Date()).toISOString(),
        proofCount: listing.proof_count,
        recentConfirmations: listing.recent_confirmations,
        disputeCount: listing.negative_signals,
      },
    };
  }

  private buildFeedSection(id: string, title: string, subtitle: string, source: ListingRow[], userId?: string) {
    return { id, title, subtitle, items: source.slice(0, 6).map((listing) => this.toListingCard(listing, userId)) };
  }

  private sortListingsByDistance(listings: ListingRow[], latitude?: number, longitude?: number): ListingRow[] {
    if (latitude === undefined || longitude === undefined) return [...listings];
    return [...listings].sort((left, right) => haversineDistanceMiles(latitude, longitude, left.latitude, left.longitude) - haversineDistanceMiles(latitude, longitude, right.latitude, right.longitude));
  }

  private affordabilityLabel(listing: ListingRow): string {
    const cheapest = listing.offers.reduce((value, offer) => Math.min(value, offer.dealPrice), Number.POSITIVE_INFINITY);
    if (cheapest <= 5) return 'Under $5';
    if (cheapest <= 10) return 'Under $10';
    if (cheapest <= 15) return 'Under $15';
    return cheapest === Number.POSITIVE_INFINITY ? 'Under $15' : '$15+';
  }

  private describeTrust(trustBand: ListingCard['trustBand']): string {
    switch (trustBand) {
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

  private async getLedgerEntries() {
    const result = await getPool().query<{ id: string; user_id: string; reason: string; points_delta: number; status: 'pending' | 'finalized' | 'reversed'; created_at: Date }>('select id, user_id, reason, points_delta, status, created_at from points_ledger order by created_at desc');
    return result.rows.map((row) => ({ id: row.id, userId: row.user_id, reason: row.reason, pointsDelta: row.points_delta, status: row.status, createdAt: row.created_at.toISOString() }));
  }

  private async getLeaderboardUsers() {
    const result = await getPool().query<{ id: string; display_name: string; verified_contributor: boolean }>('select u.id, p.display_name, p.verified_contributor from users u join user_profiles p on p.user_id = u.id');
    return result.rows.map((row) => ({ id: row.id, displayName: row.display_name, verifiedContributor: row.verified_contributor }));
  }

  private async addLedger(userId: string, contributionId: string, reason: string, pointsDelta: number, status: 'pending' | 'finalized') {
    await getPool().query(
      'insert into points_ledger (id, user_id, contribution_id, reason, points_delta, status) values ($1, $2, $3, $4, $5, $6)',
      [`pts_${ulid().toLowerCase()}`, userId, contributionId, reason, pointsDelta, status],
    );
  }

  private async pushNotification(userId: string, kind: NotificationRecord['kind'], title: string, body: string, deepLink: string) {
    await getPool().query(
      'insert into notifications (id, user_id, kind, title, body, deep_link) values ($1, $2, $3, $4, $5, $6)',
      [`ntf_${ulid().toLowerCase()}`, userId, kind, title, body, deepLink],
    );
  }

  private async appendOutbox(type: string, aggregateType: string, aggregateId: string, payload: object) {
    await getPool().query(
      'insert into outbox_events (id, event_type, aggregate_type, aggregate_id, payload, status, idempotency_key, occurred_at) values ($1, $2, $3, $4, $5, $$pending$$, $6, now()) on conflict (idempotency_key) do nothing',
      [`evt_${ulid().toLowerCase()}`, type, aggregateType, aggregateId, payload, `${type}:${aggregateId}:${ulid()}`],
    );
  }

  private toAdminQueueItem(row: Record<string, unknown>, type: AdminQueueItem['type']): AdminQueueItem {
    return {
      id: String(row.id),
      entityId: String(row.entity_id ?? row.id),
      type,
      title: String(row.title ?? type),
      subtitle: String(row.subtitle ?? 'Requires moderator review.'),
      neighborhood: String(row.neighborhood ?? 'Unknown'),
      createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : new Date().toISOString(),
      priority: 'medium',
      status: String(row.status ?? 'pending'),
    };
  }
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}
