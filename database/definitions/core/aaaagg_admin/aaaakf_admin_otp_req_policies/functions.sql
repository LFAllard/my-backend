-- backend/database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/functions.sql
-- Resolve effective OTP request limit: overrides (enabled & not expired) take precedence over baseline policies.

create or replace function aaaakf_get_effective_otp_limit(
  p_env        text,
  p_route      text,
  p_platform   text,
  p_app_version text,
  p_key_type   auth_rl_key,
  p_rl_window  auth_rl_window
)
returns table(limit_count int, source text, row_id bigint, route text, platform text)
language sql
stable
as
$$
  -- 1) Active overrides first
  (
    select
      o.limit_count,
      'override'::text as source,
      o.id as row_id,
      o.route,
      o.platform
    from aaaakg_admin_otp_req_overrides o
    where o.enabled
      and (o.expires_at is null or o.expires_at > now())
      and o.env = p_env
      and o.route in (p_route, '*')
      and o.platform in (p_platform, '*')
      and o.key_type = p_key_type
      and o.rl_window = p_rl_window
      and (o.app_version_min is null or semver_gte(p_app_version, o.app_version_min))
      and (o.app_version_max is null or semver_lte(p_app_version, o.app_version_max))
    order by
      -- Prefer exact route/platform over wildcard
      case when o.route = p_route then 0 else 1 end,
      case when o.platform = p_platform then 0 else 1 end,
      -- Prefer narrower version ranges
      (o.app_version_min is null) asc,
      (o.app_version_max is null) asc,
      -- Most recently updated wins among equals
      o.updated_at desc
    limit 1
  )
  union all
  -- 2) Baseline policies if no override matched
  (
    select
      p.limit_count,
      'policy'::text as source,
      p.id as row_id,
      p.route,
      p.platform
    from aaaakf_admin_otp_req_policies p
    where p.enabled
      and p.env = p_env
      and p.route in (p_route, '*')
      and p.platform in (p_platform, '*')
      and p.key_type = p_key_type
      and p.rl_window = p_rl_window
      and (p.app_version_min is null or semver_gte(p_app_version, p.app_version_min))
      and (p.app_version_max is null or semver_lte(p_app_version, p.app_version_max))
    order by
      case when p.route = p_route then 0 else 1 end,
      case when p.platform = p_platform then 0 else 1 end,
      (p.app_version_min is null) asc,
      (p.app_version_max is null) asc,
      p.updated_at desc
    limit 1
  )
  limit 1;
$$;
