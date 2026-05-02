/**
 * Database setup — run once before the first `db:push`, and again after.
 *
 * Pass 1 (before db:push):
 *   - Creates required Postgres extensions:
 *       postgis    → geography type + spatial indexes
 *       pg_trgm   → trigram similarity for search suggestions
 *       btree_gin → GIN index support for composite queries
 *
 * Pass 2 (after db:push):
 *   - Creates the venue_locations table (PostGIS geography column that
 *     drizzle-kit cannot emit correctly — it quotes the type name).
 *   - Creates the GIST spatial index on venue_locations.location.
 *
 * Safe to run multiple times — all statements use IF NOT EXISTS / IF EXISTS.
 *
 * Usage: pnpm db:setup
 */
import 'dotenv/config';
import postgres from 'postgres';

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set.');
}

const sql = postgres(process.env.DATABASE_URL, { max: 1 });

try {
  // ── Extensions ────────────────────────────────────────────────────────────
  console.log('Creating extensions...');
  await sql`CREATE EXTENSION IF NOT EXISTS postgis`;
  await sql`CREATE EXTENSION IF NOT EXISTS pg_trgm`;
  await sql`CREATE EXTENSION IF NOT EXISTS btree_gin`;
  console.log('Extensions ready.');

  // ── venue_locations ───────────────────────────────────────────────────────
  // Managed here rather than via drizzle-kit because drizzle-kit wraps custom
  // type names in double quotes ("geography(Point,4326)"), which PostgreSQL
  // rejects. This table is excluded from drizzle.config.ts tablesFilter.
  const [venuesExists] = await sql`
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'venues' AND table_schema = 'public'
  `;

  if (venuesExists) {
    console.log('Creating venue_locations table...');
    await sql`
      CREATE TABLE IF NOT EXISTS venue_locations (
        venue_id    uuid PRIMARY KEY
                    REFERENCES venues(id) ON DELETE CASCADE,
        location    geography(Point, 4326) NOT NULL,
        created_at  timestamptz DEFAULT now() NOT NULL,
        updated_at  timestamptz DEFAULT now() NOT NULL
      )
    `;
    await sql`
      CREATE INDEX IF NOT EXISTS idx_venue_locations_venue_id
      ON venue_locations (venue_id)
    `;
    await sql`
      CREATE INDEX IF NOT EXISTS idx_venue_locations_gist
      ON venue_locations USING GIST (location)
    `;
    console.log('venue_locations ready.');
  } else {
    console.log(
      'Skipping venue_locations — venues table not found yet. Run db:push first, then db:setup again.',
    );
  }

  console.log('Setup complete.');
} finally {
  await sql.end();
}
