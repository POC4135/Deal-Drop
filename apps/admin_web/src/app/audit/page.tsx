import { AdminShell } from '../../components/admin-shell';
import { TableCard } from '../../components/table-card';
import { adminApi } from '../../lib/api';

export default async function AuditPage() {
  const auditEntries = await adminApi.audit();
  return (
    <AdminShell eyebrow="Trust" title="Audit log">
      <TableCard
        title="Privileged activity"
        subtitle="Admin and system events written for reviewability and export."
        columns={['Action', 'Entity', 'Actor', 'At']}
        rows={auditEntries.map((entry) => [
          <span key={`${entry.id}-a`} className="font-semibold">
            {entry.type}
          </span>,
          <span key={`${entry.id}-e`}>
            {entry.aggregateType} / {entry.aggregateId}
          </span>,
          <span key={`${entry.id}-actor`}>system</span>,
          <span key={`${entry.id}-time`}>{entry.occurredAt}</span>,
        ])}
      />
    </AdminShell>
  );
}
