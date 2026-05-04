import { readFileSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

describe('migration sanity', () => {
  const migration = readFileSync(
    new URL('../../services/api/migrations/0001_platform_foundation.sql', import.meta.url),
    'utf8',
  );
  const productionAlignmentMigration = readFileSync(
    new URL('../../services/api/migrations/0002_production_alignment.sql', import.meta.url),
    'utf8',
  );

  it('includes PostGIS and search foundations', () => {
    expect(migration).toContain('create extension if not exists postgis');
    expect(migration).toContain('create extension if not exists pg_trgm');
    expect(migration).toContain('search_documents');
  });

  it('creates partitioned event tables and idempotency support', () => {
    expect(migration).toContain('partition by range (created_at)');
    expect(migration).toContain('create table outbox_events');
    expect(migration).toContain('create table idempotency_keys');
  });

  it('keeps app contract enums and durable notification tables in schema', () => {
    expect(migration).toContain('merchant_confirmed');
    expect(migration).toContain('report_expired');
    expect(migration).toContain('marketing_announcements');
    expect(migration).toContain('create table notifications');
    expect(migration).toContain('create table device_registrations');
    expect(migration).toContain('create table telemetry_events');
  });

  it('adds production alignment changes additively', () => {
    expect(productionAlignmentMigration).toContain('create table if not exists listing_offers');
    expect(productionAlignmentMigration).toContain("add value if not exists 'macos'");
    expect(productionAlignmentMigration).toContain('alter column push_token drop not null');
    expect(productionAlignmentMigration).toContain('alter column contribution_id drop not null');
  });
});
