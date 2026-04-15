import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { auditEntries } from '../../lib/mock-data';

export default function AuditPage() {
  return (
    <AdminShell eyebrow="Trust" title="Audit log">
      <TableCard
        title="Privileged activity"
        subtitle="Admin and system events written for reviewability and export."
        columns={['Action', 'Entity', 'Actor', 'At']}
        rows={auditEntries.map((entry) => [
          <span key={`${entry.id}-a`} className="font-semibold">
            {entry.action}
          </span>,
          <span key={`${entry.id}-e`}>
            {entry.entityType} / {entry.entityId}
          </span>,
          <span key={`${entry.id}-actor`}>{entry.actor}</span>,
          <span key={`${entry.id}-time`}>{entry.createdAt}</span>,
        ])}
      />
    </AdminShell>
  );
}
