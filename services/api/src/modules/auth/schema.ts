import { z } from 'zod';

// ── Requests ──────────────────────────────────────────────────────────────────

export const signUpBody = z.object({
  email: z.string().email(),
  displayName: z.string().min(1).max(64),
});

export const signInBody = z.object({
  email: z.string().email(),
});

export type SignUpBody = z.infer<typeof signUpBody>;
export type SignInBody = z.infer<typeof signInBody>;

// ── Response contract ─────────────────────────────────────────────────────────
// This shape is the backend-owned auth contract. The mobile app never speaks
// directly to Cognito — it uses this surface. In Phase E, the service layer
// is swapped from the dev stub to a Cognito facade while the response shape
// stays identical.

export type AuthSession = {
  accessToken: string;
  tokenType: 'Bearer';
  expiresIn: number; // seconds
};

export type AuthProfile = {
  id: string;
  email: string;
  displayName: string;
  role: 'user' | 'moderator' | 'admin';
  verifiedContributor: boolean;
};

export type AuthResponse = {
  session: AuthSession;
  profile: AuthProfile;
};

// Fastify JSON schema (used for response serialisation and docs).
export const authResponseSchema = {
  type: 'object',
  required: ['session', 'profile'],
  properties: {
    session: {
      type: 'object',
      required: ['accessToken', 'tokenType', 'expiresIn'],
      properties: {
        accessToken: { type: 'string' },
        tokenType: { type: 'string', enum: ['Bearer'] },
        expiresIn: { type: 'number' },
      },
    },
    profile: {
      type: 'object',
      required: ['id', 'email', 'displayName', 'role', 'verifiedContributor'],
      properties: {
        id: { type: 'string' },
        email: { type: 'string' },
        displayName: { type: 'string' },
        role: { type: 'string', enum: ['user', 'moderator', 'admin'] },
        verifiedContributor: { type: 'boolean' },
      },
    },
  },
};
