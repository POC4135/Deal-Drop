import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import { contributionCreateSchema, contributionUpdateSchema } from '@dealdrop/shared-types';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

export async function registerContributionRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.post('/v1/contributions/listings', async (request, reply) => {
    const payload = contributionCreateSchema.parse(request.body);
    const result = await platform.createContribution(request.auth.userId, payload);
    return reply.code(202).send(result);
  });

  app.post('/v1/contributions/listings/:listingId/update', async (request, reply) => {
    const params = z.object({ listingId: z.string() }).parse(request.params);
    const payload = contributionUpdateSchema.parse({
      ...(request.body as object),
      listingId: params.listingId,
    });
    const result = await platform.updateContribution(request.auth.userId, payload);
    return reply.code(202).send(result);
  });

  app.post('/v1/contributions', async (request, reply) => {
    const payload = contributionCreateSchema.parse(request.body);
    const result = await platform.createContribution(request.auth.userId, payload);
    return reply.code(202).send(result);
  });

  app.post('/v1/contributions/proofs/presign', async (request) => {
    const payload = z.object({ contentType: z.string().default('image/jpeg') }).parse(request.body);
    return platform.presignProofUpload(request.auth.userId, payload.contentType);
  });
}
