import 'dotenv/config';

import { getPool } from '../db/pool.js';

const batchSize = Number(process.env.WORKER_BATCH_SIZE ?? 50);

export async function runOutboxRelay(): Promise<number> {
  const result = await getPool().query<{ id: string }>(
    `
      update outbox_events
      set status = 'published', published_at = now(), attempts = attempts + 1
      where id in (
        select id from outbox_events
        where status in ('pending', 'failed')
        order by occurred_at asc
        limit $1
      )
      returning id
    `,
    [batchSize],
  );
  console.log(JSON.stringify({ worker: 'outbox-relay', published: result.rowCount }));
  return result.rowCount ?? 0;
}

runOutboxRelay().catch((error) => {
  console.error(error);
  process.exit(1);
});
