type HttpMethod = 'GET' | 'POST' | 'DELETE';

type RouteDefinition = {
  method: HttpMethod;
  path: string;
  module: string;
  description: string;
};

const routeCatalog: RouteDefinition[] = [
  {
    method: 'GET',
    path: '/v1/discovery/feed',
    module: 'Discovery',
    description: 'Return nearby curated card read models.',
  },
  {
    method: 'GET',
    path: '/v1/discovery/map',
    module: 'Discovery',
    description: 'Return clustered map read models for bbox and zoom.',
  },
  {
    method: 'GET',
    path: '/v1/search/suggestions',
    module: 'Search',
    description: 'Return suggestions across venue, area, cuisine, and tags.',
  },
  {
    method: 'GET',
    path: '/v1/listings/:listingId',
    module: 'Listings',
    description: 'Return listing detail read model.',
  },
  {
    method: 'POST',
    path: '/v1/contributions',
    module: 'Contributions',
    description: 'Accept moderated contribution payloads.',
  },
  {
    method: 'POST',
    path: '/v1/listings/:listingId/confirm',
    module: 'Trust',
    description: 'Accept a validity confirmation event.',
  },
  {
    method: 'POST',
    path: '/v1/listings/:listingId/report',
    module: 'Moderation',
    description: 'Accept an issue report event.',
  },
  {
    method: 'POST',
    path: '/v1/saved',
    module: 'Saved',
    description: 'Save a listing for the active user.',
  },
  {
    method: 'DELETE',
    path: '/v1/saved',
    module: 'Saved',
    description: 'Remove a saved listing for the active user.',
  },
  {
    method: 'GET',
    path: '/v1/me/karma',
    module: 'Karma',
    description: 'Return the current karma summary and leaderboard context.',
  },
  {
    method: 'GET',
    path: '/v1/me/profile',
    module: 'Identity',
    description: 'Return the active user profile summary.',
  },
];

const workerPipelines = [
  'read-model-projector',
  'trust-scorer',
  'moderation-dedupe',
  'karma-ledger-projector',
  'stale-sweeper',
];

console.log(
  JSON.stringify(
    {
      service: '@dealdrop/api',
      mode: 'scaffold',
      routeCatalog,
      workerPipelines,
    },
    null,
    2,
  ),
);
