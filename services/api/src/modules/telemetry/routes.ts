import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import { telemetryEventSchema } from '@dealdrop/shared-types';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

export async function registerTelemetryRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.post('/v1/telemetry/events', async (request) => {
    const payload = z.object({ events: z.array(telemetryEventSchema) }).parse(request.body);
    return platform.trackTelemetry(payload.events);
  });
}
