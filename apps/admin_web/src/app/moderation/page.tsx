import Link from 'next/link';

import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { adminApi } from '../../lib/api';

export default async function ModerationPage() {
  const moderationQueue = await adminApi.moderationQueue();
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
          <Link key={`${item.id}-a`} href={`/listings/${item.entityId}`} className="font-semibold text-amber-700">
            Review
          </Link>,
        ])}
      />
    </AdminShell>
  );
}
