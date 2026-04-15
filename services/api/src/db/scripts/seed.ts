import { Client } from 'pg';

import { parseRuntimeEnv } from '@dealdrop/config';

import { atlantaSeed } from '../seeds/atlanta.js';

async function main() {
  const env = parseRuntimeEnv(process.env);
  const client = new Client({ connectionString: env.DATABASE_URL });
  await client.connect();

  for (const user of atlantaSeed.users) {
    await client.query(
      `
        insert into users (id, email, role)
        values ($1, $2, $3)
        on conflict (id) do update set email = excluded.email, role = excluded.role
      `,
      [user.id, user.email, user.role],
    );

    await client.query(
      `
        insert into user_profiles (
          user_id,
          display_name,
          home_neighborhood,
          contributor_trust_score,
          verified_contributor,
          current_level
        )
        values ($1, $2, $3, $4, $5, $6)
        on conflict (user_id) do update set
          display_name = excluded.display_name,
          home_neighborhood = excluded.home_neighborhood,
          contributor_trust_score = excluded.contributor_trust_score,
          verified_contributor = excluded.verified_contributor,
          current_level = excluded.current_level
      `,
      [user.id, user.displayName, user.homeNeighborhood, user.verifiedContributor ? 0.8 : 0.45, user.verifiedContributor, user.verifiedContributor ? 'Verified Contributor' : 'Newcomer'],
    );
  }

  for (const venue of atlantaSeed.venues) {
    await client.query(
      `
        insert into venues (id, slug, name, rating, status)
        values ($1, $2, $3, $4, 'active')
        on conflict (id) do update set slug = excluded.slug, name = excluded.name, rating = excluded.rating
      `,
      [venue.id, venue.slug, venue.name, venue.rating],
    );

    await client.query(
      `
        insert into venue_locations (
          id,
          venue_id,
          neighborhood_name,
          neighborhood_slug,
          address,
          latitude,
          longitude,
          point
        )
        values (
          $1,
          $2,
          $3,
          lower(replace($3, ' ', '-')),
          $4,
          $5,
          $6,
          ST_SetSRID(ST_MakePoint($6, $5), 4326)::geography
        )
        on conflict (venue_id) do update set
          neighborhood_name = excluded.neighborhood_name,
          address = excluded.address,
          latitude = excluded.latitude,
          longitude = excluded.longitude,
          point = excluded.point
      `,
      [`loc_${venue.id}`, venue.id, venue.neighborhood, venue.address, venue.latitude, venue.longitude],
    );
  }

  for (const listing of atlantaSeed.listings) {
    await client.query(
      `
        insert into listings (
          id,
          venue_id,
          slug,
          title,
          description,
          category_label,
          schedule_summary,
          conditions,
          source_note,
          cuisine,
          status,
          trust_band,
          visibility_state,
          confidence_score,
          fresh_until_at,
          recheck_after_at,
          published_at,
          last_verified_at
        )
        values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'visible', $13, $14, $15, now(), $16)
        on conflict (id) do update set
          title = excluded.title,
          description = excluded.description,
          category_label = excluded.category_label,
          schedule_summary = excluded.schedule_summary,
          conditions = excluded.conditions,
          source_note = excluded.source_note,
          cuisine = excluded.cuisine,
          status = excluded.status,
          trust_band = excluded.trust_band,
          confidence_score = excluded.confidence_score,
          fresh_until_at = excluded.fresh_until_at,
          recheck_after_at = excluded.recheck_after_at,
          last_verified_at = excluded.last_verified_at
      `,
      [
        listing.id,
        listing.venueId,
        listing.slug,
        listing.title,
        listing.description,
        listing.categoryLabel,
        listing.scheduleLabel,
        listing.conditions,
        listing.sourceNote,
        listing.cuisine,
        listing.status === 'suppressed' ? 'suppressed' : listing.status === 'stale' ? 'stale' : 'active',
        listing.trustBand,
        listing.confidenceScore,
        listing.freshUntilAt,
        listing.recheckAfterAt,
        listing.lastVerifiedAt,
      ],
    );

    await client.query(`delete from listing_tags where listing_id = $1`, [listing.id]);
    for (const tag of listing.tags) {
      await client.query(`insert into listing_tags (listing_id, tag) values ($1, $2) on conflict do nothing`, [listing.id, tag]);
    }
  }

  for (const entry of atlantaSeed.pointsLedger) {
    await client.query(
      `
        insert into points_ledger (id, user_id, reason, status, points_delta, created_at)
        values ($1, $2, $3, $4, $5, $6)
        on conflict (id) do update set
          reason = excluded.reason,
          status = excluded.status,
          points_delta = excluded.points_delta,
          created_at = excluded.created_at
      `,
      [entry.id, entry.userId, entry.reason, entry.status, entry.pointsDelta, entry.createdAt],
    );
  }

  await client.end();
  console.log(`Seeded Atlanta launch data: ${atlantaSeed.venues.length} venues, ${atlantaSeed.listings.length} listings.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
