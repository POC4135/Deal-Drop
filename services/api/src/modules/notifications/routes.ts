import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import { deviceRegistrationSchema, userPreferencesSchema } from '@dealdrop/shared-types';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

export async function registerNotificationRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.get('/v1/notifications', async (request) => platform.getNotifications(request.auth.userId));

  app.post('/v1/notifications/:notificationId/read', async (request, reply) => {
    const { notificationId } = z.object({ notificationId: z.string() }).parse(request.params);
    const notification = platform.markNotificationRead(request.auth.userId, notificationId);
    if (!notification) {
      return reply.code(404).send({ error: 'not_found', requestId: request.requestId });
    }
    return notification;
  });

  app.get('/v1/me/preferences', async (request) => platform.getPreferences(request.auth.userId));

  app.put('/v1/me/preferences', async (request) => {
    const payload = userPreferencesSchema.parse(request.body);
    return platform.updatePreferences(request.auth.userId, payload);
  });

  app.post('/v1/devices/register', async (request) => {
    const payload = deviceRegistrationSchema.parse(request.body);
    return platform.registerDevice(request.auth.userId, payload);
  });

  app.delete('/v1/devices/:deviceId', async (request, reply) => {
    const { deviceId } = z.object({ deviceId: z.string() }).parse(request.params);
    platform.unregisterDevice(request.auth.userId, deviceId);
    return reply.code(204).send();
  });
}
