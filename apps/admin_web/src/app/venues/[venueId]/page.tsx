import { AdminShell } from '../../../components/admin-shell';
import { adminApi } from '../../../lib/api';

export default async function VenueDetailPage({ params }: { params: Promise<{ venueId: string }> }) {
  const { venueId } = await params;
  const venue = (await adminApi.venues()).find((candidate) => candidate.id === venueId);
  if (!venue) return <AdminShell eyebrow="Catalog" title="Venue not found"><section className="panel p-8">No live venue exists for this id.</section></AdminShell>;

  return (
    <AdminShell eyebrow="Catalog" title={venue.name}>
      <section className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <article className="panel p-8">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Venue details</p>
          <dl className="mt-6 grid gap-5 md:grid-cols-2">
            <div>
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Neighborhood</dt>
              <dd className="mt-2 text-lg font-semibold">{venue.neighborhood}</dd>
            </div>
            <div>
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Rating</dt>
              <dd className="mt-2 text-lg font-semibold">{venue.rating.toFixed(1)}</dd>
            </div>
            <div className="md:col-span-2">
              <dt className="text-xs uppercase tracking-[0.16em] text-[var(--muted)]">Address</dt>
              <dd className="mt-2 text-lg font-semibold">{venue.address}</dd>
            </div>
          </dl>
        </article>

        <article className="panel p-8">
          <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Operational hooks</p>
          <ul className="mt-5 space-y-3 text-sm text-[var(--body)]">
            <li>Geofence radius defaults to 120m for proof and on-site confirmations.</li>
            <li>Search document and map projection refresh on any venue edit.</li>
            <li>Listing create/edit keeps venue as the owning geospatial root.</li>
          </ul>
        </article>
      </section>
    </AdminShell>
  );
}
