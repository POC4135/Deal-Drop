import { and, eq, ilike, inArray, or, sql } from 'drizzle-orm';
import { db } from '../../db/client';
import { listings, listingSchedules, listingTags, venues } from '../../db/schema/index';
import type { ListListingsQuery } from './schema';

export type ListingRow = {
  id: string;
  venueId: string;
  venueName: string;
  venueNeighborhood: string | null;
  venueAddress: string;
  latitude: number | null;
  longitude: number | null;
  title: string;
  description: string | null;
  category: string;
  trustBand: string;
  confidenceScore: string | null;
  confirmationCount: number;
  freshnessAt: string | null;
  updatedAt: string;
  ageRestricted: boolean;
  studentOnly: boolean;
  priceBand: number | null;
  phone: string | null;
  website: string | null;
  sourceType: string;
  tags: string[];
  schedules: Array<{
    dayOfWeek: number;
    startTime: string;
    endTime: string;
    timezone: string;
    isRecurring: boolean;
  }>;
};

export async function listActiveListings(query: ListListingsQuery): Promise<{
  data: ListingRow[];
  total: number;
}> {
  // Build where conditions
  const conditions = [eq(listings.status, 'active'), eq(venues.isActive, true)];

  if (query.city) {
    conditions.push(eq(venues.city, query.city));
  }
  if (query.neighborhood) {
    conditions.push(eq(venues.neighborhood, query.neighborhood));
  }
  if (query.category) {
    conditions.push(sql`${listings.category}::text = ${query.category}`);
  }
  if (query.search) {
    const term = `%${query.search}%`;
    conditions.push(
      or(
        ilike(listings.title, term),
        ilike(venues.name, term),
        ilike(venues.neighborhood, term),
      )!,
    );
  }

  const where = and(...conditions);

  // Main join: listings + venues
  const rows = await db
    .select({
      id: listings.id,
      venueId: listings.venueId,
      venueName: venues.name,
      venueNeighborhood: venues.neighborhood,
      venueAddress: venues.addressLine1,
      city: venues.city,
      title: listings.title,
      description: listings.description,
      category: sql<string>`${listings.category}::text`,
      trustBand: sql<string>`${listings.trustBand}::text`,
      confidenceScore: listings.confidenceScore,
      confirmationCount: listings.confirmationCount,
      freshnessAt: listings.freshnessAt,
      updatedAt: listings.updatedAt,
      ageRestricted: listings.ageRestricted,
      studentOnly: listings.studentOnly,
      priceBand: venues.priceBand,
      phone: venues.phone,
      website: venues.website,
      sourceType: sql<string>`${listings.sourceType}::text`,
    })
    .from(listings)
    .innerJoin(venues, eq(listings.venueId, venues.id))
    .where(where)
    .limit(query.limit)
    .offset(query.offset);

  if (rows.length === 0) {
    return { data: [], total: 0 };
  }

  // Batch load venue locations (PostGIS raw query)
  const venueIds = [...new Set(rows.map((r) => r.venueId))];
  const locationResult = await db.execute<{
    venue_id: string;
    lat: number;
    lng: number;
  }>(sql`
    SELECT venue_id,
           ST_Y(location::geometry) AS lat,
           ST_X(location::geometry) AS lng
    FROM venue_locations
    WHERE venue_id = ANY(ARRAY[${sql.join(venueIds.map((id) => sql`${id}::uuid`), sql`, `)}])
  `);
  const locationByVenueId = new Map(
    locationResult.map((r) => [r.venue_id, { lat: r.lat, lng: r.lng }]),
  );

  // Batch load listing IDs for schedules + tags
  const listingIds = rows.map((r) => r.id);

  const [scheduleRows, tagRows] = await Promise.all([
    db
      .select({
        listingId: listingSchedules.listingId,
        dayOfWeek: listingSchedules.dayOfWeek,
        startTime: listingSchedules.startTime,
        endTime: listingSchedules.endTime,
        timezone: listingSchedules.timezone,
        isRecurring: listingSchedules.isRecurring,
      })
      .from(listingSchedules)
      .where(inArray(listingSchedules.listingId, listingIds)),

    db
      .select({ listingId: listingTags.listingId, tag: listingTags.tag })
      .from(listingTags)
      .where(inArray(listingTags.listingId, listingIds)),
  ]);

  const schedulesByListingId = new Map<string, (typeof scheduleRows)[number][]>();
  for (const s of scheduleRows) {
    const arr = schedulesByListingId.get(s.listingId) ?? [];
    arr.push(s);
    schedulesByListingId.set(s.listingId, arr);
  }

  const tagsByListingId = new Map<string, string[]>();
  for (const t of tagRows) {
    const arr = tagsByListingId.get(t.listingId) ?? [];
    arr.push(t.tag);
    tagsByListingId.set(t.listingId, arr);
  }

  const data: ListingRow[] = rows.map((r) => {
    const loc = locationByVenueId.get(r.venueId) ?? null;
    return {
      id: r.id,
      venueId: r.venueId,
      venueName: r.venueName,
      venueNeighborhood: r.venueNeighborhood ?? null,
      venueAddress: r.venueAddress,
      latitude: loc?.lat ?? null,
      longitude: loc?.lng ?? null,
      title: r.title,
      description: r.description ?? null,
      category: r.category,
      trustBand: r.trustBand,
      confidenceScore: r.confidenceScore ?? null,
      confirmationCount: r.confirmationCount,
      freshnessAt: r.freshnessAt?.toISOString() ?? null,
      updatedAt: r.updatedAt.toISOString(),
      ageRestricted: r.ageRestricted,
      studentOnly: r.studentOnly,
      priceBand: r.priceBand ?? null,
      phone: r.phone ?? null,
      website: r.website ?? null,
      sourceType: r.sourceType,
      tags: tagsByListingId.get(r.id) ?? [],
      schedules: (schedulesByListingId.get(r.id) ?? []).map((s) => ({
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
        timezone: s.timezone,
        isRecurring: s.isRecurring,
      })),
    };
  });

  // Count total matching rows
  const [{ count }] = await db
    .select({ count: sql<number>`count(*)::int` })
    .from(listings)
    .innerJoin(venues, eq(listings.venueId, venues.id))
    .where(where);

  return { data, total: count };
}

export async function getListingById(listingId: string): Promise<ListingRow | null> {
  const result = await listActiveListings({
    limit: 1,
    offset: 0,
    city: undefined,
    neighborhood: undefined,
    category: undefined,
    search: undefined,
  });

  // Override: fetch specific listing regardless of status filter would need a tweak,
  // so we do a targeted query here.
  const rows = await db
    .select({
      id: listings.id,
      venueId: listings.venueId,
      venueName: venues.name,
      venueNeighborhood: venues.neighborhood,
      venueAddress: venues.addressLine1,
      title: listings.title,
      description: listings.description,
      category: sql<string>`${listings.category}::text`,
      trustBand: sql<string>`${listings.trustBand}::text`,
      confidenceScore: listings.confidenceScore,
      confirmationCount: listings.confirmationCount,
      freshnessAt: listings.freshnessAt,
      updatedAt: listings.updatedAt,
      ageRestricted: listings.ageRestricted,
      studentOnly: listings.studentOnly,
      priceBand: venues.priceBand,
      phone: venues.phone,
      website: venues.website,
      sourceType: sql<string>`${listings.sourceType}::text`,
    })
    .from(listings)
    .innerJoin(venues, eq(listings.venueId, venues.id))
    .where(and(eq(listings.id, listingId), eq(listings.status, 'active')))
    .limit(1);

  void result; // unused — kept for structural reference

  if (rows.length === 0) return null;
  const r = rows[0];

  // Location
  const locationResult = await db.execute<{ lat: number; lng: number }>(sql`
    SELECT ST_Y(location::geometry) AS lat,
           ST_X(location::geometry) AS lng
    FROM venue_locations
    WHERE venue_id = ${r.venueId}::uuid
    LIMIT 1
  `);
  const loc = locationResult[0] ?? null;

  const [scheduleRows, tagRows] = await Promise.all([
    db
      .select({
        dayOfWeek: listingSchedules.dayOfWeek,
        startTime: listingSchedules.startTime,
        endTime: listingSchedules.endTime,
        timezone: listingSchedules.timezone,
        isRecurring: listingSchedules.isRecurring,
      })
      .from(listingSchedules)
      .where(eq(listingSchedules.listingId, listingId)),

    db
      .select({ tag: listingTags.tag })
      .from(listingTags)
      .where(eq(listingTags.listingId, listingId)),
  ]);

  return {
    id: r.id,
    venueId: r.venueId,
    venueName: r.venueName,
    venueNeighborhood: r.venueNeighborhood ?? null,
    venueAddress: r.venueAddress,
    latitude: loc?.lat ?? null,
    longitude: loc?.lng ?? null,
    title: r.title,
    description: r.description ?? null,
    category: r.category,
    trustBand: r.trustBand,
    confidenceScore: r.confidenceScore ?? null,
    confirmationCount: r.confirmationCount,
    freshnessAt: r.freshnessAt?.toISOString() ?? null,
    updatedAt: r.updatedAt.toISOString(),
    ageRestricted: r.ageRestricted,
    studentOnly: r.studentOnly,
    priceBand: r.priceBand ?? null,
    phone: r.phone ?? null,
    website: r.website ?? null,
    sourceType: r.sourceType,
    tags: tagRows.map((t) => t.tag),
    schedules: scheduleRows.map((s) => ({
      dayOfWeek: s.dayOfWeek,
      startTime: s.startTime,
      endTime: s.endTime,
      timezone: s.timezone,
      isRecurring: s.isRecurring,
    })),
  };
}
