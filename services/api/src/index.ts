import 'dotenv/config';
import './types/jwt.d.ts';
import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import fastifyHelmet from '@fastify/helmet';
import fastifyRateLimit from '@fastify/rate-limit';

import { registerAuthDecorators } from './middleware/auth';
import healthPlugin from './modules/health/index';
import authPlugin from './modules/auth/index';
import listingsPlugin from './modules/listings/index';
import karmaPlugin from './modules/karma/index';

const PORT = Number(process.env.PORT ?? 3000);
const HOST = process.env.HOST ?? '0.0.0.0';
const IS_DEV = process.env.NODE_ENV !== 'production';

if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET is not set. Copy .env.example to .env and fill in the values.');
}

const app = Fastify({
  logger: {
    level: IS_DEV ? 'info' : 'warn',
    ...(IS_DEV && {
      transport: {
        target: 'pino-pretty',
        options: { colorize: true, translateTime: 'HH:MM:ss', ignore: 'pid,hostname' },
      },
    }),
  },
  // Propagate a unique request ID for tracing across logs and audit records.
  genReqId: () => crypto.randomUUID(),
  requestIdHeader: 'x-request-id',
});

// ── Security ──────────────────────────────────────────────────────────────────
await app.register(fastifyHelmet, {
  contentSecurityPolicy: false, // API — no HTML served
});

await app.register(fastifyCors, {
  origin: IS_DEV ? true : (process.env.ALLOWED_ORIGINS ?? '').split(','),
  credentials: true,
});

await app.register(fastifyRateLimit, {
  global: true,
  max: 200,
  timeWindow: '1 minute',
  // Auth endpoints get a tighter limit.
  keyGenerator: (req) => req.ip,
});

// ── Auth ──────────────────────────────────────────────────────────────────────
await app.register(fastifyJwt, {
  secret: process.env.JWT_SECRET,
});

registerAuthDecorators(app);

// ── Modules ───────────────────────────────────────────────────────────────────
await app.register(healthPlugin);
await app.register(authPlugin);
await app.register(listingsPlugin);
await app.register(karmaPlugin);

// Tighter rate limit on auth write paths.
app.addHook('onRequest', async (req, _reply) => {
  if (req.url.startsWith('/v1/auth/')) {
    // @fastify/rate-limit max override not available per-route in v10;
    // handled via separate route-level plugin registration in Phase E.
    // Placeholder comment for production hardening.
  }
});

// ── 404 handler ───────────────────────────────────────────────────────────────
app.setNotFoundHandler((req, reply) => {
  reply.code(404).send({
    error: 'Not Found',
    message: `Route ${req.method} ${req.url} not found.`,
  });
});

// ── Start ─────────────────────────────────────────────────────────────────────
try {
  await app.listen({ port: PORT, host: HOST });
  app.log.info(`DealDrop API listening on ${HOST}:${PORT} [${process.env.NODE_ENV ?? 'development'}]`);
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
