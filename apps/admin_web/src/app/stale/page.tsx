import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { staleQueue } from '../../lib/mock-data';

export default function StalePage() {
  return (
    <AdminShell eyebrow="Queues" title="Stale listings">
      <TableCard
        title="Recheck SLA"
        subtitle="Listings waiting for fresh proof, confirmation, or moderator override."
        columns={['Listing', 'Neighborhood', 'Due state']}
        rows={staleQueue.map((item) => [
          <div key={`${item.id}-item`}>
            <p className="font-semibold">{item.title}</p>
            <p className="mt-1 text-xs text-[var(--body)]">{item.subtitle}</p>
          </div>,
          <span key={`${item.id}-n`}>{item.neighborhood}</span>,
          <span key={`${item.id}-s`} className="pill">
            {item.status}
          </span>,
        ])}
      />
    </AdminShell>
  );
}
