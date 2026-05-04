import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

import { Client } from 'pg';

import { parseRuntimeEnv } from '@dealdrop/config';

function splitSqlStatements(sql: string): string[] {
  return sql
    .split(';')
    .map((statement) => statement.trim())
    .filter((statement) => statement.length > 0);
}

function summarizeStatement(statement: string): string {
  return statement.replace(/\s+/g, ' ').slice(0, 160);
}

async function main() {
  const env = parseRuntimeEnv(process.env);
  const migrationsDir = join(process.cwd(), 'migrations');
  const migrationFiles = (await readdir(migrationsDir)).filter((file) => file.endsWith('.sql')).sort();
  const client = new Client({ connectionString: env.DATABASE_URL });
  await client.connect();
  try {
    await client.query(`
      create table if not exists schema_migrations (
        filename varchar(255) primary key,
        applied_at timestamptz not null default now()
      )
    `);

    for (const migrationFile of migrationFiles) {
      const applied = await client.query<{ filename: string }>(
        `select filename from schema_migrations where filename = $1`,
        [migrationFile],
      );
      if (applied.rowCount && applied.rowCount > 0) {
        console.log(`Skipping migration ${migrationFile}`);
        continue;
      }

      const sql = await readFile(join(migrationsDir, migrationFile), 'utf8');
      const statements = splitSqlStatements(sql);
      await client.query('begin');
      try {
        for (const [index, statement] of statements.entries()) {
          try {
            await client.query(statement);
          } catch (error) {
            console.error(
              `Migration ${migrationFile} failed at statement ${index + 1}/${statements.length}: ${summarizeStatement(statement)}`,
            );
            throw error;
          }
        }
        await client.query(`insert into schema_migrations (filename) values ($1)`, [migrationFile]);
        await client.query('commit');
      } catch (error) {
        await client.query('rollback');
        throw error;
      }
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
