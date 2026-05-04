import { Pool } from 'pg';

import { parseRuntimeEnv } from '@dealdrop/config';

let pool: Pool | undefined;

export function getPool(): Pool {
  if (!pool) {
    const env = parseRuntimeEnv(process.env);
    pool = new Pool({ connectionString: env.DATABASE_URL });
  }
  return pool;
}

export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = undefined;
  }
}
