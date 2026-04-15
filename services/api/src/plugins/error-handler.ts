import type { FastifyInstance } from 'fastify';

export async function registerErrorHandler(app: FastifyInstance): Promise<void> {
  app.setErrorHandler((error, request, reply) => {
    request.log.error(
      {
        requestId: request.requestId,
        err: error,
      },
      'request_failed',
    );

    reply.status(error.statusCode ?? 500).send({
      error: error.name ?? 'internal_error',
      message: error.message,
      requestId: request.requestId,
    });
  });
}
