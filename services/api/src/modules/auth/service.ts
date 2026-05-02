/**
 * DEV STUB AUTH SERVICE
 *
 * This is a local-development-only auth implementation.
 * It creates users directly in the DB and issues JWTs signed with JWT_SECRET.
 *
 * It is NOT production auth. There is no password verification.
 * Phase E replaces this with a Cognito-backed facade that preserves the same
 * AuthResponse contract shape.
 *
 * Never deploy this stub to production.
 */
import type { FastifyInstance } from 'fastify';
import { eq } from 'drizzle-orm';
import { db } from '../../db/client';
import { users, userProfiles, karmaSnapshots, streakCheckpoints, notificationPreferences } from '../../db/schema/index';
import type { AuthResponse } from './schema';

const TOKEN_EXPIRY_SECONDS = 60 * 60 * 24; // 24h for dev convenience

export async function devSignUp(
  app: FastifyInstance,
  email: string,
  displayName: string,
): Promise<AuthResponse> {
  const normalizedEmail = email.toLowerCase().trim();

  // Idempotent — return existing user if email already registered.
  const existing = await db
    .select()
    .from(users)
    .where(eq(users.email, normalizedEmail))
    .limit(1);

  if (existing.length > 0) {
    return buildAuthResponse(app, existing[0]);
  }

  // Create user + required 1:1 child rows in a single transaction.
  const [newUser] = await db.transaction(async (tx) => {
    const [user] = await tx
      .insert(users)
      .values({
        authProviderSubject: `dev:${normalizedEmail}`,
        email: normalizedEmail,
        displayName,
        role: 'user',
        status: 'active',
      })
      .returning();

    await tx.insert(userProfiles).values({ userId: user.id });
    await tx.insert(karmaSnapshots).values({ userId: user.id });
    await tx.insert(streakCheckpoints).values({ userId: user.id });
    await tx.insert(notificationPreferences).values({ userId: user.id });

    return [user];
  });

  return buildAuthResponse(app, newUser);
}

export async function devSignIn(
  app: FastifyInstance,
  email: string,
): Promise<AuthResponse | null> {
  const normalizedEmail = email.toLowerCase().trim();

  const [user] = await db
    .select()
    .from(users)
    .where(eq(users.email, normalizedEmail))
    .limit(1);

  if (!user || user.status !== 'active' || user.deletedAt) {
    return null;
  }

  return buildAuthResponse(app, user);
}

function buildAuthResponse(
  app: FastifyInstance,
  user: typeof users.$inferSelect,
): AuthResponse {
  const accessToken = app.jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    { expiresIn: TOKEN_EXPIRY_SECONDS },
  );

  return {
    session: {
      accessToken,
      tokenType: 'Bearer',
      expiresIn: TOKEN_EXPIRY_SECONDS,
    },
    profile: {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      role: user.role,
      verifiedContributor: user.verifiedContributor,
    },
  };
}
