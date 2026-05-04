import Link from 'next/link';

import { AdminShell } from '../components/admin-shell';
import { TableCard } from '../components/table-card';
import { adminApi } from '../lib/api';

export default async function DashboardPage() {
  const [metrics, moderationQueue] = await Promise.all([adminApi.dashboard(), adminApi.moderationQueue()]);
  const dashboardMetrics = [
    { label: 'Submission queue', value: `${metrics.openContributionCount} pending`, note: 'Contribution reviews waiting', tone: 'accent' },
    { label: 'Issue reports', value: `${metrics.openReportCount} open`, note: 'Reports affecting listing trust', tone: 'rose' },
    { label: 'Stale listings', value: `${metrics.staleListingCount} due`, note: 'Listings due for recheck', tone: 'warn' },
  ];
  return (
    <AdminShell eyebrow="Dashboard" title="Moderation overview">
      <section className="grid gap-4 md:grid-cols-3">
        {dashboardMetrics.map((metric) => (
          <article key={metric.label} className="panel p-6">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">{metric.label}</p>
            <p className="mt-3 text-3xl font-semibold">{metric.value}</p>
            <p className="mt-2 text-sm text-[var(--body)]">{metric.note}</p>
          </article>
        ))}
      </section>

      <section className="mt-6 grid gap-6 lg:grid-cols-[1.4fr_1fr]">
        <TableCard
          title="High-impact listings"
          subtitle="Trust and freshness watchlist for operator triage."
          columns={['Venue', 'Trust', 'Freshness', 'Action']}
          rows={metrics.highRiskListings.map((listing) => [
            <div key={`${listing.id}-venue`}>
              <p className="font-semibold">{listing.venueName}</p>
              <p className="mt-1 text-xs text-[var(--body)]">{listing.title}</p>
            </div>,
            <span key={`${listing.id}-trust`} className="pill">
              {listing.trustBand.replace(/_/g, ' ')}
            </span>,
            <span key={`${listing.id}-fresh`}>{listing.freshnessText}</span>,
            <Link key={`${listing.id}-link`} href={`/listings/${listing.id}`} className="font-semibold text-amber-700">
              Review
            </Link>,
          ])}
        />

        <section className="panel p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Contributor health</p>
          <h3 className="mt-3 text-3xl font-semibold">92% approval accuracy</h3>
          <p className="mt-3 text-sm leading-6 text-[var(--body)]">
            Higher-trust contributors are currently carrying 61% of successful freshness confirmations.
          </p>
          <div className="mt-8 rounded-[24px] bg-[var(--panel-strong)] p-5">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Queue SLA</p>
            <p className="mt-2 text-2xl font-semibold">12m median review time</p>
          </div>
          <div className="mt-6 space-y-3">
            {moderationQueue.map((item) => (
              <div key={item.id} className="rounded-[20px] border border-[var(--line)] bg-white px-4 py-3">
                <p className="font-semibold">{item.title}</p>
                <p className="mt-1 text-sm text-[var(--body)]">{item.subtitle}</p>
              </div>
            ))}
          </div>
        </section>
      </section>
    </AdminShell>
  );
}
