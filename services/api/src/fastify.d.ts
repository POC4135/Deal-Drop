import type { Role } from '@dealdrop/shared-types';

declare module 'fastify' {
  interface FastifyRequest {
    requestId: string;
    auth: {
      userId: string;
      email: string;
      role: Role;
      displayName: string;
      verifiedContributor: boolean;
    };
  }
}
