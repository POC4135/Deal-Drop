/**
 * Import script — loads venues and deals from an Excel workbook.
 *
 * Expects two sheets named exactly "Venues" and "Deals":
 *
 * Venues columns:
 *   name, slug, address_line_1, address_line_2, city, state, postal_code,
 *   neighborhood, latitude, longitude, phone, website, price_band, google_place_id
 *
 * Deals columns:
 *   venue_slug, title, description, category, days, start_time, end_time,
 *   age_restricted, student_only, tags, valid_from, valid_to
 *
 *   days      — comma-separated abbreviations: Mon,Tue,Wed,Thu,Fri,Sat,Sun
 *               OR the literal "Every day"
 *   category  — one of: cheap_eats food_deal drink_deal student_offer special happy_hour
 *   times     — 24-hour HH:MM (e.g. 17:00)
 *   tags      — optional, comma-separated free-text
 *   valid_from/valid_to — optional YYYY-MM-DD
 *
 * Venues are upserted by slug — safe to re-run.
 * Deals are additive per run — re-running the same file will insert duplicates.
 *
 * Usage: pnpm db:import ./data.xlsx
 */
import 'dotenv/config';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
const require = createRequire(import.meta.url);
const XLSX = require('xlsx') as typeof import('xlsx');
import postgres from 'postgres';
import { drizzle } from 'drizzle-orm/postgres-js';
import * as schema from './schema/index';

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is not set.');

const filePath = process.argv[2];
if (!filePath) {
  console.error('Usage: pnpm db:import <path-to-xlsx>');
  process.exit(1);
}

const client = postgres(process.env.DATABASE_URL, { max: 1 });
const db = drizzle(client, { schema });
const sql = client;

// ── Day parsing ───────────────────────────────────────────────────────────────
// DB: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat

const DAY_MAP: Record<string, number> = {
  sun: 0, sunday: 0,
  mon: 1, monday: 1,
  tue: 2, tuesday: 2,
  wed: 3, wednesday: 3,
  thu: 4, thursday: 4,
  fri: 5, friday: 5,
  sat: 6, saturday: 6,
};
const ALL_DAYS = [0, 1, 2, 3, 4, 5, 6];

function parseDays(raw: string): number[] {
  const trimmed = raw.trim().toLowerCase();
  if (trimmed === 'every day' || trimmed === 'everyday' || trimmed === 'daily') {
    return ALL_DAYS;
  }
  return trimmed.split(',').map((d) => {
    const n = DAY_MAP[d.trim()];
    if (n === undefined) throw new Error(`Unknown day abbreviation: "${d.trim()}"`);
    return n;
  });
}

// Excel stores times as a fraction of a day (e.g. 11:00 = 0.4583...).
// Convert to HH:MM, or pass through if already a string like "11:00".
function parseTime(raw: unknown): string {
  if (typeof raw === 'number') {
    const totalMinutes = Math.round(raw * 24 * 60);
    const h = Math.floor(totalMinutes / 60) % 24;
    const m = totalMinutes % 60;
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  }
  return str(raw).trim() || '00:00';
}

function parseBool(raw: string | boolean | undefined): boolean {
  if (typeof raw === 'boolean') return raw;
  if (!raw) return false;
  return raw.toString().toLowerCase() === 'true';
}

function str(v: unknown): string {
  return v === null || v === undefined ? '' : String(v).trim();
}

// ── Read workbook ─────────────────────────────────────────────────────────────

console.log(`\n📂 Reading ${filePath}...\n`);
const workbook = XLSX.readFile(resolve(filePath));

const venueSheet = workbook.Sheets['Venues'];
const dealSheet  = workbook.Sheets['Deals'];

if (!venueSheet) throw new Error('Sheet "Venues" not found in workbook.');
if (!dealSheet)  throw new Error('Sheet "Deals" not found in workbook.');

type VenueRow = Record<string, unknown>;
type DealRow  = Record<string, unknown>;

const venueRows: VenueRow[] = XLSX.utils.sheet_to_json(venueSheet, { defval: '' });
const dealRows: DealRow[]   = XLSX.utils.sheet_to_json(dealSheet,  { defval: '' });

console.log(`  Found ${venueRows.length} venue rows`);
console.log(`  Found ${dealRows.length} deal rows\n`);

// ── Upsert venues ─────────────────────────────────────────────────────────────

console.log('Upserting venues...');
const venueIdBySlug: Record<string, string> = {};

for (const row of venueRows) {
  const slug = str(row['slug']);
  if (!slug) throw new Error(`Venue row missing slug: ${JSON.stringify(row)}`);

  const priceBand = row['price_band'] ? Number(row['price_band']) : undefined;

  const values: typeof schema.venues.$inferInsert = {
    name:          str(row['name'])          || (() => { throw new Error(`Venue "${slug}" missing name`); })(),
    slug,
    addressLine1:  str(row['address_line_1']) || (() => { throw new Error(`Venue "${slug}" missing address_line_1`); })(),
    addressLine2:  str(row['address_line_2']) || undefined,
    city:          str(row['city'])          || (() => { throw new Error(`Venue "${slug}" missing city`); })(),
    state:         str(row['state'])         || (() => { throw new Error(`Venue "${slug}" missing state`); })(),
    postalCode:    str(row['postal_code'])   || undefined,
    neighborhood:  str(row['neighborhood'])  || undefined,
    googlePlaceId: str(row['google_place_id']) || undefined,
    phone:         str(row['phone'])         || undefined,
    website:       str(row['website'])       || undefined,
    priceBand:     priceBand && !isNaN(priceBand) ? priceBand : undefined,
    isActive:      true,
  };

  const [upserted] = await db
    .insert(schema.venues)
    .values(values)
    .onConflictDoUpdate({
      target: schema.venues.slug,
      set: {
        name:          values.name,
        addressLine1:  values.addressLine1,
        addressLine2:  values.addressLine2,
        city:          values.city,
        state:         values.state,
        postalCode:    values.postalCode,
        neighborhood:  values.neighborhood,
        googlePlaceId: values.googlePlaceId,
        phone:         values.phone,
        website:       values.website,
        priceBand:     values.priceBand,
        updatedAt:     new Date(),
      },
    })
    .returning({ id: schema.venues.id, slug: schema.venues.slug });

  venueIdBySlug[upserted.slug] = upserted.id;

  // Upsert venue_locations if lat/lng provided
  const lat = parseFloat(str(row['latitude']));
  const lng = parseFloat(str(row['longitude']));
  if (!isNaN(lat) && !isNaN(lng)) {
    await sql`
      INSERT INTO venue_locations (venue_id, location)
      VALUES (
        ${upserted.id},
        ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography
      )
      ON CONFLICT (venue_id) DO UPDATE
        SET location   = EXCLUDED.location,
            updated_at = now()
    `;
  }

  console.log(`  ✓ ${values.name} (${slug})`);
}

// Also load any venues already in DB that aren't in this file (for deal FK resolution)
const allVenues = await db.select({ id: schema.venues.id, slug: schema.venues.slug }).from(schema.venues);
for (const v of allVenues) {
  if (!venueIdBySlug[v.slug]) venueIdBySlug[v.slug] = v.id;
}

console.log(`\n  ${venueRows.length} venues upserted.\n`);

// ── Insert deals ──────────────────────────────────────────────────────────────

console.log('Inserting deals...');
let listingCount = 0;
let scheduleCount = 0;
let tagCount = 0;

for (const row of dealRows) {
  const venueSlug = str(row['venue_slug']);
  const venueId   = venueIdBySlug[venueSlug];
  if (!venueId) throw new Error(`Deal references unknown venue_slug: "${venueSlug}"`);

  const title = str(row['title']);
  if (!title) throw new Error(`Deal row missing title: ${JSON.stringify(row)}`);

  const category = str(row['category']) as typeof schema.listings.$inferInsert['category'];
  const validCategories = ['cheap_eats','food_deal','drink_deal','student_offer','special','happy_hour'];
  if (!validCategories.includes(category)) {
    throw new Error(`Invalid category "${category}" for deal "${title}". Must be one of: ${validCategories.join(', ')}`);
  }

  // Insert listing
  const [listing] = await db
    .insert(schema.listings)
    .values({
      venueId,
      title,
      description:   str(row['description']) || undefined,
      category,
      status:        'active',
      sourceType:    'founder_entered',
      trustBand:     'founder_verified',
      confidenceScore: '90',
      ageRestricted: parseBool(row['age_restricted'] as string),
      studentOnly:   parseBool(row['student_only'] as string),
    })
    .returning({ id: schema.listings.id });

  listingCount++;

  // Insert schedules (one row per day)
  const daysRaw = str(row['days']);
  if (daysRaw) {
    const days = parseDays(daysRaw);
    const startTime = parseTime(row['start_time']);
    const endTime   = parseTime(row['end_time']) || '23:59';
    const validFrom = str(row['valid_from']) || undefined;
    const validTo   = str(row['valid_to'])   || undefined;

    const scheduleRows = days.map((dayOfWeek) => ({
      listingId:   listing.id,
      dayOfWeek,
      startTime,
      endTime,
      timezone:    'America/New_York',
      isRecurring: true,
      validFrom:   validFrom || null,
      validTo:     validTo   || null,
    })) satisfies (typeof schema.listingSchedules.$inferInsert)[];

    await db.insert(schema.listingSchedules).values(scheduleRows);
    scheduleCount += scheduleRows.length;
  }

  // Insert tags
  const tagsRaw = str(row['tags']);
  if (tagsRaw) {
    const tags = tagsRaw.split(',').map((t) => t.trim()).filter(Boolean);
    if (tags.length > 0) {
      await db.insert(schema.listingTags).values(tags.map((tag) => ({ listingId: listing.id, tag })));
      tagCount += tags.length;
    }
  }

  console.log(`  ✓ ${title} @ ${venueSlug}`);
}

console.log(`\n  ${listingCount} deals inserted`);
console.log(`  ${scheduleCount} schedule rows inserted`);
console.log(`  ${tagCount} tags inserted\n`);

console.log('✅ Import complete.');
await client.end();
