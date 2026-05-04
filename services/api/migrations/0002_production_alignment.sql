alter type platform_type add value if not exists 'macos';
alter type platform_type add value if not exists 'windows';
alter type platform_type add value if not exists 'linux';

create table if not exists listing_offers (
  id varchar(64) primary key,
  listing_id varchar(64) not null references listings(id),
  title varchar(255) not null,
  original_price double precision not null,
  deal_price double precision not null,
  currency varchar(8) not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists listing_offers_listing_idx on listing_offers (listing_id, deal_price);

alter table device_registrations alter column push_token drop not null;

alter table contribution_proofs
  alter column contribution_id drop not null,
  add column if not exists upload_url text,
  add column if not exists status varchar(32) not null default 'pending_upload',
  add column if not exists metadata jsonb not null default '{}'::jsonb;

create index if not exists contribution_proofs_status_idx on contribution_proofs (status, uploaded_at);
