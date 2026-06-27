/**
 * Contract tests: the OpenAPI source of truth vs. the routes the app actually
 * registers. Uses Fastify route introspection (`hasRoute`) — no handler is
 * executed, so this purely checks the request contract (path + method), not
 * behavior, and never produces false 404s from handler logic.
 *
 * Two guarantees:
 *  1. Every CRITICAL documented endpoint is implemented (hard assertion).
 *  2. The set of documented endpoints NOT yet implemented is pinned as a golden
 *     master, so contract drift (new gaps, or gaps closed) surfaces in review.
 *
 * Sources: packages/contracts/openapi/dealdrop.v1.yaml, app/create-app.ts
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import { load } from 'js-yaml';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { buildSeedApp } from '../support/app.js';

type OpenApiDoc = { paths: Record<string, Record<string, unknown>> };

const HTTP_METHODS = new Set(['get', 'put', 'post', 'delete', 'patch']);

function loadContractEndpoints(): Array<{ method: string; url: string; raw: string }> {
  const file = fileURLToPath(new URL('../../packages/contracts/openapi/dealdrop.v1.yaml', import.meta.url));
  const doc = load(readFileSync(file, 'utf8')) as OpenApiDoc;
  const endpoints: Array<{ method: string; url: string; raw: string }> = [];
  for (const [path, operations] of Object.entries(doc.paths)) {
    // OpenAPI `{param}` -> Fastify `:param`
    const url = path.replace(/\{([^}]+)\}/g, ':$1');
    for (const method of Object.keys(operations)) {
      if (HTTP_METHODS.has(method.toLowerCase())) {
        endpoints.push({ method: method.toUpperCase(), url, raw: `${method.toUpperCase()} ${path}` });
      }
    }
  }
  return endpoints.sort((a, b) => a.raw.localeCompare(b.raw));
}

// Endpoints the mobile + admin clients depend on today; these MUST exist.
const CRITICAL = [
  'GET /health/ready',
  'GET /v1/feed/home',
  'GET /v1/search',
  'GET /v1/listings/map-bounds',
  'GET /v1/listings/{listingId}',
  'GET /v1/me/profile',
  'GET /v1/me/karma',
  'POST /v1/auth/sign-in',
  'POST /v1/auth/bootstrap',
  'GET /v1/leaderboards',
  'GET /v1/admin/dashboard',
];

let app: Awaited<ReturnType<typeof buildSeedApp>>;
const endpoints = loadContractEndpoints();

beforeAll(async () => {
  app = await buildSeedApp();
  await app.ready();
});

afterAll(async () => {
  await app.close();
});

const has = (method: string, url: string): boolean => {
  try {
    return app.hasRoute({ method: method as never, url });
  } catch {
    return false;
  }
};

describe('OpenAPI contract', () => {
  it('documents a stable set of endpoints', () => {
    expect(endpoints.map((e) => e.raw)).toMatchSnapshot();
  });

  it.each(CRITICAL)('implements critical endpoint %s', (raw) => {
    const [method, path] = raw.split(' ');
    const url = path.replace(/\{([^}]+)\}/g, ':$1');
    expect(has(method, url)).toBe(true);
  });

  it('pins the set of documented-but-unimplemented endpoints (contract coverage)', () => {
    const missing = endpoints.filter((e) => !has(e.method, e.url)).map((e) => e.raw);
    // Snapshot, not a hard zero — the contract is aspirational ahead of the app.
    // Any change to this set (a gap opened or closed) is surfaced for review.
    expect(missing).toMatchSnapshot();
  });
});
