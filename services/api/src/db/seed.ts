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

type ListingInsert = Omit<typeof schema.listings.$inferInsert, 'venueId'> & { _slug: string; _venueSlug: string; venueId?: string };

const listingDefs: ListingInsert[] = [
  // ── Zoe's Tacos ─────────────────────────────────────────────────────────────
  {
    _slug: 'zoes-150-tacos',
    _venueSlug: 'zoes-tacos-midtown',
    title: '$1.50 Tacos',
    description: '$1.50 Tacos — Tuesday & Friday',
    category: 'cheap_eats',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'zoes-899-burrito',
    _venueSlug: 'zoes-tacos-midtown',
    title: '$8.99 Burrito',
    description: '$8.99 Burrito — Wednesdays',
    category: 'cheap_eats',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'zoes-599-quesadilla',
    _venueSlug: 'zoes-tacos-midtown',
    title: '$5.99 Quesadilla',
    description: '$5.99 Quesadilla — Thursdays',
    category: 'cheap_eats',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'zoes-799-torta',
    _venueSlug: 'zoes-tacos-midtown',
    title: '$7.99 Torta',
    description: '$7.99 Torta — Mondays',
    category: 'cheap_eats',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },

  // ── Moe's Southwest Grill ────────────────────────────────────────────────────
  {
    _slug: 'moes-699-burrito-bowl',
    _venueSlug: 'moes-grill-midtown',
    title: '$6.99 Burrito or Bowl',
    description: 'Dine-in or carry-out. Rewards Members only.',
    category: 'student_offer',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },

  // ── Gyro Bros ────────────────────────────────────────────────────────────────
  {
    _slug: 'gyro-bros-899-lunch',
    _venueSlug: 'gyro-bros-midtown',
    title: '$8.99 Gyro Lunch Special',
    description: '$8.99 Gyro and side — available every day',
    category: 'food_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },

  // ── Cypress Street Pint & Plate ───────────────────────────────────────────────
  {
    _slug: 'cypress-3-taco-monday',
    _venueSlug: 'cypress-street-midtown',
    title: '$3 Taco Monday',
    description: '$3 Tacos every Monday',
    category: 'cheap_eats',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'cypress-3-beer',
    _venueSlug: 'cypress-street-midtown',
    title: '$3 Beer',
    description: '$3 Select Beers — House IPA & House Pilsner',
    category: 'drink_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'cypress-20-wine-pizza',
    _venueSlug: 'cypress-street-midtown',
    title: '$20 Bottle of Wine & Personal Pizza',
    description: 'Bottle of wine and a personal pizza — Wednesdays',
    category: 'special',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },

  // ── Steamhouse Lounge ────────────────────────────────────────────────────────
  {
    _slug: 'steamhouse-20-snow-crab',
    _venueSlug: 'steamhouse-lounge-midtown',
    title: '$20 1 lb Snow Crab',
    description: '1 lb Snow Crab — Mondays',
    category: 'food_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'steamhouse-6-goombay',
    _venueSlug: 'steamhouse-lounge-midtown',
    title: '$6 Goombay Smash',
    description: 'Goombay Smash cocktail — Mondays',
    category: 'drink_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'steamhouse-taco-special',
    _venueSlug: 'steamhouse-lounge-midtown',
    title: 'Taco Special',
    description: 'Taco Special — Tuesdays',
    category: 'food_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'steamhouse-650-margarita',
    _venueSlug: 'steamhouse-lounge-midtown',
    title: '$6.50 Campo Bravo Margarita',
    description: 'Campo Bravo Margarita — Tuesdays',
    category: 'drink_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'steamhouse-15-raw-oysters',
    _venueSlug: 'steamhouse-lounge-midtown',
    title: '$15 Dozen Raw Oysters',
    description: 'Dozen Raw Oysters — Wednesdays',
    category: 'food_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'steamhouse-10-grilled-oysters',
    _venueSlug: 'steamhouse-lounge-midtown',
    title: '$10 ½ Dozen Char-Grilled Oysters',
    description: '½ Dozen Char-Grilled Oysters — Wednesdays',
    category: 'food_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
  {
    _slug: 'steamhouse-550-house-wine',
    _venueSlug: 'steamhouse-lounge-midtown',
    title: '$5.50 House Wine',
    description: 'House Wine — Wednesdays',
    category: 'drink_deal',
    trustBand: 'founder_verified',
    status: 'active',
    sourceType: 'founder_entered',
    confidenceScore: '90',
  },
];

// ── Schedules ─────────────────────────────────────────────────────────────────
// Days: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat

type ScheduleDef = {
  listingSlug: string;
  days: number[];
  startTime: string;
  endTime: string;
  timezone?: string;
};

const ALL_DAYS = [0, 1, 2, 3, 4, 5, 6];

const scheduleDefs: ScheduleDef[] = [
  // Zoe's Tacos
  { listingSlug: 'zoes-150-tacos',        days: [2, 5],    startTime: '11:00', endTime: '21:00' },
  { listingSlug: 'zoes-899-burrito',       days: [3],       startTime: '11:00', endTime: '21:00' },
  { listingSlug: 'zoes-599-quesadilla',    days: [4],       startTime: '11:00', endTime: '21:00' },
  { listingSlug: 'zoes-799-torta',         days: [1],       startTime: '11:00', endTime: '21:00' },
  // Moe's
  { listingSlug: 'moes-699-burrito-bowl',  days: [1],       startTime: '10:00', endTime: '23:00' },
  // Gyro Bros
  { listingSlug: 'gyro-bros-899-lunch',    days: ALL_DAYS,  startTime: '11:00', endTime: '20:30' },
  // Cypress Street
  { listingSlug: 'cypress-3-taco-monday',  days: [1],       startTime: '11:00', endTime: '23:59' },
  { listingSlug: 'cypress-3-beer',         days: ALL_DAYS,  startTime: '12:00', endTime: '23:59' },
  { listingSlug: 'cypress-20-wine-pizza',  days: [3],       startTime: '13:00', endTime: '23:59' },
  // Steamhouse Lounge
  { listingSlug: 'steamhouse-20-snow-crab',      days: [1], startTime: '11:30', endTime: '22:00' },
  { listingSlug: 'steamhouse-6-goombay',         days: [1], startTime: '11:30', endTime: '22:00' },
  { listingSlug: 'steamhouse-taco-special',      days: [2], startTime: '11:30', endTime: '22:00' },
  { listingSlug: 'steamhouse-650-margarita',     days: [2], startTime: '11:30', endTime: '22:00' },
  { listingSlug: 'steamhouse-15-raw-oysters',    days: [3], startTime: '11:30', endTime: '22:00' },
  { listingSlug: 'steamhouse-10-grilled-oysters',days: [3], startTime: '11:30', endTime: '22:00' },
  { listingSlug: 'steamhouse-550-house-wine',    days: [3], startTime: '11:30', endTime: '22:00' },
];

// ── Tags ──────────────────────────────────────────────────────────────────────

const tagDefs: Record<string, string[]> = {
  'zoes-150-tacos':               ['tacos', 'mexican', 'cheap_eats'],
  'zoes-899-burrito':             ['burritos', 'mexican'],
  'zoes-599-quesadilla':          ['quesadilla', 'mexican'],
  'zoes-799-torta':               ['torta', 'mexican'],
  'moes-699-burrito-bowl':        ['burritos', 'mexican', 'rewards'],
  'gyro-bros-899-lunch':          ['gyro', 'mediterranean', 'lunch'],
  'cypress-3-taco-monday':        ['tacos', 'happy_hour'],
  'cypress-3-beer':               ['beer', 'happy_hour'],
  'cypress-20-wine-pizza':        ['wine', 'pizza'],
  'steamhouse-20-snow-crab':      ['seafood', 'crab'],
  'steamhouse-6-goombay':         ['cocktails'],
  'steamhouse-taco-special':      ['tacos'],
  'steamhouse-650-margarita':     ['cocktails', 'margarita'],
  'steamhouse-15-raw-oysters':    ['seafood', 'oysters'],
  'steamhouse-10-grilled-oysters':['seafood', 'oysters'],
  'steamhouse-550-house-wine':    ['wine'],
};

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
