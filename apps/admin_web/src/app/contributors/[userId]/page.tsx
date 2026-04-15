import { notFound } from 'next/navigation';

import { AdminShell } from '../../../components/admin-shell';
import { contributors } from '../../../lib/mock-data';

export function generateStaticParams() {
  return contributors.map((user) => ({ userId: user.id }));
}

export default async function ContributorPage({ params }: { params: Promise<{ userId: string }> }) {
  const { userId } = await params;
  const contributor = contributors.find((candidate) => candidate.id === userId);
  if (!contributor) {
    notFound();
  }

  return (
    <AdminShell eyebrow="Trust" title={contributor.displayName}>
      <section className="grid gap-6 md:grid-cols-3">
        <article className="panel p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Trust score</p>
          <p className="mt-3 text-4xl font-semibold">{Math.round(contributor.trustScore * 100)}%</p>
        </article>
        <article className="panel p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Accuracy</p>
          <p className="mt-3 text-4xl font-semibold">{Math.round(contributor.approvalAccuracy * 100)}%</p>
        </article>
        <article className="panel p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Current streak</p>
          <p className="mt-3 text-4xl font-semibold">{contributor.currentStreakDays} days</p>
        </article>
      </section>
    </AdminShell>
  );
}
