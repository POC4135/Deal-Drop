import type { ModerationDecision } from '@dealdrop/shared-types';

export function requiresProof(decision: ModerationDecision): boolean {
  return decision === 'request_proof';
}
