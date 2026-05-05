import Link from 'next/link';

import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { adminApi } from '../../lib/api';

export default async function ListingsPage() {
  const listings = await adminApi.listings();
  return (
    <AdminShell eyebrow="Catalog" title="Listings">
      <div className="mb-6 flex justify-end">
        <Link href="/listings/new" className="rounded-full bg-[var(--accent)] px-5 py-3 text-sm font-semibold text-white shadow-sm hover:bg-[var(--accent-strong)]">
          Create listing
        </Link>
      </div>
      <TableCard
        title="Listing registry"
        subtitle="Feed-eligible deals with trust, freshness, and moderation context."
        columns={['Listing', 'Trust', 'Confidence', 'Detail']}
        rows={listings.map((listing) => [
          <div key={`${listing.id}-title`}>
            <p className="font-semibold">{listing.title}</p>
            <p className="mt-1 text-xs text-[var(--body)]">{listing.venueName}</p>
          </div>,
          <span key={`${listing.id}-trust`} className="pill">
            {listing.trustBand.replace(/_/g, ' ')}
          </span>,
          <span key={`${listing.id}-score`}>{Math.round(listing.confidenceScore * 100)}%</span>,
          <Link key={`${listing.id}-detail`} href={`/listings/${listing.id}`} className="font-semibold text-[var(--accent)]">
            Open
          </Link>,
        ])}
      />
    </AdminShell>
  );
}
