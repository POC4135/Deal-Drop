/**
 * Integration tier — REAL Postgres + PostGIS.
 *
 * Runs only when a database is reachable (CI provides a postgis service and runs
 * db:migrate + db:seed before tests). Locally, with no database, the whole suite
 * SKIPS cleanly rather than failing — this container has no PostGIS.
 *
 * Do-no-harm: every write is wrapped in a transaction that is ROLLED BACK, so
 * the test never mutates persisted data.
 */
import { afterAll, describe, expect, it } from 'vitest';
import { Pool } from 'pg';

const connectionString = process.env.DATABASE_URL ?? 'postgres://postgres:postgres@localhost:5432/dealdrop';

// Probe connectivity at load time with a short timeout; skip the suite if down.
let pool: Pool | undefined;
let available = false;
try {
  const probe = new Pool({ connectionString, connectionTimeoutMillis: 1500, max: 2 });
  await probe.query('select 1');
  pool = probe;
  available = true;
} catch {
  available = false;
}

afterAll(async () => {
  await pool?.end();
});

describe.skipIf(!available)('postgres integration (real DB)', () => {
  it('has the core platform tables', async () => {
    const { rows } = await pool!.query<{ table_name: string }>(
      `select table_name from information_schema.tables
       where table_schema = 'public' and table_name = any($1)`,
      [['users', 'listings', 'venues', 'confidence_snapshots', 'points_ledger']],
    );
    const names = rows.map((r) => r.table_name).sort();
    expect(names).toEqual(['confidence_snapshots', 'listings', 'points_ledger', 'users', 'venues']);
  });

  it('records applied migrations idempotently', async () => {
    const { rows } = await pool!.query<{ count: string }>('select count(*)::int as count from schema_migrations');
    expect(Number(rows[0].count)).toBeGreaterThanOrEqual(1);
    // create extension is declared `if not exists`, so re-applying is a no-op.
    await expect(pool!.query('create extension if not exists pg_trgm')).resolves.toBeTruthy();
  });

  it('has PostGIS available and computes a geography distance', async () => {
    const { rows } = await pool!.query<{ meters: number }>(
      `select st_distance(
         st_setsrid(st_makepoint(-84.4112, 33.7867), 4326)::geography,
         st_setsrid(st_makepoint(-84.3873, 33.7815), 4326)::geography
       ) as meters`,
    );
    expect(rows[0].meters).toBeGreaterThan(2000);
    expect(rows[0].meters).toBeLessThan(3000);
  });

  it('contains seeded launch-market data', async () => {
    const { rows } = await pool!.query<{ count: string }>('select count(*)::int as count from venues');
    expect(Number(rows[0].count)).toBeGreaterThan(0);
  });

  it('enforces the users primary-key constraint (rolled back)', async () => {
    const client = await pool!.connect();
    try {
      await client.query('begin');
      const existing = await client.query<{ id: string }>('select id from users limit 1');
      expect(existing.rowCount).toBeGreaterThan(0);
      const dupeId = existing.rows[0].id;
      await expect(
        client.query('insert into users (id, email, role) values ($1, $2, $3)', [
          dupeId,
          `dupe_${dupeId}@dealdrop.test`,
          'user',
        ]),
      ).rejects.toThrow();
    } finally {
      // Always roll back — the insert above must never persist.
      await client.query('rollback');
      client.release();
    }
  });
});
