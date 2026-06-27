/**
 * Unit tests for the in-memory event store.
 * Source: services/api/src/lib/events.ts
 */
import { describe, expect, it } from 'vitest';

import { InMemoryEventStore } from '../../services/api/src/lib/events.js';

const sampleEvent = {
  type: 'favorite.created',
  occurredAt: '2026-01-01T00:00:00.000Z',
  aggregateType: 'listing',
  aggregateId: 'lst_x',
  payload: { userId: 'u1', listingId: 'lst_x' },
} as const;

describe('InMemoryEventStore', () => {
  it('starts empty', async () => {
    const store = new InMemoryEventStore();
    expect(await store.list()).toEqual([]);
  });

  it('assigns an id on append and preserves the payload', async () => {
    const store = new InMemoryEventStore();
    const record = await store.append({ ...sampleEvent });
    expect(record.id).toBeTruthy();
    expect(record.type).toBe('favorite.created');
    expect(record.payload).toEqual({ userId: 'u1', listingId: 'lst_x' });
  });

  it('preserves append order and returns a defensive copy', async () => {
    const store = new InMemoryEventStore();
    await store.append({ ...sampleEvent, aggregateId: 'a' });
    await store.append({ ...sampleEvent, aggregateId: 'b' });
    const list = await store.list();
    expect(list.map((e) => e.aggregateId)).toEqual(['a', 'b']);

    // Mutating the returned array must not affect the store.
    list.pop();
    expect(await store.list()).toHaveLength(2);
  });

  it('assigns unique ids across appends', async () => {
    const store = new InMemoryEventStore();
    const a = await store.append({ ...sampleEvent });
    const b = await store.append({ ...sampleEvent });
    expect(a.id).not.toBe(b.id);
  });
});
