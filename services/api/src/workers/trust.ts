import { queueNames } from '@dealdrop/config';

console.log(
  JSON.stringify({
    worker: 'trust',
    queue: queueNames.trustScorer,
    responsibility: 'Consumes verification and moderation events, recomputes confidence snapshots, and schedules rechecks.',
  }),
);
