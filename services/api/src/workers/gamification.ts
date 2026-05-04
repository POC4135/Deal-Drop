import 'dotenv/config';

import { getPool } from '../db/pool.js';

export async function runGamificationProjector(): Promise<number> {
  const result = await getPool().query(`
    update points_ledger
    set status = 'finalized'
    where status = 'pending'
      and created_at < now() - interval '15 minutes'
  `);
  console.log(JSON.stringify({ worker: 'gamification', finalizedPoints: result.rowCount }));
  return result.rowCount ?? 0;
}

runGamificationProjector().catch((error) => {
  console.error(error);
  process.exit(1);
});
