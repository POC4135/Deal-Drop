-- Migration: listing_images table
-- Stores user-uploaded photos attached to listings.
-- Images are stored in Supabase Storage (or MinIO in dev); only the asset key is stored here.

create type listing_image_status as enum ('pending', 'active', 'deleted');

create table listing_images (
  id                   varchar(64)           primary key,
  listing_id           varchar(64)           not null references listings(id) on delete cascade,
  uploaded_by_user_id  varchar(64)           references users(id) on delete set null,
  asset_key            varchar(512)          not null,
  content_type         varchar(64)           not null default 'image/jpeg',
  status               listing_image_status  not null default 'pending',
  created_at           timestamptz           not null default now(),
  updated_at           timestamptz           not null default now()
);

create index listing_images_listing_idx on listing_images(listing_id, status);
create index listing_images_user_idx   on listing_images(uploaded_by_user_id);
