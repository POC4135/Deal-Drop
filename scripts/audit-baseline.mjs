// Dependency-advisory ratchet. Compares the current `pnpm audit` report against
// security/audit-baseline.json and fails only on advisories NOT in the baseline
// (i.e. newly introduced) — the security analogue of the coverage ratchet.
//
//   node scripts/audit-baseline.mjs check   # exit 1 if new advisories exist
//   node scripts/audit-baseline.mjs write   # regenerate the baseline
import fs from 'node:fs';

const BASELINE = 'security/audit-baseline.json';
const REPORT = 'test-results/pnpm-audit.json';
const cmd = process.argv[2] ?? 'check';

const report = JSON.parse(fs.readFileSync(REPORT, 'utf8'));
const advisories = report.advisories ?? {};
const current = Object.values(advisories)
  .map((a) => ({
    id: a.github_advisory_id ?? String(a.id),
    severity: a.severity,
    module: a.module_name ?? '?',
    title: a.title,
  }))
  .sort((x, y) => x.id.localeCompare(y.id));

if (cmd === 'write') {
  const out = {
    _comment:
      'Baseline of KNOWN, pre-existing dependency advisories. security-scan.sh blocks only on advisories NOT listed here. Shrink as deps are upgraded. Regenerate: UPDATE_AUDIT_BASELINE=1 pnpm security:scan',
    counts: report.metadata?.vulnerabilities,
    acknowledged: current.map((a) => a.id),
    details: current,
  };
  fs.writeFileSync(BASELINE, JSON.stringify(out, null, 2) + '\n');
  console.log(`baseline updated: ${current.length} advisories`);
  process.exit(0);
}

const baseline = fs.existsSync(BASELINE) ? JSON.parse(fs.readFileSync(BASELINE, 'utf8')) : { acknowledged: [] };
const known = new Set(baseline.acknowledged ?? []);
const fresh = current.filter((a) => !known.has(a.id));
const c = report.metadata?.vulnerabilities ?? {};
console.log(`advisories: ${current.length} total (crit ${c.critical ?? 0}/high ${c.high ?? 0}/mod ${c.moderate ?? 0}/low ${c.low ?? 0}); ${known.size} baselined; ${fresh.length} new`);

if (fresh.length) {
  console.log('NEW advisories (not in baseline):');
  for (const a of fresh) console.log(`  - ${a.id} [${a.severity}] ${a.module}: ${a.title}`);
  process.exit(1);
}
process.exit(0);
