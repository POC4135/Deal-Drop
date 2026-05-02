import { z } from 'zod';

// ── Query params ──────────────────────────────────────────────────────────────

export const listListingsQuerySchema = z.object({
  city: z.string().optional(),
  neighborhood: z.string().optional(),
  category: z.string().optional(),
  search: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

export type ListListingsQuery = z.infer<typeof listListingsQuerySchema>;

// ── Response shapes ───────────────────────────────────────────────────────────

export const scheduleSchema = {
  type: 'object',
  properties: {
    dayOfWeek: { type: 'number' },
    startTime: { type: 'string' },
    endTime: { type: 'string' },
    timezone: { type: 'string' },
    isRecurring: { type: 'boolean' },
  },
} as const;

export const listingCardSchema = {
  type: 'object',
  properties: {
    id: { type: 'string' },
    venueId: { type: 'string' },
    venueName: { type: 'string' },
    venueNeighborhood: { type: 'string', nullable: true },
    venueAddress: { type: 'string' },
    latitude: { type: 'number', nullable: true },
    longitude: { type: 'number', nullable: true },
    title: { type: 'string' },
    description: { type: 'string', nullable: true },
    category: { type: 'string' },
    trustBand: { type: 'string' },
    confidenceScore: { type: 'string', nullable: true },
    confirmationCount: { type: 'number' },
    freshnessAt: { type: 'string', nullable: true },
    updatedAt: { type: 'string' },
    ageRestricted: { type: 'boolean' },
    studentOnly: { type: 'boolean' },
    tags: { type: 'array', items: { type: 'string' } },
    schedules: { type: 'array', items: scheduleSchema },
  },
} as const;

export const listListingsResponseSchema = {
  type: 'object',
  properties: {
    data: { type: 'array', items: listingCardSchema },
    total: { type: 'number' },
    limit: { type: 'number' },
    offset: { type: 'number' },
  },
} as const;

export const getListingResponseSchema = {
  ...listingCardSchema,
  properties: {
    ...listingCardSchema.properties,
    priceBand: { type: 'number', nullable: true },
    phone: { type: 'string', nullable: true },
    website: { type: 'string', nullable: true },
    studentOnly: { type: 'boolean' },
    sourceType: { type: 'string' },
  },
} as const;
