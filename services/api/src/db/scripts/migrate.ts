import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

import { Client } from 'pg';

import { parseRuntimeEnv } from '@dealdrop/config';

async function main() {
  const env = parseRuntimeEnv(process.env);
  const migrationsDir = join(process.cwd(), 'migrations');
  const migrationFiles = (await readdir(migrationsDir)).filter((file) => file.endsWith('.sql')).sort();
  const client = new Client({ connectionString: env.DATABASE_URL });
  await client.connect();
  try {
    for (const migrationFile of migrationFiles) {
      const sql = await readFile(join(migrationsDir, migrationFile), 'utf8');
      await client.query(sql);
      console.log(`Applied migration ${migrationFile}`);
    }
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
