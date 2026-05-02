/**
 * Runs pending Drizzle migrations from the ./drizzle folder.
 * Used in CI and production deployments.
 *
 * For local development, prefer `pnpm db:push` (no migration files needed).
 *
 * Usage: pnpm db:migrate
 */
import 'dotenv/config';
import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set.');
}

const client = postgres(process.env.DATABASE_URL, { max: 1 });
const db = drizzle(client);

console.log('Running migrations...');
await migrate(db, { migrationsFolder: './drizzle' });
console.log('Migrations complete.');

await client.end();
