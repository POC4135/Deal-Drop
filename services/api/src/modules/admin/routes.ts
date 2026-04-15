import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import type { DealDropPlatform } from '../../bootstrap/platform.js';
import { requireRole } from '../../plugins/auth.js';

export async function registerAdminRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.get('/v1/admin/dashboard', { preHandler: requireRole('moderator') }, async () => platform.getAdminMetrics());

  app.get('/v1/admin/queues/moderation', { preHandler: requireRole('moderator') }, async () => platform.getModerationQueue());
  app.get('/v1/admin/queues/reports', { preHandler: requireRole('moderator') }, async () => platform.getReportsQueue());
  app.get('/v1/admin/queues/stale', { preHandler: requireRole('moderator') }, async () => platform.getStaleQueue());

  app.get('/v1/admin/contributors/:userId', { preHandler: requireRole('moderator') }, async (request) => {
    const { userId } = z.object({ userId: z.string() }).parse(request.params);
    return platform.getContributorReview(userId);
  });

  app.get('/v1/admin/audit', { preHandler: requireRole('admin') }, async () => platform.listEvents());

  app.get('/v1/admin/venues', { preHandler: requireRole('moderator') }, async () => platform.listAdminVenues());
  app.post('/v1/admin/venues', { preHandler: requireRole('moderator') }, async (request) => {
    const body = z.object({
      id: z.string().optional(),
      name: z.string(),
      neighborhood: z.string(),
      address: z.string(),
      latitude: z.number(),
      longitude: z.number(),
    }).parse(request.body);
    return platform.upsertVenue(body);
  });
  app.patch('/v1/admin/venues/:venueId', { preHandler: requireRole('moderator') }, async (request) => {
    const params = z.object({ venueId: z.string() }).parse(request.params);
    const body = z.object({
      name: z.string(),
      neighborhood: z.string(),
      address: z.string(),
      latitude: z.number(),
      longitude: z.number(),
    }).parse(request.body);
    return platform.upsertVenue({ id: params.venueId, ...body });
  });

  app.get('/v1/admin/listings', { preHandler: requireRole('moderator') }, async () => platform.listAdminListings());
  app.post('/v1/admin/listings', { preHandler: requireRole('moderator') }, async (request) => {
    const body = z.object({
      id: z.string().optional(),
      title: z.string(),
      venueId: z.string(),
      neighborhood: z.string(),
      categoryLabel: z.string().optional(),
      scheduleLabel: z.string().optional(),
      valueNote: z.string().optional(),
      cuisine: z.string().optional(),
      latitude: z.number().optional(),
      longitude: z.number().optional(),
    }).parse(request.body);
    return platform.upsertListing(body);
  });
  app.patch('/v1/admin/listings/:listingId', { preHandler: requireRole('moderator') }, async (request) => {
    const params = z.object({ listingId: z.string() }).parse(request.params);
    const body = z.object({
      title: z.string(),
      venueId: z.string(),
      neighborhood: z.string(),
      categoryLabel: z.string().optional(),
      scheduleLabel: z.string().optional(),
      valueNote: z.string().optional(),
      cuisine: z.string().optional(),
      latitude: z.number().optional(),
      longitude: z.number().optional(),
    }).parse(request.body);
    return platform.upsertListing({ id: params.listingId, ...body });
  });
}
