create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists pgcrypto;

create type role as enum ('user', 'moderator', 'admin');
create type listing_status as enum ('draft', 'active', 'stale', 'suppressed', 'archived');
create type trust_band as enum ('founder_verified', 'merchant_confirmed', 'user_confirmed', 'recently_updated', 'needs_recheck', 'disputed');
create type visibility_state as enum ('visible', 'shadow_hidden', 'suppressed');
create type contribution_type as enum ('new_listing', 'listing_update', 'confirm_valid', 'report_expired');
create type contribution_status as enum ('submitted', 'needs_proof', 'under_review', 'approved', 'rejected', 'merged');
create type moderation_decision as enum ('approve', 'reject', 'request_proof', 'merge_duplicate', 'snooze');
create type report_status as enum ('open', 'resolved');
create type ledger_status as enum ('pending', 'finalized', 'reversed');
create type leaderboard_window as enum ('daily', 'weekly', 'all_time');
create type outbox_status as enum ('pending', 'published', 'failed');
create type platform_type as enum ('ios', 'android', 'web', 'unknown');
create type notification_kind as enum ('contribution_resolved', 'points_finalized', 'trust_status_changed', 'listing_reported_stale', 'moderation_update');
create type notification_delivery_status as enum ('queued', 'sent', 'delivered', 'failed', 'suppressed');

create table users (
  id varchar(64) primary key,
  email varchar(255) not null unique,
  role role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table user_profiles (
  user_id varchar(64) primary key references users(id),
  display_name varchar(120) not null,
  home_neighborhood varchar(120) not null,
  contributor_trust_score double precision not null default 0.5,
  verified_contributor boolean not null default false,
  current_level varchar(120) not null default 'Newcomer',
  deleted_at timestamptz,
  updated_at timestamptz not null default now()
);

create table device_sessions (
  id varchar(64) primary key,
  user_id varchar(64) not null references users(id),
  platform varchar(32) not null,
  device_label varchar(128) not null,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table venues (
  id varchar(64) primary key,
  slug varchar(160) not null unique,
  name varchar(255) not null,
  rating double precision not null default 0,
  status listing_status not null default 'active',
  deleted_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table venue_locations (
  id varchar(64) primary key,
  venue_id varchar(64) not null references venues(id),
  neighborhood_name varchar(120) not null,
  neighborhood_slug varchar(120) not null,
  address text not null,
  latitude double precision not null,
  longitude double precision not null,
  point geography(Point, 4326) not null,
  verification_geofence_radius_meters integer not null default 120,
  created_at timestamptz not null default now()
);

create unique index venue_locations_venue_idx on venue_locations (venue_id);
create index venue_locations_neighborhood_idx on venue_locations (neighborhood_slug, venue_id);
create index venue_locations_point_idx on venue_locations using gist (point);

create table listings (
  id varchar(64) primary key,
  venue_id varchar(64) not null references venues(id),
  slug varchar(160) not null unique,
  title varchar(255) not null,
  description text not null,
  category_label varchar(120) not null,
  schedule_summary varchar(160) not null,
  conditions text not null,
  source_note text not null,
  cuisine varchar(120) not null,
  status listing_status not null default 'draft',
  trust_band trust_band not null default 'recently_updated',
  visibility_state visibility_state not null default 'visible',
  confidence_score double precision not null default 0.5,
  fresh_until_at timestamptz,
  recheck_after_at timestamptz,
  published_at timestamptz,
  last_verified_at timestamptz,
  deleted_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index listings_feed_idx on listings (status, trust_band, confidence_score desc, updated_at desc);
create index listings_venue_idx on listings (venue_id, status);
create index listings_active_partial_idx on listings (confidence_score desc, updated_at desc) where status = 'active' and deleted_at is null;
create index listings_recheck_partial_idx on listings (recheck_after_at) where status in ('active', 'stale');

create table listing_schedules (
  id varchar(64) primary key,
  listing_id varchar(64) not null references listings(id),
  day_of_week integer not null check (day_of_week between 0 and 6),
  start_time_local varchar(16) not null,
  end_time_local varchar(16) not null,
  timezone varchar(64) not null default 'America/New_York',
  special_label varchar(120)
);

create index listing_schedules_idx on listing_schedules (listing_id, day_of_week, start_time_local);

create table listing_tags (
  listing_id varchar(64) not null references listings(id),
  tag varchar(120) not null,
  created_at timestamptz not null default now(),
  primary key (listing_id, tag)
);

create index listing_tags_tag_idx on listing_tags (tag, listing_id);

create table favorites (
  user_id varchar(64) not null references users(id),
  listing_id varchar(64) not null references listings(id),
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

create index favorites_listing_idx on favorites (listing_id, created_at desc);

create table contributions (
  id varchar(64) primary key,
  listing_id varchar(64) references listings(id),
  user_id varchar(64) not null references users(id),
  type contribution_type not null,
  status contribution_status not null default 'submitted',
  title varchar(255),
  description text,
  schedule_summary varchar(160),
  neighborhood varchar(120),
  latitude double precision,
  longitude double precision,
  payload jsonb not null default '{}'::jsonb,
  duplicate_of_listing_id varchar(64),
  idempotency_key varchar(160),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index contributions_idempotency_idx on contributions (idempotency_key) where idempotency_key is not null;
create index contributions_status_idx on contributions (status, created_at desc);
create index contributions_user_idx on contributions (user_id, created_at desc);
create index contributions_review_partial_idx on contributions (created_at desc) where status in ('submitted', 'needs_proof', 'under_review');

create table contribution_proofs (
  id varchar(64) primary key,
  contribution_id varchar(64) not null references contributions(id),
  asset_key text not null,
  content_type varchar(120) not null,
  uploaded_at timestamptz not null default now()
);

create index contribution_proofs_idx on contribution_proofs (contribution_id, uploaded_at desc);

create table reports (
  id varchar(64) primary key,
  listing_id varchar(64) not null references listings(id),
  user_id varchar(64) not null references users(id),
  reason varchar(120) not null,
  notes text,
  status report_status not null default 'open',
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index reports_status_idx on reports (status, created_at desc);
create index reports_open_partial_idx on reports (created_at desc) where status = 'open';

create table moderation_actions (
  id varchar(64) primary key,
  contribution_id varchar(64) references contributions(id),
  report_id varchar(64) references reports(id),
  moderator_user_id varchar(64) not null references users(id),
  decision moderation_decision not null,
  notes text,
  merged_into_listing_id varchar(64),
  created_at timestamptz not null default now()
);

create index moderation_actions_idx on moderation_actions (moderator_user_id, created_at desc);

create table verification_events (
  id varchar(64) not null,
  listing_id varchar(64) not null references listings(id),
  user_id varchar(64) references users(id),
  source_type varchar(32) not null,
  weight double precision not null default 1,
  proof_provided boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  happened_at timestamptz not null,
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);

create table verification_events_2026_04 partition of verification_events
  for values from ('2026-04-01') to ('2026-05-01');
create table verification_events_default partition of verification_events default;
create index verification_events_listing_idx on verification_events (listing_id, created_at desc);

create table trust_signals (
  id varchar(64) not null,
  listing_id varchar(64) not null references listings(id),
  signal_type varchar(64) not null,
  signal_weight double precision not null,
  source_contribution_id varchar(64) references contributions(id),
  source_report_id varchar(64) references reports(id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);

create table trust_signals_2026_04 partition of trust_signals
  for values from ('2026-04-01') to ('2026-05-01');
create table trust_signals_default partition of trust_signals default;
create index trust_signals_listing_idx on trust_signals (listing_id, created_at desc);

create table confidence_snapshots (
  id varchar(64) primary key,
  listing_id varchar(64) not null references listings(id),
  score double precision not null,
  trust_band trust_band not null,
  visibility_state visibility_state not null,
  recent_confirmations integer not null default 0,
  negative_signals integer not null default 0,
  fresh_until_at timestamptz not null,
  recheck_after_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index confidence_snapshots_listing_idx on confidence_snapshots (listing_id, created_at desc);

create table points_ledger (
  id varchar(64) not null,
  user_id varchar(64) not null references users(id),
  reason varchar(120) not null,
  status ledger_status not null,
  points_delta integer not null,
  contribution_id varchar(64) references contributions(id),
  verification_event_id varchar(64),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);

create table points_ledger_2026_04 partition of points_ledger
  for values from ('2026-04-01') to ('2026-05-01');
create table points_ledger_default partition of points_ledger default;
create index points_ledger_user_idx on points_ledger (user_id, created_at desc);
create index points_ledger_pending_idx on points_ledger (user_id, created_at desc) where status = 'pending';

create table streaks (
  user_id varchar(64) primary key references users(id),
  current_streak_days integer not null default 0,
  longest_streak_days integer not null default 0,
  last_qualified_date timestamptz,
  updated_at timestamptz not null default now()
);

create table badges (
  id varchar(64) primary key,
  code varchar(120) not null unique,
  title varchar(120) not null,
  description text not null,
  min_points integer not null default 0,
  created_at timestamptz not null default now()
);

create table leaderboard_snapshots (
  id varchar(64) primary key,
  window leaderboard_window not null,
  snapshot_date timestamptz not null,
  user_id varchar(64) not null references users(id),
  rank integer not null,
  points integer not null,
  level_title varchar(120) not null,
  created_at timestamptz not null default now()
);

create index leaderboard_snapshots_idx on leaderboard_snapshots (window, snapshot_date desc, rank asc);

create table notification_preferences (
  user_id varchar(64) primary key references users(id),
  contribution_resolved boolean not null default true,
  points_finalized boolean not null default true,
  trust_status_changed boolean not null default true,
  marketing_announcements boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table notifications (
  id varchar(64) primary key,
  user_id varchar(64) not null references users(id),
  kind notification_kind not null,
  title text not null,
  body text not null,
  reference_type varchar(64),
  reference_id varchar(64),
  deep_link text,
  metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_created_idx on notifications (user_id, created_at desc);
create index notifications_user_read_idx on notifications (user_id, read_at);

create table device_registrations (
  id varchar(64) primary key,
  user_id varchar(64) not null references users(id),
  platform platform_type not null,
  device_identifier varchar(160) not null,
  push_token text not null,
  app_version varchar(64),
  last_seen_at timestamptz not null default now(),
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index device_registrations_user_device_idx on device_registrations (user_id, device_identifier);
create index device_registrations_user_disabled_idx on device_registrations (user_id, disabled_at);

create table notification_deliveries (
  id varchar(64) primary key,
  notification_id varchar(64) not null references notifications(id),
  device_id varchar(64) not null references device_registrations(id),
  channel varchar(64) not null,
  status notification_delivery_status not null default 'queued',
  provider_message_id varchar(255),
  attempted_at timestamptz,
  delivered_at timestamptz,
  failed_at timestamptz,
  failure_reason text,
  created_at timestamptz not null default now()
);

create index notification_deliveries_notification_idx on notification_deliveries (notification_id);
create index notification_deliveries_device_idx on notification_deliveries (device_id);
create index notification_deliveries_status_idx on notification_deliveries (status, created_at);

create table telemetry_events (
  id varchar(64) primary key,
  user_id varchar(64) references users(id),
  device_id varchar(64) references device_registrations(id),
  session_id varchar(160),
  event_name varchar(160) not null,
  event_payload jsonb not null default '{}'::jsonb,
  app_version varchar(64),
  platform platform_type,
  created_at timestamptz not null default now()
);

create index telemetry_events_created_idx on telemetry_events (created_at);
create index telemetry_events_name_created_idx on telemetry_events (event_name, created_at);
create index telemetry_events_user_created_idx on telemetry_events (user_id, created_at);

create table audit_logs (
  id varchar(64) not null,
  actor_user_id varchar(64) not null references users(id),
  action varchar(160) not null,
  entity_type varchar(64) not null,
  entity_id varchar(64) not null,
  request_id varchar(120) not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);

create table audit_logs_2026_04 partition of audit_logs
  for values from ('2026-04-01') to ('2026-05-01');
create table audit_logs_default partition of audit_logs default;
create index audit_logs_actor_idx on audit_logs (actor_user_id, created_at desc);

create table outbox_events (
  id varchar(64) primary key,
  event_type varchar(160) not null,
  aggregate_type varchar(64) not null,
  aggregate_id varchar(64) not null,
  payload jsonb not null,
  status outbox_status not null default 'pending',
  idempotency_key varchar(160) not null unique,
  attempts integer not null default 0,
  occurred_at timestamptz not null,
  published_at timestamptz
);

create index outbox_pending_idx on outbox_events (status, occurred_at asc);
create index outbox_retry_partial_idx on outbox_events (occurred_at asc) where status in ('pending', 'failed');

create table idempotency_keys (
  idempotency_key varchar(160) primary key,
  scope varchar(120) not null,
  request_hash varchar(160) not null,
  response_body jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create index idempotency_keys_expiry_idx on idempotency_keys (expires_at asc);

create table search_documents (
  id varchar(64) primary key,
  listing_id varchar(64) not null references listings(id),
  venue_id varchar(64) not null references venues(id),
  neighborhood_slug varchar(120) not null,
  title text not null,
  body text not null,
  search_vector tsvector generated always as (
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(body, '')), 'B')
  ) stored,
  updated_at timestamptz not null default now()
);

create unique index search_documents_listing_idx on search_documents (listing_id);
create index search_documents_tsv_idx on search_documents using gin (search_vector);
create index search_documents_title_trgm_idx on search_documents using gin (title gin_trgm_ops);
create index search_documents_neighborhood_idx on search_documents (neighborhood_slug, updated_at desc);
