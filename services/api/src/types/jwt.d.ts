import '@fastify/jwt';

// Extend @fastify/jwt's module types so request.user is fully typed
// everywhere without casting.
declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: {
      sub: string;                          // users.id (UUID)
      email: string;
      role: 'user' | 'moderator' | 'admin';
    };
    user: {
      sub: string;
      email: string;
      role: 'user' | 'moderator' | 'admin';
    };
  }
}
