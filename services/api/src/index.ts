import 'dotenv/config';

import { parseRuntimeEnv } from '@dealdrop/config';

import { createApp } from './app/create-app.js';

async function main() {
  const env = parseRuntimeEnv(process.env);
  const app = await createApp();
  await app.listen({
    port: env.PORT,
    host: '0.0.0.0',
  });
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  process.exit(1);
});
