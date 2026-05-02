import type { FastifyPluginAsync } from 'fastify';
import { signUpBody, signInBody, authResponseSchema } from './schema';
import { devSignUp, devSignIn } from './service';

const authPlugin: FastifyPluginAsync = async (app) => {
  /**
   * POST /v1/auth/sign-up
   *
   * DEV STUB: creates a new user (or returns existing) without password.
   * Phase E: replaced by Cognito-backed implementation.
   */
  app.post('/v1/auth/sign-up', {
    schema: {
      body: {
        type: 'object',
        required: ['email', 'displayName'],
        properties: {
          email: { type: 'string', format: 'email' },
          displayName: { type: 'string', minLength: 1, maxLength: 64 },
        },
      },
      response: { 201: authResponseSchema },
    },
  }, async (request, reply) => {
    const body = signUpBody.parse(request.body);
    const result = await devSignUp(app, body.email, body.displayName);
    return reply.code(201).send(result);
  });

  /**
   * POST /v1/auth/sign-in
   *
   * DEV STUB: finds user by email and issues a token (no password check).
   * Phase E: replaced by Cognito-backed implementation.
   */
  app.post('/v1/auth/sign-in', {
    schema: {
      body: {
        type: 'object',
        required: ['email'],
        properties: {
          email: { type: 'string', format: 'email' },
        },
      },
      response: {
        200: authResponseSchema,
        401: {
          type: 'object',
          properties: {
            error: { type: 'string' },
            message: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    const body = signInBody.parse(request.body);
    const result = await devSignIn(app, body.email);

    if (!result) {
      return reply.code(401).send({
        error: 'Unauthorized',
        message: 'No active user found for this email. Sign up first.',
      });
    }

    return reply.send(result);
  });
};

export default authPlugin;
