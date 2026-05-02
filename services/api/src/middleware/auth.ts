import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

declare module 'fastify' {
  interface FastifyInstance {
    // Attach to routes as: { onRequest: [fastify.authenticate] }
    authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<void>;
    // Moderator or admin required.
    authenticateModerator: (req: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

export function registerAuthDecorators(app: FastifyInstance): void {
  app.decorate(
    'authenticate',
    async (req: FastifyRequest, reply: FastifyReply) => {
      try {
        await req.jwtVerify();
      } catch {
        reply.code(401).send({ error: 'Unauthorized', message: 'Valid bearer token required.' });
      }
    },
  );

  app.decorate(
    'authenticateModerator',
    async (req: FastifyRequest, reply: FastifyReply) => {
      try {
        await req.jwtVerify();
        if (req.user.role !== 'moderator' && req.user.role !== 'admin') {
          reply.code(403).send({ error: 'Forbidden', message: 'Moderator or admin role required.' });
        }
      } catch {
        reply.code(401).send({ error: 'Unauthorized', message: 'Valid bearer token required.' });
      }
    },
  );
}
