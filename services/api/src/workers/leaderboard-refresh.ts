import 'dotenv/config';

import { ulid } from 'ulid';

import { getPool } from '../db/pool.js';

const windows = ['daily', 'weekly', 'all_time'] as const;

export async function runLeaderboardRefresh(): Promise<number> {
  let inserted = 0;
  for (const window of windows) {
    const interval = window === 'daily' ? "interval '1 day'" : window === 'weekly' ? "interval '7 days'" : null;
    const result = await getPool().query<{ user_id: string; points: number; rank: number; level_title: string }>(
      `
        select user_id, points, rank() over (order by points desc)::int as rank, 'Contributor' as level_title
        from (
          select user_id, coalesce(sum(points_delta), 0)::int as points
          from points_ledger
          where status = 'finalized'
            ${interval ? `and created_at >= now() - ${interval}` : ''}
          group by user_id
        ) scored
        order by points desc
        limit 100
      `,
    );
    for (const row of result.rows) {
      await getPool().query(
        `
          insert into leaderboard_snapshots (id, leaderboard_window, snapshot_date, user_id, rank, points, level_title)
          values ($1, $2, date_trunc('day', now()), $3, $4, $5, $6)
        `,
        [`lbs_${ulid().toLowerCase()}`, window, row.user_id, row.rank, row.points, row.level_title],
      );
      inserted += 1;
    }
  }
  console.log(JSON.stringify({ worker: 'leaderboard-refresh', inserted }));
  return inserted;
}

runLeaderboardRefresh().catch((error) => {
  console.error(error);
  process.exit(1);
});
