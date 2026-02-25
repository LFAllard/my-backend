-- backend/database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/table.sql
-- Admin overrides for OTP request rate-limits (temporary, high-priority caps)

create table aaaakg_admin_otp_req_overrides (
  id               bigserial primary key,
  env              text not null,                  -- 'production' | 'staging' | 'test'
  route            text not null,                  -- e.g. '/public/otp/request'
  platform         text not null default '*',      -- 'ios' | 'android' | '*'
  app_version_min  text null,                      -- inclusive lower bound; NULL = no lower bound
  app_version_max  text null,                      -- inclusive upper bound; NULL = no upper bound
  key_type         auth_rl_key not null,           -- email | device | ip | pair | global
  rl_window        auth_rl_window not null,        -- 60s | 5m | 1h | 24h
  limit_count      integer not null check (limit_count > 0),
  reason           text,                           -- ops context (“vendor limiting”, “abuse wave”, etc.)
  enabled          boolean not null default true,  -- only enabled rows are considered
  expires_at       timestamptz null,               -- auto-disable after this instant
  updated_by       text not null,                  -- who set this override (email/login/service)
  updated_at       timestamptz not null default now()
);
