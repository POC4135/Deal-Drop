import 'dotenv/config';

import { getPool } from '../db/pool.js';

export async function runNotificationDispatch(): Promise<number> {
  const result = await getPool().query<{
    notification_id: string;
    device_id: string;
  }>(`
    insert into notification_deliveries (id, notification_id, device_id, channel, status, attempted_at)
    select 'ndl_' || replace(gen_random_uuid()::text, '-', ''), n.id, d.id, 'push', 'queued', now()
    from notifications n
    join device_registrations d on d.user_id = n.user_id and d.disabled_at is null and d.push_token is not null
    left join notification_preferences p on p.user_id = n.user_id
    where n.created_at > now() - interval '1 day'
      and case n.kind
        when 'contribution_resolved' then coalesce(p.contribution_resolved, true)
        when 'points_finalized' then coalesce(p.points_finalized, true)
        when 'trust_status_changed' then coalesce(p.trust_status_changed, true)
        else true
      end
      and not exists (
        select 1 from notification_deliveries nd
        where nd.notification_id = n.id and nd.device_id = d.id
      )
    returning notification_id, device_id
  `);

  await getPool().query(`
    update notification_deliveries
    set status = case
      when $1::text is not null or $2::text is not null then 'sent'
      else 'suppressed'
    end,
    attempted_at = coalesce(attempted_at, now()),
    delivered_at = case when $1::text is not null or $2::text is not null then now() else delivered_at end,
    failed_at = case when $1::text is null and $2::text is null then now() else failed_at end,
    failure_reason = case when $1::text is null and $2::text is null then 'push credentials not configured' else failure_reason end
    where status = 'queued'
  `, [process.env.FCM_SERVER_KEY ?? null, process.env.APNS_KEY_ID ?? null]);

  console.log(JSON.stringify({ worker: 'notifications', queued: result.rowCount }));
  return result.rowCount ?? 0;
}

runNotificationDispatch().catch((error) => {
  console.error(error);
  process.exit(1);
});
