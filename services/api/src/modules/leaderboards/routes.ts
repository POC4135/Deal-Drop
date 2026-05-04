import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

export async function registerLeaderboardRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.get('/v1/leaderboards', async (request) => {
    const { window } = z
      .object({ window: z.enum(['daily', 'weekly', 'all_time']).default('weekly') })
      .parse(request.query);
    return {
      window,
      items: await platform.getLeaderboard(window),
    };
  });
}
