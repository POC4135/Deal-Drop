import Link from 'next/link';

import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { venues } from '../../lib/mock-data';

export default function VenuesPage() {
  return (
    <AdminShell eyebrow="Catalog" title="Venues">
      <div className="mb-6 flex justify-end">
        <Link href="/venues/new" className="rounded-full bg-amber-600 px-5 py-3 text-sm font-semibold text-white">
          Create venue
        </Link>
      </div>
      <TableCard
        title="Venue registry"
        subtitle="Search-ready venue roots with geospatial metadata and active listing counts."
        columns={['Venue', 'Neighborhood', 'Active listings', 'Detail']}
        rows={venues.map((venue) => [
          <div key={`${venue.id}-name`}>
            <p className="font-semibold">{venue.name}</p>
            <p className="mt-1 text-xs text-[var(--body)]">{venue.address}</p>
          </div>,
          <span key={`${venue.id}-neighborhood`}>{venue.neighborhood}</span>,
          <span key={`${venue.id}-active`}>{venue.activeListingCount}</span>,
          <Link key={`${venue.id}-detail`} href={`/venues/${venue.id}`} className="font-semibold text-amber-700">
            Open
          </Link>,
        ])}
      />
    </AdminShell>
  );
}
