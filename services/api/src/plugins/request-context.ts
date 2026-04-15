import { randomUUID } from 'node:crypto';

import type { FastifyInstance } from 'fastify';

export async function registerRequestContext(app: FastifyInstance): Promise<void> {
  app.addHook('onRequest', async (request) => {
    request.requestId = request.headers['x-request-id']?.toString() ?? randomUUID();
  });
}
