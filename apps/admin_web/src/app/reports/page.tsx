import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { adminApi } from '../../lib/api';

export default async function ReportsPage() {
  const reportQueue = await adminApi.reportsQueue();
  return (
    <AdminShell eyebrow="Queues" title="Reports queue">
      <TableCard
        title="Open reports"
        subtitle="Report workflow feeding trust penalties and stale suppression logic."
        columns={['Report', 'Neighborhood', 'Status']}
        rows={reportQueue.map((item) => [
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
