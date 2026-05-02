/// <reference types="node" />
import 'dotenv/config';
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema/index.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  // Exclude PostGIS system tables from schema diffing.
  // venue_locations is also excluded — it uses geography(Point,4326) which
  // drizzle-kit cannot emit correctly. It is managed via raw SQL in setup.ts.
  tablesFilter: [
    '!spatial_ref_sys',
    '!geography_columns',
    '!geometry_columns',
    '!raster_columns',
    '!raster_overviews',
    '!venue_locations',
  ],
  verbose: true,
  strict: true,
});
