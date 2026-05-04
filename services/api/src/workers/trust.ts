import 'dotenv/config';

import { ulid } from 'ulid';

import { getPool } from '../db/pool.js';

export async function runTrustProjector(): Promise<number> {
  const result = await getPool().query<{ id: string; confidence_score: number; trust_band: string; visibility_state: string; fresh_until_at: Date; recheck_after_at: Date }>(`
    select id, confidence_score, trust_band, visibility_state, fresh_until_at, recheck_after_at
    from listings
    where updated_at > now() - interval '1 day'
    limit 100
  `);
  for (const row of result.rows) {
    await getPool().query(
      `
        insert into confidence_snapshots (
          id, listing_id, score, trust_band, visibility_state, fresh_until_at, recheck_after_at, created_at
        )
        values ($1, $2, $3, $4, $5, coalesce($6, now()), coalesce($7, now()), now())
      `,
      [`cfs_${ulid().toLowerCase()}`, row.id, row.confidence_score, row.trust_band, row.visibility_state, row.fresh_until_at, row.recheck_after_at],
    );
  }
  const snapshotCount = result.rowCount ?? result.rows.length;
  console.log(JSON.stringify({ worker: 'trust', snapshots: snapshotCount }));
  return snapshotCount;
}

runTrustProjector().catch((error) => {
  console.error(error);
  process.exit(1);
});
