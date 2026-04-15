import Link from 'next/link';

import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { moderationQueue } from '../../lib/mock-data';

export default function ModerationPage() {
  return (
    <AdminShell eyebrow="Queues" title="Moderation queue">
      <TableCard
        title="Contribution review"
        subtitle="Review new listings, updates, proofs, and duplicate-merge candidates."
        columns={['Item', 'Neighborhood', 'Priority', 'Action']}
        rows={moderationQueue.map((item) => [
          <div key={`${item.id}-item`}>
            <p className="font-semibold">{item.title}</p>
            <p className="mt-1 text-xs text-[var(--body)]">{item.subtitle}</p>
          </div>,
          <span key={`${item.id}-n`}>{item.neighborhood}</span>,
          <span key={`${item.id}-p`} className="pill">
            {item.priority}
          </span>,
          <Link key={`${item.id}-a`} href="/listings/lst_slice_combo" className="font-semibold text-amber-700">
            Review
          </Link>,
        ])}
      />
    </AdminShell>
  );
}
