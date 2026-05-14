import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

const listingParamsSchema = z.object({
  listingId: z.string(),
});

const venueParamsSchema = z.object({
  venueId: z.string(),
});

const confirmBodySchema = z.object({
  proofAssetKey: z.string().optional(),
});

export async function registerListingRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.get('/v1/listings/:listingId', async (request, reply) => {
    const { listingId } = listingParamsSchema.parse(request.params);
    const listing = await platform.getListingDetail(listingId, request.auth.userId);
    if (!listing) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    return listing;
  });

  app.get('/v1/venues/:venueId', async (request, reply) => {
    const { venueId } = venueParamsSchema.parse(request.params);
    const venue = await platform.getVenueDetail(venueId);
    if (!venue) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    return venue;
  });

  app.post('/v1/listings/:listingId/confirm', async (request) => {
    const { listingId } = listingParamsSchema.parse(request.params);
    confirmBodySchema.parse(request.body ?? {});
    return platform.confirmListing(request.auth.userId, listingId);
  });

  app.post('/v1/listings/:listingId/report-expired', async (request) => {
    const { listingId } = listingParamsSchema.parse(request.params);
    const payload = z.object({ reason: z.string(), notes: z.string().optional() }).parse(request.body);
    return platform.reportExpired(request.auth.userId, listingId, payload);
  });

  app.post('/v1/listings/:listingId/report', async (request) => {
    const { listingId } = listingParamsSchema.parse(request.params);
    const payload = z.object({ reason: z.string(), notes: z.string().optional() }).parse(request.body);
    return platform.reportExpired(request.auth.userId, listingId, payload);
  });

  app.get('/v1/listings/:listingId/images', async (request, reply) => {
    const { listingId } = listingParamsSchema.parse(request.params);
    const listing = await platform.getListingDetail(listingId, request.auth.userId);
    if (!listing) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    return platform.getListingImages(listingId);
  });

  app.post('/v1/listings/:listingId/images/presign', async (request, reply) => {
    const { listingId } = listingParamsSchema.parse(request.params);
    const { contentType } = z.object({ contentType: z.string() }).parse(request.body);
    const listing = await platform.getListingDetail(listingId, request.auth.userId);
    if (!listing) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    return platform.presignListingImageUpload(request.auth.userId, listingId, contentType);
  });

  app.post('/v1/listings/:listingId/images/confirm', async (request, reply) => {
    const { listingId } = listingParamsSchema.parse(request.params);
    const { assetKey } = z.object({ assetKey: z.string() }).parse(request.body);
    const listing = await platform.getListingDetail(listingId, request.auth.userId);
    if (!listing) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    await platform.confirmListingImageUpload(request.auth.userId, listingId, assetKey);
    return { ok: true };
  });
}
