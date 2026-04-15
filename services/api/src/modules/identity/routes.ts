import type { FastifyInstance } from 'fastify';

import type { DealDropPlatform } from '../../bootstrap/platform.js';

export async function registerIdentityRoutes(app: FastifyInstance, platform: DealDropPlatform): Promise<void> {
  app.get('/v1/me/profile', async (request) => platform.getProfile(request.auth.userId));

  app.get('/v1/me/karma', async (request) => {
    const query = (request.query as { window?: 'daily' | 'weekly' | 'all_time' } | undefined) ?? {};
    return platform.getKarma(request.auth.userId, query.window ?? 'weekly');
  });

  app.get('/v1/me/contributions', async (request) => platform.getContributionHistory(request.auth.userId));

  app.get('/v1/me/saved', async (request) => platform.getSavedListings(request.auth.userId));
}
