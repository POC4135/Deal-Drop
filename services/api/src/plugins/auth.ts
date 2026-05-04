import { createRemoteJWKSet, jwtVerify } from 'jose';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { z } from 'zod';

import { authClaimSchema, parseRuntimeEnv, resolveRole } from '@dealdrop/config';
import type { Role } from '@dealdrop/shared-types';

import { getPool } from '../db/pool.js';

const devHeadersSchema = z.object({
  'x-dev-user-id': z.string().optional(),
  'x-dev-email': z.string().optional(),
  'x-dev-role': z.enum(['user', 'moderator', 'admin']).optional(),
  'x-dev-name': z.string().optional(),
  'x-dev-verified-contributor': z.string().optional(),
});

export async function registerAuth(app: FastifyInstance): Promise<void> {
  const env = parseRuntimeEnv(process.env);
  const jwtIssuer = env.SUPABASE_JWT_ISSUER ?? env.JWT_ISSUER;
  const jwtAudience = env.SUPABASE_URL ? env.SUPABASE_JWT_AUDIENCE : env.JWT_AUDIENCE;
  const jwksUrl = env.SUPABASE_JWKS_URL ?? `${jwtIssuer}/.well-known/jwks.json`;
  const jwks = createRemoteJWKSet(new URL(jwksUrl));

  app.decorateRequest('auth', null);

  app.addHook('preHandler', async (request) => {
    const publicRoute = isPublicRoute(request.method, request.routeOptions.url ?? request.url);
    if (env.USE_DEV_AUTH) {
      const headers = devHeadersSchema.parse(request.headers);
      if (!headers['x-dev-user-id'] && publicRoute) {
        request.auth = {
          userId: 'guest_local',
          email: 'guest@dealdrop.local',
          role: 'user',
          displayName: 'Guest',
          verifiedContributor: false,
        };
        return;
      }
      request.auth = {
        userId: headers['x-dev-user-id'] ?? 'usr_jon',
        email: headers['x-dev-email'] ?? 'jon@dealdrop.app',
        role: headers['x-dev-role'] ?? 'admin',
        displayName: headers['x-dev-name'] ?? 'Jon Patel',
        verifiedContributor: headers['x-dev-verified-contributor'] !== 'false',
      };
      return;
    }

    const authorization = request.headers.authorization;
    if (!authorization?.startsWith('Bearer ')) {
      if (publicRoute) {
        request.auth = {
          userId: 'guest_public',
          email: 'guest@dealdrop.app',
          role: 'user',
          displayName: 'Guest',
          verifiedContributor: false,
        };
        return;
      }
      const error = new Error('Missing bearer token');
      (error as Error & { statusCode?: number }).statusCode = 401;
      throw error;
    }

    const token = authorization.slice('Bearer '.length);
    const verified = await jwtVerify(token, jwks, {
      issuer: jwtIssuer,
      audience: jwtAudience,
    });
    const claims = authClaimSchema.parse(verified.payload);
    const fallbackRole = resolveRole(claims);
    const appRole = env.PLATFORM_BACKEND === 'postgres' ? await resolveRoleFromDatabase(claims.sub, fallbackRole) : fallbackRole;
    request.auth = {
      userId: claims.sub,
      email: claims.email ?? 'unknown@dealdrop.app',
      role: appRole,
      displayName: claims.username ?? claims.email ?? claims.sub,
      verifiedContributor: appRole !== 'user',
    };
  });
}

async function resolveRoleFromDatabase(userId: string, fallbackRole: Role): Promise<Role> {
  const result = await getPool().query<{ role: Role }>('select role from users where id = $1 limit 1', [userId]);
  return result.rows[0]?.role ?? fallbackRole;
}

function isPublicRoute(method: string, url: string): boolean {
  const publicRoutes = new Set([
    'GET:/health/live',
    'GET:/health/ready',
    'POST:/v1/auth/sign-in',
    'POST:/v1/auth/sign-up',
    'GET:/v1/feed/home',
    'GET:/v1/listings/live-now',
    'GET:/v1/listings/tonight',
    'GET:/v1/listings/nearby',
    'GET:/v1/listings/map-bounds',
    'GET:/v1/search',
    'GET:/v1/filters/metadata',
    'GET:/v1/discovery/feed',
    'GET:/v1/discovery/map',
  ]);

  return (
    publicRoutes.has(`${method}:${url}`) ||
    (method === 'GET' && url.startsWith('/v1/listings/')) ||
    (method === 'GET' && url.startsWith('/v1/venues/'))
  );
}

export function requireRole(role: Role) {
  const order: Role[] = ['user', 'moderator', 'admin'];
  return async (request: FastifyRequest, reply: FastifyReply) => {
    if (order.indexOf(request.auth.role) < order.indexOf(role)) {
      return reply.code(403).send({
        error: 'forbidden',
        message: `Route requires ${role}`,
        requestId: request.requestId,
      });
    }
  };
}
