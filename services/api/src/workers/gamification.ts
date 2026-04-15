import { queueNames } from '@dealdrop/config';

console.log(
  JSON.stringify({
    worker: 'gamification',
    queue: queueNames.gamificationProjector,
    responsibility: 'Finalizes pending points, updates streaks, and writes leaderboard snapshots.',
  }),
);
