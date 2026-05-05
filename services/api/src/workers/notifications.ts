import 'dotenv/config';

import { importPKCS8, SignJWT } from 'jose';

import { getPool } from '../db/pool.js';

type PendingDelivery = {
  delivery_id: string;
  notification_id: string;
  device_id: string;
  push_token: string;
  title: string;
  body: string;
  deep_link: string | null;
};

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id?: string;
};

let cachedAccessToken: { token: string; expiresAt: number } | undefined;

export async function runNotificationDispatch(): Promise<number> {
  await queueNotificationDeliveries();
  const pending = await getPendingDeliveries();
  const fcmConfig = resolveFcmConfig();

  if (!fcmConfig) {
    await markAllSuppressed(pending, 'FCM credentials not configured');
    console.log(
      JSON.stringify({
        worker: 'notifications',
        queued: pending.length,
        sent: 0,
        suppressed: pending.length,
      }),
    );
    return pending.length;
  }

  let sent = 0;
  let failed = 0;
  for (const delivery of pending) {
    try {
      await sendFcmMessage(fcmConfig, delivery);
      await markDeliverySent(delivery.delivery_id);
      sent += 1;
    } catch (error) {
      await markDeliveryFailed(delivery.delivery_id, error);
      failed += 1;
    }
  }

  console.log(
    JSON.stringify({
      worker: 'notifications',
      queued: pending.length,
      sent,
      failed,
    }),
  );
  return pending.length;
}

async function queueNotificationDeliveries(): Promise<void> {
  await getPool().query(`
    insert into notification_deliveries (id, notification_id, device_id, channel, status, attempted_at)
    select 'ndl_' || replace(gen_random_uuid()::text, '-', ''), n.id, d.id, 'push', 'queued'::notification_delivery_status, now()
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
  `);
}

async function getPendingDeliveries(): Promise<PendingDelivery[]> {
  const result = await getPool().query<PendingDelivery>(`
    select
      nd.id as delivery_id,
      n.id as notification_id,
      d.id as device_id,
      d.push_token,
      n.title,
      n.body,
      n.deep_link
    from notification_deliveries nd
    join notifications n on n.id = nd.notification_id
    join device_registrations d on d.id = nd.device_id
    where nd.status = 'queued'
      and d.disabled_at is null
      and d.push_token is not null
    order by nd.created_at asc
    limit 500
  `);
  return result.rows;
}

function resolveFcmConfig():
  | { mode: 'v1'; projectId: string; serviceAccount: ServiceAccount }
  | { mode: 'legacy'; serverKey: string }
  | undefined {
  if (process.env.FCM_SERVICE_ACCOUNT_JSON) {
    const serviceAccount = JSON.parse(
      process.env.FCM_SERVICE_ACCOUNT_JSON,
    ) as ServiceAccount;
    const projectId = process.env.FCM_PROJECT_ID ?? serviceAccount.project_id;
    if (!projectId) {
      throw new Error('FCM_PROJECT_ID is required with FCM service account credentials');
    }
    return {
      mode: 'v1',
      projectId,
      serviceAccount: {
        ...serviceAccount,
        private_key: serviceAccount.private_key.replace(/\\n/g, '\n'),
      },
    };
  }
  if (process.env.FCM_SERVER_KEY) {
    return { mode: 'legacy', serverKey: process.env.FCM_SERVER_KEY };
  }
  return undefined;
}

async function sendFcmMessage(
  config:
    | { mode: 'v1'; projectId: string; serviceAccount: ServiceAccount }
    | { mode: 'legacy'; serverKey: string },
  delivery: PendingDelivery,
): Promise<void> {
  if (config.mode === 'legacy') {
    await sendLegacyFcmMessage(config.serverKey, delivery);
    return;
  }
  const accessToken = await getFcmAccessToken(config.serviceAccount);
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${config.projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: delivery.push_token,
          notification: {
            title: delivery.title,
            body: delivery.body,
          },
          data: {
            notificationId: delivery.notification_id,
            deepLink: delivery.deep_link ?? '',
          },
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'dealdrop_alerts',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        },
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`fcm_v1_${response.status}:${await response.text()}`);
  }
}

async function sendLegacyFcmMessage(
  serverKey: string,
  delivery: PendingDelivery,
): Promise<void> {
  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      Authorization: `key=${serverKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: delivery.push_token,
      priority: 'high',
      notification: {
        title: delivery.title,
        body: delivery.body,
        sound: 'default',
      },
      data: {
        notificationId: delivery.notification_id,
        deepLink: delivery.deep_link ?? '',
      },
    }),
  });
  if (!response.ok) {
    throw new Error(`fcm_legacy_${response.status}:${await response.text()}`);
  }
}

async function getFcmAccessToken(
  serviceAccount: ServiceAccount,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt - 60 > now) {
    return cachedAccessToken.token;
  }

  const privateKey = await importPKCS8(serviceAccount.private_key, 'RS256');
  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Error(`fcm_oauth_${response.status}:${await response.text()}`);
  }
  const payload = (await response.json()) as {
    access_token: string;
    expires_in?: number;
  };
  cachedAccessToken = {
    token: payload.access_token,
    expiresAt: now + (payload.expires_in ?? 3600),
  };
  return cachedAccessToken.token;
}

async function markDeliverySent(deliveryId: string): Promise<void> {
  await getPool().query(
    `
      update notification_deliveries
      set status = 'sent'::notification_delivery_status,
        attempted_at = coalesce(attempted_at, now()),
        delivered_at = now(),
        failure_reason = null
      where id = $1
    `,
    [deliveryId],
  );
}

async function markDeliveryFailed(
  deliveryId: string,
  error: unknown,
): Promise<void> {
  await getPool().query(
    `
      update notification_deliveries
      set status = 'failed'::notification_delivery_status,
        attempted_at = coalesce(attempted_at, now()),
        failed_at = now(),
        failure_reason = left($2, 500)
      where id = $1
    `,
    [deliveryId, error instanceof Error ? error.message : String(error)],
  );
}

async function markAllSuppressed(
  deliveries: PendingDelivery[],
  reason: string,
): Promise<void> {
  if (deliveries.length === 0) {
    return;
  }
  await getPool().query(
    `
      update notification_deliveries
      set status = 'suppressed'::notification_delivery_status,
        attempted_at = coalesce(attempted_at, now()),
        failed_at = now(),
        failure_reason = $2
      where id = any($1::varchar[])
    `,
    [deliveries.map((delivery) => delivery.delivery_id), reason],
  );
}

runNotificationDispatch().catch((error) => {
  console.error(error);
  process.exit(1);
});
