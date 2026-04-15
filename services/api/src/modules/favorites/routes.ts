import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

const paramsSchema = z.object({ listingId: z.string() });

export async function registerFavoriteRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.post('/v1/favorites/:listingId', async (request, reply) => {
    const { listingId } = paramsSchema.parse(request.params);
    await platform.addFavorite(request.auth.userId, listingId);
    return reply.code(204).send();
  });

  app.delete('/v1/favorites/:listingId', async (request, reply) => {
    const { listingId } = paramsSchema.parse(request.params);
    await platform.removeFavorite(request.auth.userId, listingId);
    return reply.code(204).send();
  });

  app.post('/v1/favorites/sync', async (request) => {
    const body = z.object({ listingIds: z.array(z.string()).default([]) }).parse(request.body);
    return platform.syncFavorites(request.auth.userId, body.listingIds);
  });

  app.post('/v1/saved', async (request, reply) => {
    const body = z.object({ listingId: z.string() }).parse(request.body);
    await platform.addFavorite(request.auth.userId, body.listingId);
    return reply.code(204).send();
  });

  app.delete('/v1/saved', async (request, reply) => {
    const body = z.object({ listingId: z.string() }).parse(request.body);
    await platform.removeFavorite(request.auth.userId, body.listingId);
    return reply.code(204).send();
  });
}
