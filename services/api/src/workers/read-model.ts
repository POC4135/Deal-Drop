import { queueNames } from '@dealdrop/config';

console.log(
  JSON.stringify({
    worker: 'read-model',
    queue: queueNames.readModelProjector,
    responsibility: 'Projects listings, trust, and moderation events into feed, map, detail, and search read models.',
  }),
);
