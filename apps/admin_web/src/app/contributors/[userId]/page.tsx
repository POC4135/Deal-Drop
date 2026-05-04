import { AdminShell } from '../../../components/admin-shell';
import { adminApi } from '../../../lib/api';

export default async function ContributorPage({ params }: { params: Promise<{ userId: string }> }) {
  const { userId } = await params;
  const contributor = await adminApi.contributor(userId);

  return (
    <AdminShell eyebrow="Trust" title={contributor.profile.displayName}>
      <section className="grid gap-6 md:grid-cols-3">
        <article className="panel p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Trust score</p>
          <p className="mt-3 text-4xl font-semibold">{Math.round(contributor.trustScore * 100)}%</p>
        </article>
        <article className="panel p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Recent contributions</p>
          <p className="mt-3 text-4xl font-semibold">{contributor.recentContributions.length}</p>
        </article>
        <article className="panel p-6">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Review state</p>
          <p className="mt-3 text-4xl font-semibold">Live</p>
        </article>
      </section>
    </AdminShell>
  );
}
