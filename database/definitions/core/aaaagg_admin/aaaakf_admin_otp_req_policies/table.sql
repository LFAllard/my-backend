create table aaaakf_admin_otp_req_policies (
  id               bigserial primary key,
  env              text not null,                  -- 'production' | 'staging' | 'test'
  route            text not null,                  -- e.g. '/public/otp/request' (or '*')
  platform         text not null default '*',      -- 'ios' | 'android' | '*'
  app_version_min  text null,                      -- semver lower bound (inclusive)
  app_version_max  text null,                      -- semver upper bound (inclusive)
  key_type         auth_rl_key not null,
  rl_window        auth_rl_window not null,        -- 60s | 5m | 1h | 24h
  limit_count      integer not null check (limit_count > 0),
  enabled          boolean not null default true,
  notes            text,
  updated_by       text not null default 'sql',
  updated_at       timestamptz not null default now()
);