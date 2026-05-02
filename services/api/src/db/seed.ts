/**
 * Seed script — inserts realistic beta data so the app has content to show.
 *
 * Seeds:
 *   - venues          (5 Atlanta Midtown restaurants)
 *   - venue_locations (lat/lng via raw SQL — PostGIS table)
 *   - listings        (deals per venue)
 *   - listing_schedules (when each deal runs)
 *   - listing_tags    (searchable tags per listing)
 *   - badges          (full catalog)
 *
 * Safe to re-run: clears seeded data first keyed on stable slugs.
 *
 * Usage: pnpm db:seed
 */
import 'dotenv/config';
import postgres from 'postgres';
import { drizzle } from 'drizzle-orm/postgres-js';
import * as schema from './schema/index';
import { inArray } from 'drizzle-orm';

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set.');
}

const client = postgres(process.env.DATABASE_URL, { max: 1 });
const db = drizzle(client, { schema });
const sql = client;

// ── Venues ────────────────────────────────────────────────────────────────────

const VENUE_SLUGS = [
  'zoes-tacos-midtown',
  'moes-grill-midtown',
  'gyro-bros-midtown',
  'cypress-street-midtown',
  'steamhouse-lounge-midtown',
];

const venueRows = [
  {
    name: "Zoe's Tacos",
    slug: 'zoes-tacos-midtown',
    addressLine1: '75 5th St NW',
    city: 'Atlanta',
    state: 'GA',
    postalCode: '30308',
    neighborhood: 'Midtown',
    phone: '+14708377155',
    website: 'https://zoetacosga.com/',
  },
  {
    name: "Moe's Southwest Grill",
    slug: 'moes-grill-midtown',
    addressLine1: '85 5th St NW',
    city: 'Atlanta',
    state: 'GA',
    postalCode: '30308',
    neighborhood: 'Midtown',
    phone: '+14045419940',
    website: 'https://www.moes.com/',
    priceBand: 1,
  },
  {
    name: 'Gyro Bros',
    slug: 'gyro-bros-midtown',
    addressLine1: '85 5th St NW Suite B',
    city: 'Atlanta',
    state: 'GA',
    postalCode: '30308',
    neighborhood: 'Midtown',
    phone: '+14048925707',
    website: 'https://www.gyrobrosatl.com/',
    priceBand: 1,
  },
  {
    name: 'Cypress Street Pint & Plate',
    slug: 'cypress-street-midtown',
    addressLine1: '817 W Peachtree St NW',
    city: 'Atlanta',
    state: 'GA',
    postalCode: '30308',
    neighborhood: 'Midtown',
    phone: '+14048159243',
    website: 'https://cypressatl.com/',
    priceBand: 2,
  },
  {
    name: 'Steamhouse Lounge',
    slug: 'steamhouse-lounge-midtown',
    addressLine1: '1051 W Peachtree St NW',
    city: 'Atlanta',
    state: 'GA',
    postalCode: '30309',
    neighborhood: 'Midtown',
    phone: '+14042337980',
    website: 'http://www.steamhouselounge.com/',
    priceBand: 2,
  },
] satisfies (typeof schema.venues.$inferInsert)[];

// ── Venue coordinates [lng, lat] (WGS-84) ────────────────────────────────────

const VENUE_COORDS: Record<string, [number, number]> = {
  'zoes-tacos-midtown':         [-84.3890, 33.7783],
  'moes-grill-midtown':         [-84.3893, 33.7782],
  'gyro-bros-midtown':          [-84.3892, 33.7781],
  'cypress-street-midtown':     [-84.3880, 33.7850],
  'steamhouse-lounge-midtown':  [-84.3885, 33.7898],
};

// ── Listings ──────────────────────────────────────────────────────────────────
// TODO: populate once deal data is provided

type ListingInsert = typeof schema.listings.$inferInsert & { _slug: string; _venueSlug: string };

const listingDefs: ListingInsert[] = [];

// ── Schedules ─────────────────────────────────────────────────────────────────

type ScheduleDef = {
  listingSlug: string;
  days: number[];
  startTime: string;
  endTime: string;
  timezone?: string;
};

const scheduleDefs: ScheduleDef[] = [];

// ── Tags ──────────────────────────────────────────────────────────────────────

const tagDefs: Record<string, string[]> = {};

// ── Badge catalog ─────────────────────────────────────────────────────────────

const badgeDefs = [
  { slug: 'first-confirmation',   title: 'First Confirmation',   description: 'Confirmed your first deal.' },
  { slug: 'streak-3',             title: '3-Day Streak',         description: 'Confirmed deals 3 days in a row.' },
  { slug: 'streak-7',             title: 'Week Warrior',         description: 'Confirmed deals 7 days in a row.' },
  { slug: 'streak-30',            title: 'Monthly Regular',      description: 'Confirmed deals 30 days in a row.' },
  { slug: 'first-contribution',   title: 'Deal Hunter',          description: 'Submitted your first new deal.' },
  { slug: 'contributions-5',      title: 'Scout',                description: 'Submitted 5 approved deals.' },
  { slug: 'contributions-25',     title: 'Correspondent',        description: 'Submitted 25 approved deals.' },
  { slug: 'top-contributor',      title: 'Top Contributor',      description: 'Ranked in the top 10 on the weekly leaderboard.' },
  { slug: 'verified-contributor', title: 'Verified Contributor', description: 'Earned verified status for consistent, accurate contributions.' },
  { slug: 'early-adopter',        title: 'Early Adopter',        description: 'Joined DealDrop during the beta.' },
] satisfies (typeof schema.badges.$inferInsert)[];

// ── Main ──────────────────────────────────────────────────────────────────────

console.log('🌱 Starting seed...\n');

// 1. Remove existing seed data keyed on stable slugs (idempotent re-runs)
console.log('Clearing old seed data...');
const existingVenues = await db
  .select({ id: schema.venues.id, slug: schema.venues.slug })
  .from(schema.venues)
  .where(inArray(schema.venues.slug, VENUE_SLUGS));

if (existingVenues.length > 0) {
  const existingVenueIds = existingVenues.map((v) => v.id);
  // Listings cascade-delete schedules and tags via FK
  await db
    .delete(schema.listings)
    .where(inArray(schema.listings.venueId, existingVenueIds));
  await db
    .delete(schema.venues)
    .where(inArray(schema.venues.id, existingVenueIds));
}
await db
  .delete(schema.badges)
  .where(inArray(schema.badges.slug, badgeDefs.map((b) => b.slug)));
console.log('Cleared.\n');

// 2. Insert venues
console.log('Inserting venues...');
const insertedVenues = await db
  .insert(schema.venues)
  .values(venueRows)
  .returning({ id: schema.venues.id, slug: schema.venues.slug });

const venueIdBySlug = Object.fromEntries(insertedVenues.map((v) => [v.slug, v.id]));
console.log(`  ${insertedVenues.length} venues inserted.`);

// 3. Insert venue_locations (raw SQL — PostGIS geography column)
console.log('Inserting venue_locations...');
for (const [slug, [lng, lat]] of Object.entries(VENUE_COORDS)) {
  const venueId = venueIdBySlug[slug];
  await sql`
    INSERT INTO venue_locations (venue_id, location)
    VALUES (
      ${venueId},
      ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography
    )
    ON CONFLICT (venue_id) DO UPDATE
      SET location   = EXCLUDED.location,
          updated_at = now()
  `;
}
console.log(`  ${Object.keys(VENUE_COORDS).length} venue_locations inserted.\n`);

// 4. Insert listings
console.log('Inserting listings...');
const listingsBySlug: Record<string, string> = {};

for (const def of listingDefs) {
  const { _slug, _venueSlug, ...row } = def;
  const venueId = venueIdBySlug[_venueSlug];
  if (!venueId) throw new Error(`Could not resolve venueId for venue slug: ${_venueSlug}`);

  const [inserted] = await db
    .insert(schema.listings)
    .values({ ...row, venueId })
    .returning({ id: schema.listings.id });

  listingsBySlug[_slug] = inserted.id;
}
console.log(`  ${listingDefs.length} listings inserted.\n`);

// 5. Insert listing_schedules
console.log('Inserting listing_schedules...');
let scheduleCount = 0;
for (const def of scheduleDefs) {
  const listingId = listingsBySlug[def.listingSlug];
  if (!listingId) throw new Error(`No listing found for slug: ${def.listingSlug}`);

  const rows = def.days.map((dayOfWeek) => ({
    listingId,
    dayOfWeek,
    startTime: def.startTime,
    endTime: def.endTime,
    timezone: def.timezone ?? 'America/New_York',
    isRecurring: true,
  })) satisfies (typeof schema.listingSchedules.$inferInsert)[];

  await db.insert(schema.listingSchedules).values(rows);
  scheduleCount += rows.length;
}
console.log(`  ${scheduleCount} schedule rows inserted.\n`);

// 6. Insert listing_tags
console.log('Inserting listing_tags...');
let tagCount = 0;
for (const [listingSlug, tags] of Object.entries(tagDefs)) {
  const listingId = listingsBySlug[listingSlug];
  if (!listingId) throw new Error(`No listing found for slug: ${listingSlug}`);

  const rows = tags.map((tag) => ({ listingId, tag })) satisfies (typeof schema.listingTags.$inferInsert)[];
  await db.insert(schema.listingTags).values(rows);
  tagCount += rows.length;
}
console.log(`  ${tagCount} tag rows inserted.\n`);

// 7. Insert badges
console.log('Inserting badges...');
await db.insert(schema.badges).values(badgeDefs);
console.log(`  ${badgeDefs.length} badges inserted.\n`);

console.log('✅ Seed complete.');
await client.end();
