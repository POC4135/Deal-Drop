import { z } from 'zod';

export const environmentSchema = z.enum(['dev', 'staging', 'prod', 'test']);

export const serviceNames = {
  api: 'dealdrop-api',
  adminWeb: 'dealdrop-admin-web',
  readModelWorker: 'dealdrop-workers-read-model',
  trustWorker: 'dealdrop-workers-trust',
  gamificationWorker: 'dealdrop-workers-gamification',
  outboxRelayWorker: 'dealdrop-workers-outbox-relay',
  moderationDedupeWorker: 'dealdrop-workers-moderation-dedupe',
  leaderboardRefreshWorker: 'dealdrop-workers-leaderboard-refresh',
  staleScanWorker: 'dealdrop-workers-stale-scan',
  notificationDispatchWorker: 'dealdrop-workers-notifications',
} as const;

export const queueNames = {
  readModelProjector: 'dealdrop.read-model.projector',
  trustScorer: 'dealdrop.trust.scorer',
  gamificationProjector: 'dealdrop.gamification.projector',
  moderationDedupe: 'dealdrop.moderation.dedupe',
  leaderboardRefresh: 'dealdrop.leaderboard.refresh',
  staleListingScan: 'dealdrop.listings.stale-scan',
  notifications: 'dealdrop.notifications.dispatch',
  dlqSuffix: '.dlq',
} as const;

export const eventTypes = {
  contributionSubmitted: 'contribution.submitted',
  moderationResolved: 'moderation.resolved',
  verificationRecorded: 'verification.recorded',
  confidenceUpdateNeeded: 'confidence.update-needed',
  pointsPending: 'points.pending',
  pointsFinalized: 'points.finalized',
  leaderboardRefreshNeeded: 'leaderboard.refresh-needed',
  staleListingScanRequested: 'listing.stale-scan-requested',
} as const;

export const cacheTtls = {
  feedHomeSeconds: 90,
  liveNowSeconds: 90,
  tonightSeconds: 180,
  nearbySeconds: 120,
  mapBoundsSeconds: 60,
  listingDetailSeconds: 180,
  venueDetailSeconds: 180,
  searchSeconds: 60,
  filterMetadataSeconds: 600,
  leaderboardSeconds: 300,
} as const;

export const cacheKeyVersion = 'v1';

export const featureFlags = {
  opensearchReadModel: false,
  notificationsDispatch: true,
  adminCsvExport: true,
} as const;

export const authClaimSchema = z.object({
  sub: z.string(),
  email: z.string().email().optional(),
  role: z.string().optional(),
  app_role: z.enum(['user', 'moderator', 'admin']).optional(),
  username: z.string().optional(),
});

export type AuthClaims = z.infer<typeof authClaimSchema>;

export const runtimeEnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  APP_ENV: environmentSchema.default('dev'),
  PLATFORM_BACKEND: z.enum(['seed', 'postgres']).default('seed'),
  PORT: z.coerce.number().default(3000),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  DATABASE_URL: z.string().default('postgres://postgres:postgres@localhost:5432/dealdrop'),
  REDIS_URL: z.string().default('redis://localhost:6379'),
  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_JWKS_URL: z.string().url().optional(),
  SUPABASE_JWT_ISSUER: z.string().url().optional(),
  SUPABASE_JWT_AUDIENCE: z.string().default('authenticated'),
  SUPABASE_PUBLISHABLE_KEY: z.string().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SUPABASE_STORAGE_BUCKET: z.string().default('proofs'),
  FCM_PROJECT_ID: z.string().optional(),
  FCM_SERVICE_ACCOUNT_JSON: z.string().optional(),
  FCM_SERVER_KEY: z.string().optional(),
  APNS_KEY_ID: z.string().optional(),
  APNS_TEAM_ID: z.string().optional(),
  APNS_BUNDLE_ID: z.string().optional(),
  APNS_PRIVATE_KEY: z.string().optional(),
  JWT_AUDIENCE: z.string().default('authenticated'),
  JWT_ISSUER: z.string().default('https://dealdrop.local/auth'),
  USE_DEV_AUTH: z
    .union([z.literal('true'), z.literal('false')])
    .default('true')
    .transform((value) => value === 'true'),
});

export type RuntimeEnv = z.infer<typeof runtimeEnvSchema>;

export function parseRuntimeEnv(input: Record<string, string | undefined>): RuntimeEnv {
  return runtimeEnvSchema.parse(input);
}

export function cacheNamespace(namespace: string): string {
  return `dealdrop:${cacheKeyVersion}:${namespace}`;
}

export function buildCacheKey(namespace: string, ...parts: Array<string | number | undefined>): string {
  return [cacheNamespace(namespace), ...parts.filter((part) => part !== undefined)].join(':');
}

export function resolveRole(claims: AuthClaims): 'user' | 'moderator' | 'admin' {
  if (claims.app_role) {
    return claims.app_role;
  }

  if (claims.role === 'user' || claims.role === 'moderator' || claims.role === 'admin') {
    return claims.role;
  }

  return 'user';
}
