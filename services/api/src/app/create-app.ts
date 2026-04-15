import cors from '@fastify/cors';
import Fastify from 'fastify';

import { DealDropPlatform } from '../bootstrap/platform.js';
import { registerAdminRoutes } from '../modules/admin/routes.js';
import { registerAuthRoutes } from '../modules/auth/routes.js';
import { registerContributionRoutes } from '../modules/contributions/routes.js';
import { registerDiscoveryRoutes } from '../modules/discovery/routes.js';
import { registerHealthRoutes } from '../modules/health/routes.js';
import { registerIdentityRoutes } from '../modules/identity/routes.js';
import { registerLeaderboardRoutes } from '../modules/leaderboards/routes.js';
import { registerFavoriteRoutes } from '../modules/favorites/routes.js';
import { registerListingRoutes } from '../modules/listings/routes.js';
import { registerNotificationRoutes } from '../modules/notifications/routes.js';
import { registerTelemetryRoutes } from '../modules/telemetry/routes.js';
import { registerAuth } from '../plugins/auth.js';
import { registerErrorHandler } from '../plugins/error-handler.js';
import { registerRequestContext } from '../plugins/request-context.js';

export async function createApp() {
  const app = Fastify({
    logger: {
      level: process.env.LOG_LEVEL ?? 'info',
      transport:
        process.env.NODE_ENV === 'production'
          ? undefined
          : {
              target: 'pino-pretty',
            },
    },
  });

  const platform = new DealDropPlatform();

  await app.register(cors, {
    origin: true,
    credentials: true,
  });
  await registerRequestContext(app);
  await registerAuth(app);
  await registerErrorHandler(app);
  await registerHealthRoutes(app);
  await registerAuthRoutes(app, platform);
  await registerIdentityRoutes(app, platform);
  await registerDiscoveryRoutes(app, platform);
  await registerListingRoutes(app, platform);
  await registerFavoriteRoutes(app, platform);
  await registerContributionRoutes(app, platform);
  await registerNotificationRoutes(app, platform);
  await registerLeaderboardRoutes(app, platform);
  await registerTelemetryRoutes(app, platform);
  await registerAdminRoutes(app, platform);

  return app;
}
