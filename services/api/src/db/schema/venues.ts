import {
  boolean,
  index,
  pgTable,
  smallint,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';

export const venues = pgTable(
  'venues',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: text('name').notNull(),
    slug: text('slug').unique().notNull(),
    addressLine1: text('address_line_1').notNull(),
    addressLine2: text('address_line_2'),
    city: text('city').notNull(),
    state: text('state').notNull(),
    postalCode: text('postal_code'),
    neighborhood: text('neighborhood'),
    googlePlaceId: text('google_place_id').unique(),
    phone: text('phone'),
    website: text('website'),
    priceBand: smallint('price_band'),
    isActive: boolean('is_active').default(true).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => [
    index('idx_venues_neighborhood').on(t.neighborhood),
    index('idx_venues_city_active').on(t.city, t.isActive),
  ],
);

// venue_locations is NOT a Drizzle-managed table.
// drizzle-kit cannot emit geography(Point,4326) correctly (it quotes the type
// name as an identifier). The table is created and indexed via raw SQL in
// src/db/setup.ts which runs after db:push.
//
// Use this type for query-time TypeScript inference when selecting from
// venue_locations via db.execute() or sql`` tagged template queries.
export type VenueLocation = {
  venueId: string;
  // ST_AsText() returns WKT; ST_AsGeoJSON() returns GeoJSON string.
  location: string;
  createdAt: Date;
  updatedAt: Date;
};
