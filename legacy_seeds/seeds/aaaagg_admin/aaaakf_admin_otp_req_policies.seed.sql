-- Environment: production
insert into aaaakf_admin_otp_req_policies
(env, route, platform, key_type, rl_window, limit_count, notes)
values
('production','/public/otp/request','*','pair','60s', 1, 'cooldown per email+device'),
('production','/public/otp/request','*','email','5m', 3,  'anti-burst per email'),
('production','/public/otp/request','*','email','1h', 10, 'sustained per email'),
('production','/public/otp/request','*','email','24h',25, 'daily per email'),
('production','/public/otp/request','*','device','5m', 3,  'per device burst'),
('production','/public/otp/request','*','device','1h', 10, 'per device sustained'),
('production','/public/otp/request','*','device','24h',20, 'per device daily'),
('production','/public/otp/request','*','ip','5m', 10,     'looser for NAT users'),
('production','/public/otp/request','*','ip','1h', 60,     'ip hourly'),
('production','/public/otp/request','*','ip','24h',300,    'ip daily'),
('production','/public/otp/request','*','global','60s',60, 'safety net'),
('production','/public/otp/request','*','global','1h',2000,'safety net hourly');
