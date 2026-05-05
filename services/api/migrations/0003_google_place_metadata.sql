alter table contributions
  add column if not exists google_place_id varchar(255),
  add column if not exists google_place_payload jsonb not null default '{}'::jsonb;

create index if not exists contributions_google_place_idx
  on contributions (google_place_id)
  where google_place_id is not null;

alter table venues
  add column if not exists google_place_id varchar(255),
  add column if not exists google_place_payload jsonb not null default '{}'::jsonb;

create unique index if not exists venues_google_place_idx
  on venues (google_place_id)
  where google_place_id is not null;
