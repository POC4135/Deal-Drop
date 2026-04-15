export function encodeCursor(value: string): string {
  return Buffer.from(value, 'utf8').toString('base64url');
}

export function decodeCursor(cursor: string | undefined): string | undefined {
  if (!cursor) {
    return undefined;
  }

  return Buffer.from(cursor, 'base64url').toString('utf8');
}

export function applyCursorPagination<T extends { id: string }>(
  items: T[],
  cursor: string | undefined,
  limit: number,
): { items: T[]; nextCursor: string | null } {
  const decoded = decodeCursor(cursor);
  const startIndex = decoded ? items.findIndex((item) => item.id === decoded) + 1 : 0;
  const page = items.slice(Math.max(startIndex, 0), Math.max(startIndex, 0) + limit);
  const next = items[startIndex + limit];

  return {
    items: page,
    nextCursor: next ? encodeCursor(page[page.length - 1]?.id ?? next.id) : null,
  };
}
