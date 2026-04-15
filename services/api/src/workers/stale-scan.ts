import { queueNames } from '@dealdrop/config';

console.log(
  JSON.stringify({
    worker: 'stale-scan',
    queue: queueNames.staleListingScan,
    responsibility: 'Finds listings past freshness SLA and emits stale scan events for moderator queues.',
  }),
);
