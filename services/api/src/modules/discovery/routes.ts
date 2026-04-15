import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

const feedQuerySchema = z.object({
  latitude: z.coerce.number().optional(),
  longitude: z.coerce.number().optional(),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  radiusMiles: z.coerce.number().min(0.1).max(25).default(3),
});

const mapBoundsSchema = z.object({
  north: z.coerce.number(),
  south: z.coerce.number(),
  east: z.coerce.number(),
  west: z.coerce.number(),
  zoom: z.coerce.number().optional(),
  trustBand: z.string().optional(),
});

const searchQuerySchema = z.object({
  q: z.string().optional(),
  neighborhood: z.string().optional(),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  trustBand: z.string().optional(),
  sort: z.enum(['relevance', 'distance', 'confidence']).optional(),
});

export async function registerDiscoveryRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.get('/v1/feed/home', async (request) => {
    const query = feedQuerySchema.parse(request.query);
    return platform.getFeedHome(query, request.auth.userId);
  });

  app.get('/v1/listings/live-now', async (request) => {
    const query = feedQuerySchema.parse(request.query);
    return platform.getLiveNow(query.latitude, query.longitude, query.cursor, query.limit, request.auth.userId);
  });

  app.get('/v1/listings/tonight', async (request) => {
    const query = feedQuerySchema.parse(request.query);
    return platform.getTonight(query.latitude, query.longitude, query.cursor, query.limit, request.auth.userId);
  });

  app.get('/v1/listings/nearby', async (request) => {
    const query = feedQuerySchema.parse(request.query);
    return platform.getNearby(query, request.auth.userId);
  });

  app.get('/v1/listings/map-bounds', async (request) => {
    const query = mapBoundsSchema.parse(request.query);
    return platform.getMapBounds(query, request.auth.userId);
  });

  app.get('/v1/search', async (request) => {
    const query = searchQuerySchema.parse(request.query);
    return platform.search(query, request.auth.userId);
  });

  app.get('/v1/filters/metadata', async () => platform.getFiltersMetadata());

  app.get('/v1/discovery/feed', async (request) => {
    const query = feedQuerySchema.parse(request.query);
    return platform.getFeedHome(query, request.auth.userId);
  });

  app.get('/v1/discovery/map', async (request) => {
    const query = mapBoundsSchema.parse(request.query);
    return platform.getMapBounds(query, request.auth.userId);
  });
}
