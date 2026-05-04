import 'dotenv/config';

import { ulid } from 'ulid';

import { getPool } from '../db/pool.js';

export async function runStaleScan(): Promise<number> {
  const result = await getPool().query<{ id: string }>(`
    update listings
    set status = case when status = 'active' then 'stale' else status end,
        trust_band = case when trust_band in ('founder_verified', 'merchant_confirmed') then trust_band else 'needs_recheck' end,
        updated_at = now()
    where recheck_after_at is not null
      and recheck_after_at < now()
      and status in ('active', 'stale')
    returning id
  `);
  for (const row of result.rows) {
    await getPool().query(
      `
        insert into outbox_events (id, event_type, aggregate_type, aggregate_id, payload, status, idempotency_key, occurred_at)
        values ($1, 'listing.stale-scan-requested', 'listing', $2, $3, 'pending', $4, now())
        on conflict (idempotency_key) do nothing
      `,
      [`evt_${ulid().toLowerCase()}`, row.id, { listingId: row.id }, `stale-scan:${row.id}`],
    );
  }
  console.log(JSON.stringify({ worker: 'stale-scan', staleListings: result.rowCount }));
  return result.rowCount ?? 0;
}

runStaleScan().catch((error) => {
  console.error(error);
  process.exit(1);
});
