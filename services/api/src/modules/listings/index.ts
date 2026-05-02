import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { listListingsQuerySchema, listListingsResponseSchema, getListingResponseSchema } from './schema';
import { listActiveListings, getListingById } from './service';

const listingsPlugin: FastifyPluginAsync = async (app) => {
  // GET /v1/listings
  app.get('/v1/listings', {
    schema: {
      querystring: {
        type: 'object',
        properties: {
          city: { type: 'string' },
          neighborhood: { type: 'string' },
          category: { type: 'string' },
          search: { type: 'string' },
          limit: { type: 'number' },
          offset: { type: 'number' },
        },
      },
      response: { 200: listListingsResponseSchema },
    },
  }, async (req, reply) => {
    const query = listListingsQuerySchema.parse(req.query);
    const result = await listActiveListings(query);
    return reply.send({
      data: result.data,
      total: result.total,
      limit: query.limit,
      offset: query.offset,
    });
  });

  // GET /v1/listings/:listingId
  app.get<{ Params: { listingId: string } }>('/v1/listings/:listingId', {
    schema: {
      params: {
        type: 'object',
        required: ['listingId'],
        properties: { listingId: { type: 'string', format: 'uuid' } },
      },
      response: {
        200: getListingResponseSchema,
        404: {
          type: 'object',
          properties: { error: { type: 'string' } },
        },
      },
    },
  }, async (req, reply) => {
    const { listingId } = req.params;

    // Validate UUID shape before hitting the DB
    const uuidResult = z.string().uuid().safeParse(listingId);
    if (!uuidResult.success) {
      return reply.code(400).send({ error: 'Invalid listing ID format.' });
    }

    const listing = await getListingById(listingId);
    if (!listing) {
      return reply.code(404).send({ error: 'Listing not found.' });
    }
    return reply.send(listing);
  });
};

export default listingsPlugin;
