/**
 * Unit tests for cursor pagination — boundary and edge coverage.
 * Source: services/api/src/lib/pagination.ts
 */
import { describe, expect, it } from 'vitest';

import { applyCursorPagination, decodeCursor, encodeCursor } from '../../services/api/src/lib/pagination.js';

const items = (n: number) => Array.from({ length: n }, (_, i) => ({ id: `id_${i}` }));

describe('encode/decode cursor', () => {
  it('round-trips an arbitrary id', () => {
    expect(decodeCursor(encodeCursor('id_42'))).toBe('id_42');
  });

  it('decodes undefined to undefined', () => {
    expect(decodeCursor(undefined)).toBeUndefined();
  });
});

describe('applyCursorPagination', () => {
  it('returns the first page and a next cursor when more remain', () => {
    const page = applyCursorPagination(items(10), undefined, 3);
    expect(page.items.map((i) => i.id)).toEqual(['id_0', 'id_1', 'id_2']);
    expect(decodeCursor(page.nextCursor ?? undefined)).toBe('id_2');
  });

  it('continues from a cursor', () => {
    const page = applyCursorPagination(items(10), encodeCursor('id_2'), 3);
    expect(page.items.map((i) => i.id)).toEqual(['id_3', 'id_4', 'id_5']);
  });

  it('returns null next cursor on the last page', () => {
    const page = applyCursorPagination(items(5), encodeCursor('id_1'), 10);
    expect(page.items.map((i) => i.id)).toEqual(['id_2', 'id_3', 'id_4']);
    expect(page.nextCursor).toBeNull();
  });

  it('handles an empty collection', () => {
    const page = applyCursorPagination([], undefined, 10);
    expect(page.items).toEqual([]);
    expect(page.nextCursor).toBeNull();
  });

  it('treats a cursor whose id is absent as starting from the top', () => {
    // findIndex returns -1, +1 => 0 => starts at the beginning (documented behavior).
    const page = applyCursorPagination(items(4), encodeCursor('does_not_exist'), 2);
    expect(page.items.map((i) => i.id)).toEqual(['id_0', 'id_1']);
  });

  it('returns exactly `limit` items when the collection is larger', () => {
    const page = applyCursorPagination(items(100), undefined, 20);
    expect(page.items).toHaveLength(20);
  });
});
