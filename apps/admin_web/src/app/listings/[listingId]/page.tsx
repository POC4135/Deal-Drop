import { AdminShell } from '../../../components/admin-shell';
import { adminApi } from '../../../lib/api';

export default async function ListingDetailPage({ params }: { params: Promise<{ listingId: string }> }) {
  const { listingId } = await params;
  const listing = (await adminApi.listings()).find((candidate) => candidate.id === listingId);
  if (!listing) return <AdminShell eyebrow="Catalog" title="Listing not found"><section className="panel p-8">No live listing exists for this id.</section></AdminShell>;

  return (
    <AdminShell eyebrow="Catalog" title={listing.title}>
      <section className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <article className="panel p-8">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Listing profile</p>
          <dl className="mt-6 grid gap-5 md:grid-cols-2">
            <div>
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Venue</dt>
              <dd className="mt-2 text-lg font-semibold">{listing.venueName}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Trust band</dt>
              <dd className="mt-2 text-lg font-semibold">{listing.trustBand.replace(/_/g, ' ')}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Confidence</dt>
              <dd className="mt-2 text-lg font-semibold">{Math.round(listing.confidenceScore * 100)}%</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Fresh until</dt>
              <dd className="mt-2 text-lg font-semibold">{listing.freshUntilAt}</dd>
            </div>
            <div className="md:col-span-2">
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Conditions</dt>
              <dd className="mt-2 text-lg font-semibold">{listing.conditions}</dd>
            </div>
          </dl>
        </article>

        <article className="panel p-8">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Operator actions</p>
          <div className="mt-5 space-y-3">
            {['Approve change', 'Request proof', 'Push stale recheck', 'Suppress listing'].map((action) => (
              <button key={action} className="w-full rounded-[20px] border border-[var(--line)] bg-white px-4 py-3 text-left font-semibold">
                {action}
              </button>
            ))}
          </div>
        </article>
      </section>
    </AdminShell>
  );
}
