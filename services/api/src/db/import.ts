/**
 * Import venues and listings from an Excel workbook into the Phase C schema.
 *
 * Venues sheet columns:
 *   name, slug, address_line_1, address_line_2, city, state, postal_code,
 *   neighborhood, latitude, longitude, google_place_id
 *
 * Deals sheet columns:
 *   venue_slug, title, description, category, days, start_time, end_time, tags
 *
 *   days     — comma-separated: Mon,Tue,Wed,Thu,Fri,Sat,Sun  OR  "Every day"
 *   category — cheap_eats | food_deal | drink_deal | student_offer | special | happy_hour
 *   times    — 24-hour HH:MM or Excel decimal fraction
 *   tags     — optional, comma-separated
 *
 * Venues are upserted by slug. Deals are additive — re-running the same file creates duplicates.
 *
 * Usage: pnpm db:import ../../path/to/file.xlsx
 */
import 'dotenv/config';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { Client } from 'pg';
import { ulid } from 'ulid';

const require = createRequire(import.meta.url);
const XLSX = require('xlsx') as typeof import('xlsx');

import { parseRuntimeEnv } from '@dealdrop/config';

const env = parseRuntimeEnv(process.env);

const filePath = process.argv[2];
if (!filePath) {
  console.error('Usage: pnpm db:import <path-to-xlsx>');
  process.exit(1);
}

const match = env.DATABASE_URL.match(/^postgres(?:ql)?:\/\/([^:]+):([^@]+)@([^:/]+):?(\d*)\/(.+)$/);
if (!match) throw new Error('Could not parse DATABASE_URL');
const [, user, password, host, port, database] = match;

const client = new Client({
  host,
  port: Number(port) || 5432,
  database,
  user,
  password,
  ssl: host.includes('supabase') ? { rejectUnauthorized: false } : false,
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function str(v: unknown): string {
  return v === null || v === undefined ? '' : String(v).trim();
}

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

function shortId(prefix: string, slug: string): string {
  return `${prefix}_${slug.replace(/-/g, '_').slice(0, 40)}`;
}

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
const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function parseDays(raw: string): number[] {
  const trimmed = raw.trim().toLowerCase();
  if (trimmed === 'every day' || trimmed === 'everyday' || trimmed === 'daily') return ALL_DAYS;
  return trimmed.split(',').map((d) => {
    const n = DAY_MAP[d.trim()];
    if (n === undefined) throw new Error(`Unknown day: "${d.trim()}"`);
    return n;
  });
}

function parseTime(raw: unknown): string {
  if (typeof raw === 'number') {
    const totalMinutes = Math.round(raw * 24 * 60);
    const h = Math.floor(totalMinutes / 60) % 24;
    const m = totalMinutes % 60;
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  }
  return str(raw).trim() || '00:00';
}

function buildScheduleSummary(days: number[], startTime: string, endTime: string): string {
  if (days.length === 7) return `Daily ${startTime}–${endTime}`;
  const names = days.map((d) => DAY_NAMES[d]).join('/');
  return `${names} ${startTime}–${endTime}`;
}

const CATEGORY_LABELS: Record<string, string> = {
  cheap_eats:    'Cheap Eats',
  food_deal:     'Food Deal',
  drink_deal:    'Drink Deal',
  student_offer: 'Student Offer',
  special:       'Special',
  happy_hour:    'Happy Hour',
};

// ── Read workbook ─────────────────────────────────────────────────────────────

console.log(`\nReading ${filePath}...\n`);
const workbook = XLSX.readFile(resolve(filePath));

const venueSheet = workbook.Sheets['Venues'];
const dealSheet  = workbook.Sheets['Deals'];
if (!venueSheet) throw new Error('Sheet "Venues" not found.');
if (!dealSheet)  throw new Error('Sheet "Deals" not found.');

type Row = Record<string, unknown>;
const venueRows: Row[] = XLSX.utils.sheet_to_json(venueSheet, { defval: '' });
const dealRows: Row[]  = XLSX.utils.sheet_to_json(dealSheet,  { defval: '' });

console.log(`  ${venueRows.length} venue rows`);
console.log(`  ${dealRows.length} deal rows\n`);

// ── Main ──────────────────────────────────────────────────────────────────────

await client.connect();

const venueIdBySlug: Record<string, string> = {};

// Upsert venues
console.log('Upserting venues...');
for (const row of venueRows) {
  const slug = str(row['slug']);
  if (!slug) throw new Error(`Venue row missing slug: ${JSON.stringify(row)}`);

  const name = str(row['name']);
  if (!name) throw new Error(`Venue "${slug}" missing name`);

  const venueId = shortId('ven', slug);

  await client.query(
    `insert into venues (id, slug, name, rating, status)
     values ($1, $2, $3, 0, 'active')
     on conflict (slug) do update set name = excluded.name, updated_at = now()`,
    [venueId, slug, name],
  );

  // Build single address string from Excel columns
  const parts = [
    str(row['address_line_1']),
    str(row['address_line_2']),
    str(row['city']),
    str(row['state']),
    str(row['postal_code']),
  ].filter(Boolean);
  const address = parts.join(', ') || slug;

  const neighborhood = str(row['neighborhood']) || 'Atlanta';
  const neighborhoodSlug = slugify(neighborhood);
  const lat = parseFloat(str(row['latitude']));
  const lng = parseFloat(str(row['longitude']));

  if (!isNaN(lat) && !isNaN(lng)) {
    await client.query(
      `insert into venue_locations (id, venue_id, neighborhood_name, neighborhood_slug, address, latitude, longitude, point)
       values ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_MakePoint($7, $6), 4326)::geography)
       on conflict (venue_id) do update set
         neighborhood_name = excluded.neighborhood_name,
         neighborhood_slug = excluded.neighborhood_slug,
         address           = excluded.address,
         latitude          = excluded.latitude,
         longitude         = excluded.longitude,
         point             = excluded.point`,
      [`loc_${venueId}`, venueId, neighborhood, neighborhoodSlug, address, lat, lng],
    );
  }

  venueIdBySlug[slug] = venueId;
  console.log(`  ✓ ${name} (${slug})`);
}

// Load any existing venues not in this file
const existing = await client.query<{ id: string; slug: string }>('select id, slug from venues');
for (const v of existing.rows) {
  if (!venueIdBySlug[v.slug]) venueIdBySlug[v.slug] = v.id;
}

console.log(`\n  ${venueRows.length} venues upserted.\n`);

// Insert listings
console.log('Inserting listings...');
let listingCount = 0;

for (const row of dealRows) {
  const venueSlug = str(row['venue_slug']);
  const venueId   = venueIdBySlug[venueSlug];
  if (!venueId) throw new Error(`Deal references unknown venue_slug: "${venueSlug}"`);

  const title = str(row['title']);
  if (!title) throw new Error(`Deal row missing title`);

  const rawCategory = str(row['category']);
  const categoryLabel = CATEGORY_LABELS[rawCategory] ?? rawCategory ?? 'Special';

  const daysRaw   = str(row['days']);
  const days      = daysRaw ? parseDays(daysRaw) : ALL_DAYS;
  const startTime = parseTime(row['start_time']);
  const endTime   = parseTime(row['end_time']) || '23:59';
  const scheduleSummary = buildScheduleSummary(days, startTime, endTime);

  const listingSlug = slugify(`${venueSlug}-${title}`);
  const listingId   = ulid();

  await client.query(
    `insert into listings (
       id, venue_id, slug, title, description, category_label,
       schedule_summary, conditions, source_note, cuisine,
       status, trust_band, visibility_state, confidence_score,
       published_at, last_verified_at
     ) values ($1,$2,$3,$4,$5,$6,$7,'','founder_entered','',
       'active','founder_verified','visible',0.9,now(),now())
     on conflict (slug) do update set
       title            = excluded.title,
       description      = excluded.description,
       category_label   = excluded.category_label,
       schedule_summary = excluded.schedule_summary,
       updated_at       = now()`,
    [listingId, venueId, listingSlug, title, str(row['description']), categoryLabel, scheduleSummary],
  );

  // Schedules
  await client.query('delete from listing_schedules where listing_id = $1', [listingId]);
  for (const day of days) {
    const schedId = ulid();
    await client.query(
      `insert into listing_schedules (id, listing_id, day_of_week, start_time_local, end_time_local, timezone)
       values ($1, $2, $3, $4, $5, 'America/New_York')
       on conflict (id) do nothing`,
      [schedId, listingId, day, startTime, endTime],
    );
  }

  // Tags
  const tagsRaw = str(row['tags']);
  if (tagsRaw) {
    const tags = tagsRaw.split(',').map((t: string) => t.trim()).filter(Boolean);
    for (const tag of tags) {
      await client.query(
        `insert into listing_tags (listing_id, tag) values ($1, $2) on conflict do nothing`,
        [listingId, tag],
      );
    }
  }

  listingCount++;
  console.log(`  ✓ ${title} @ ${venueSlug}`);
}

console.log(`\n  ${listingCount} listings inserted.\n`);
console.log('Import complete.');
await client.end();
