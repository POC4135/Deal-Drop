import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

const paramsSchema = z.object({
  listingId: z.string(),
  venueId: z.string().optional(),
});

const confirmBodySchema = z.object({
  proofAssetKey: z.string().optional(),
});

export async function registerListingRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.get('/v1/listings/:listingId', async (request, reply) => {
    const { listingId } = paramsSchema.parse(request.params);
    const listing = await platform.getListingDetail(listingId, request.auth.userId);
    if (!listing) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    return listing;
  });

  app.get('/v1/venues/:venueId', async (request, reply) => {
    const { venueId } = paramsSchema.parse(request.params);
    const venue = await platform.getVenueDetail(venueId);
    if (!venue) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    return venue;
  });

  app.post('/v1/listings/:listingId/confirm', async (request) => {
    const { listingId } = paramsSchema.parse(request.params);
    confirmBodySchema.parse(request.body ?? {});
    return platform.confirmListing(request.auth.userId, listingId);
  });

  app.post('/v1/listings/:listingId/report-expired', async (request) => {
    const { listingId } = paramsSchema.parse(request.params);
    const payload = z.object({ reason: z.string(), notes: z.string().optional() }).parse(request.body);
    return platform.reportExpired(request.auth.userId, listingId, payload);
  });

  app.post('/v1/listings/:listingId/report', async (request) => {
    const { listingId } = paramsSchema.parse(request.params);
    const payload = z.object({ reason: z.string(), notes: z.string().optional() }).parse(request.body);
    return platform.reportExpired(request.auth.userId, listingId, payload);
  });
}
