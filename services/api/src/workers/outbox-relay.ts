import { queueNames } from '@dealdrop/config';

console.log(
  JSON.stringify({
    worker: 'outbox-relay',
    queue: queueNames.readModelProjector,
    responsibility: 'Publishes pending outbox events to EventBridge and marks delivery state with retry metadata.',
  }),
);
