-- database/seeds/prod/10_otp_policies.sql
-- Production rate limits + permissive development overrides.
-- Development rows are 10x production limits to allow unimpeded local testing.

INSERT INTO aaaakf_admin_otp_req_policies
  (env, route, platform, key_type, rl_window, limit_count, notes)
VALUES
  -- Production limits
  ('production', '/public/otp/request', '*', 'pair',   '60s',  1,    'cooldown per email+device'),
  ('production', '/public/otp/request', '*', 'email',  '5m',   3,    'anti-burst per email'),
  ('production', '/public/otp/request', '*', 'email',  '1h',   10,   'sustained per email'),
  ('production', '/public/otp/request', '*', 'email',  '24h',  25,   'daily per email'),
  ('production', '/public/otp/request', '*', 'device', '5m',   3,    'per device burst'),
  ('production', '/public/otp/request', '*', 'device', '1h',   10,   'per device sustained'),
  ('production', '/public/otp/request', '*', 'device', '24h',  20,   'per device daily'),
  ('production', '/public/otp/request', '*', 'ip',     '5m',   10,   'looser for NAT users'),
  ('production', '/public/otp/request', '*', 'ip',     '1h',   60,   'ip hourly'),
  ('production', '/public/otp/request', '*', 'ip',     '24h',  300,  'ip daily'),
  ('production', '/public/otp/request', '*', 'global', '60s',  60,   'safety net'),
  ('production', '/public/otp/request', '*', 'global', '1h',   2000, 'safety net hourly'),

  -- Development limits (10x production — unimpeded local testing)
  ('development', '/public/otp/request', '*', 'pair',   '60s',  10,    'dev: cooldown per email+device'),
  ('development', '/public/otp/request', '*', 'email',  '5m',   30,   'dev: anti-burst per email'),
  ('development', '/public/otp/request', '*', 'email',  '1h',   100,  'dev: sustained per email'),
  ('development', '/public/otp/request', '*', 'email',  '24h',  250,  'dev: daily per email'),
  ('development', '/public/otp/request', '*', 'device', '5m',   30,   'dev: per device burst'),
  ('development', '/public/otp/request', '*', 'device', '1h',   100,  'dev: per device sustained'),
  ('development', '/public/otp/request', '*', 'device', '24h',  200,  'dev: per device daily'),
  ('development', '/public/otp/request', '*', 'ip',     '5m',   100,  'dev: looser for NAT users'),
  ('development', '/public/otp/request', '*', 'ip',     '1h',   600,  'dev: ip hourly'),
  ('development', '/public/otp/request', '*', 'ip',     '24h',  3000, 'dev: ip daily'),
  ('development', '/public/otp/request', '*', 'global', '60s',  600,  'dev: safety net'),
  ('development', '/public/otp/request', '*', 'global', '1h',   20000,'dev: safety net hourly')

ON CONFLICT DO NOTHING;
