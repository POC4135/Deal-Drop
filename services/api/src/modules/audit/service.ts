export function auditAction(entityType: string, action: string): string {
  return `${entityType}.${action}`;
}
