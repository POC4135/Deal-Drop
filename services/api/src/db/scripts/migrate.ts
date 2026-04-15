import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

import { Client } from 'pg';

import { parseRuntimeEnv } from '@dealdrop/config';

async function main() {
  const env = parseRuntimeEnv(process.env);
  const filePath = join(process.cwd(), 'migrations', '0001_platform_foundation.sql');
  const sql = await readFile(filePath, 'utf8');
  const client = new Client({ connectionString: env.DATABASE_URL });
  await client.connect();
  await client.query(sql);
  await client.end();
  console.log('Applied migration 0001_platform_foundation.sql');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
