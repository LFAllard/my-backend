# Database Reference

## Schema authoring workflow

SQL is authored in `database/definitions/` — one subdirectory per table, one file per concern (`table.sql`, `indexes.sql`, `functions.sql`, `triggers.sql`, `rls.sql`, `cron.sql`).

`bash database/build.sh` assembles all definition files into a single timestamped migration in `supabase/migrations/`. **Never edit the migration file directly.**

After every change to a definition file:
1. `bash database/build.sh` — generates new migration, deletes old one
2. Update the filename in `lint.sh` to match the new timestamp
3. `bash lint.sh` — must show 0 issues
4. `python database/seeds/dev/generate_personas.py` — regenerates `supabase/seed.sql`
5. `supabase db reset --linked` — drops and rebuilds from scratch

---

## Squawk linter

Run via `bash lint.sh`. Always run after editing definitions, before `db reset`.

When warnings appear:
1. Read every warning carefully
2. Identify which definition file contains the offending SQL
3. Fix the definition file (never the migration)
4. Rebuild and re-lint

Six rules are intentionally excluded. Rationale is documented inside `lint.sh`. Do not add `-- squawk:ignore` inline suppressions without explaining the reason first.

`.squawk.toml` exists but is not used — the installed Squawk version does not reliably read it. Rules are passed via `--exclude` in `lint.sh`.

---

## Seed architecture

- `database/seeds/prod/01–11_*.sql` — static reference data, committed, applied on every reset
- `database/seeds/dev/generate_personas.py` — Python script, committed
- `supabase/seed.sql` — generated output, **gitignored** (contains computed secrets)
- `supabase/config.toml` is configured to load `./seed.sql` automatically on reset

Always regenerate `seed.sql` before `db reset --linked`:
```bash
python database/seeds/dev/generate_personas.py
```

The generator reads `HMAC_SECRET_KEY` and `PII_ENCRYPTION_KEY` from `.env`.

Dev personas: 100 users — Swedish male/female @svensson.se, Irish male/female @joyce.ie (A–Y, 25 each). User 1 (`adam@svensson.se`) = `super_admin`; all others = `user`.

---

## PII encryption scheme

| What              | Algorithm     | Stored as | Column                              | Env var             |
|-------------------|---------------|-----------|-------------------------------------|---------------------|
| Email blind index | HMAC-SHA256   | BYTEA     | `aaaafm_email_lookup.email_hash`    | `HMAC_SECRET_KEY`   |
| Email ciphertext  | AES-256-GCM   | TEXT (base64) | `aaaafm_email_lookup.encrypted_email` | `PII_ENCRYPTION_KEY` |

`PII_ENCRYPTION_KEY` must be exactly 64 hex chars (32 bytes).
Wire format for encrypted_email: `base64(12-byte-nonce || ciphertext+tag)`.

Both keys are stored as Render environment variables (no KMS needed at this stage).
See `database/seeds/dev/generate_personas.py` for the reference implementation.

**Key rotation requires a migration script** that re-encrypts every row. Do not rotate casually.

---

## Table names (do not rename or alias)

### Auth / identity

| Purpose               | Table                       |
|-----------------------|-----------------------------|
| Users                 | `aaaaff_users`              |
| Email lookup (PII)    | `aaaafm_email_lookup`       |
| User core data (PII)  | `aaaafp_user_core_data`     |
| Role definitions      | `aaaafs_role_definitions`   |
| User roles            | `aaaaft_roles`              |

### Admin / config

| Purpose               | Table                              |
|-----------------------|------------------------------------|
| Languages             | `aaaagg_admin_langs`               |
| Global IDs            | `aaaahf_admin_global_ids`          |
| Systems               | `aaaahg_admin_systems`             |
| Pools                 | `aaaahh_admin_pools`               |
| Config audit log      | `aaaakh_admin_config_audit`        |

### Geo reference

| Purpose               | Table                                      |
|-----------------------|--------------------------------------------|
| Countries             | `aaaaif_admin_geo_countries`               |
| Dialing codes         | `aaaaig_admin_geo_country_dialing_codes`   |
| Phone number lengths  | `aaaaih_admin_geo_phone_number_lengths`    |
| Age limits            | `aaaaij_admin_geo_age_limits`              |

### OTP / registration

| Purpose               | Table                               |
|-----------------------|-------------------------------------|
| OTP request policies  | `aaaakf_admin_otp_req_policies`     |
| OTP request overrides | `aaaakg_admin_otp_req_overrides`    |
| OTP requests (ledger) | `aaaaki_admin_otp_requests`         |
| OTP counters (RL)     | `aaaakj_admin_otp_counters`         |
| Invitations           | `aaaakk_admin_invitations`          |
| Registration policy   | `aaaakl_admin_registration_policy`  |
| Invitation entitlements | `aaaakm_user_invitation_entitlements` |

### OTP policy env values
`env` CHECK allows: `'production'`, `'staging'`, `'test'`, `'development'`
