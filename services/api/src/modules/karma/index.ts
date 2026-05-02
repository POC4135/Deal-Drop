import type { FastifyPluginAsync } from 'fastify';
import { karmaSnapshotResponseSchema } from './schema';
import { getKarmaSnapshot } from './service';

const karmaPlugin: FastifyPluginAsync = async (app) => {
  // GET /v1/users/me/karma — requires auth
  app.get('/v1/users/me/karma', {
    onRequest: [app.authenticate],
    schema: {
      response: {
        200: karmaSnapshotResponseSchema,
        404: {
          type: 'object',
          properties: { error: { type: 'string' } },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.sub;
    const snapshot = await getKarmaSnapshot(userId);
    if (!snapshot) {
      return reply.code(404).send({ error: 'User not found.' });
    }
    return reply.send(snapshot);
  });
};

export default karmaPlugin;
