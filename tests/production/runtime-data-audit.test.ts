import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { describe, expect, it } from 'vitest';

const runtimeRoots = [
  'apps/mobile_flutter/lib',
  'apps/admin_web/src',
  'services/api/src',
  'packages/config/src',
  'packages/shared_types/src',
];

const forbidden = /\b(seed|fallback|mock|dummy|placeholder)\b|dealdrop\.local/i;
const repoRoot = fileURLToPath(new URL('../../', import.meta.url));

function collectFiles(path: string): string[] {
  const stat = statSync(path);
  if (stat.isFile()) {
    return [path];
  }
  return readdirSync(path).flatMap((entry) => collectFiles(join(path, entry)));
}

describe('production runtime data audit', () => {
  it('keeps runtime code free of seed, fallback, and dummy data markers', () => {
    const offenders = runtimeRoots.flatMap((root) =>
      collectFiles(join(repoRoot, root)).flatMap((file) => {
        const content = readFileSync(file, 'utf8');
        return forbidden.test(content) ? [file] : [];
      }),
    );

    expect(offenders).toEqual([]);
  });
});
