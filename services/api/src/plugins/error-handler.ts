import type { FastifyInstance } from 'fastify';

export async function registerErrorHandler(app: FastifyInstance): Promise<void> {
  app.setErrorHandler((error, request, reply) => {
    const appError = error as Error & { statusCode?: number };
    request.log.error(
      {
        requestId: request.requestId,
        err: appError,
      },
      'request_failed',
    );

    reply.status(appError.statusCode ?? 500).send({
      error: appError.name ?? 'internal_error',
      message: appError.message,
      requestId: request.requestId,
    });
  });
}
