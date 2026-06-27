/**
 * Shared helpers for Phase 1 characterization tests.
 *
 * Characterization tests pin the CURRENT observed behavior of the system so that
 * any future change in behavior is surfaced by a failing test — even where the
 * current behavior may be "wrong". They must be deterministic and isolated.
 *
 * Two determinism hazards in this codebase are handled here:
 *  1. The in-memory `DealDropPlatform` mutates a module-level `atlantaSeed`
 *     singleton. Tests that mutate must construct a platform over a *fresh clone*
 *     of the seed (`freshSeed()`), never the shared default.
 *  2. Several read responses carry a per-request id (`requestId: "req-N"`) that
 *     increments per Fastify instance. `stripVolatile()` removes those so route
 *     snapshots stay stable.
 */
import { atlantaSeed, type LaunchSeedDataset } from '../../services/api/src/db/seeds/atlanta.js';

/** A deep, independent copy of the launch seed for mutation-safe tests. */
export function freshSeed(): LaunchSeedDataset {
  return structuredClone(atlantaSeed);
}

const VOLATILE_KEYS = new Set(['requestId']);

/**
 * Recursively strip fields that are non-deterministic across runs (request ids).
 * Read endpoints over the fixed seed are otherwise fully deterministic, so this
 * is intentionally narrow — we do not want to mask real behavioral fields.
 */
export function stripVolatile<T>(value: T): T {
  if (Array.isArray(value)) {
    return value.map((item) => stripVolatile(item)) as unknown as T;
  }
  if (value && typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(value as Record<string, unknown>)) {
      if (VOLATILE_KEYS.has(key)) {
        continue;
      }
      out[key] = stripVolatile(val);
    }
    return out as T;
  }
  return value;
}
