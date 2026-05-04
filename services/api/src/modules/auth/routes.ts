import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import { authBootstrapSchema } from '@dealdrop/shared-types';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

const authBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(2).optional(),
  homeNeighborhood: z.string().optional(),
});

export async function registerAuthRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.post('/v1/auth/bootstrap', async (request) => {
    const body = authBootstrapSchema.parse(request.body ?? {});
    return platform.bootstrapAuthenticatedUser(request.auth, body);
  });

  app.post('/v1/auth/sign-in', async (request, reply) => {
    if (process.env.USE_DEV_AUTH === 'false') {
      return reply.code(404).send({
        error: 'not_found',
        message: 'Password auth is handled by Supabase in production.',
      });
    }
    const body = authBodySchema.parse(request.body);
    try {
      return platform.authenticate({
        email: body.email,
        password: body.password,
        mode: 'sign_in',
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'invalid_credentials') {
        return reply.code(401).send({
          error: 'invalid_credentials',
          message: 'Email or password is incorrect.',
        });
      }
      throw error;
    }
  });

  app.post('/v1/auth/sign-up', async (request, reply) => {
    if (process.env.USE_DEV_AUTH === 'false') {
      return reply.code(404).send({
        error: 'not_found',
        message: 'Password auth is handled by Supabase in production.',
      });
    }
    const body = authBodySchema.parse(request.body);
    try {
      return platform.authenticate({
        email: body.email,
        password: body.password,
        displayName: body.displayName,
        homeNeighborhood: body.homeNeighborhood,
        mode: 'sign_up',
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'email_already_exists') {
        return reply.code(409).send({
          error: 'email_already_exists',
          message: 'An account already exists for this email.',
        });
      }
      throw error;
    }
  });
}
