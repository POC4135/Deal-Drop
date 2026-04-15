import type { FastifyInstance } from 'fastify';

export async function registerHealthRoutes(app: FastifyInstance): Promise<void> {
  app.get('/health/live', async (request) => ({
    status: 'ok',
    service: 'api',
    requestId: request.requestId,
  }));

  app.get('/health/ready', async (request) => ({
    status: 'ready',
    dependencies: {
      database: 'configured',
      redis: 'configured',
      eventBus: 'configured',
    },
    requestId: request.requestId,
  }));
}
