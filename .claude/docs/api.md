# API Reference

## Auth flow

*To be documented as the Python layer is built.*

Key decisions already made:
- Email OTP only — no password, no OAuth
- Custom-built rate limiting (calls `aaaakj_evaluate_otp_request` DB function)
- JWT issued on successful OTP verification (HS256, secret from env)
- No Firebase, no external auth library

---

## OTP request flow (planned)

1. Client POSTs email + device_id to `/public/otp/request`
2. App calls `aaaakj_evaluate_otp_request()` — returns allow/throttle/block decision
3. If allowed: generate OTP, store in `aaaaki_admin_otp_requests`, send via MailerSend
4. Client POSTs OTP code to `/public/otp/verify`
5. App calls `aaaaki_verify_otp()` — returns user_id on success
6. App issues JWT, returns to client

---

## Environment variables

| Variable            | Purpose                                         |
|---------------------|-------------------------------------------------|
| `HMAC_SECRET_KEY`   | HMAC-SHA256 blind index for email lookups       |
| `PII_ENCRYPTION_KEY`| AES-256-GCM email encryption (64 hex chars)     |
| `JWT_SECRET`        | JWT signing secret (HS256)                      |
| `MAILERSEND_API_KEY`| MailerSend transactional email                  |
| `DATABASE_URL`      | Async PostgreSQL connection string              |
| `SUPABASE_DB_PASSWORD` | Used by Supabase CLI for `db reset --linked` |
| `APP_ENV`           | `production` / `development` / `test`           |

---

## API versioning

All routes under `/api/v1/`. One file per domain under `src/app/api/v1/endpoints/`.

---

## Deployment

Hosted on Render. Environment variables set in Render dashboard.
`render.yaml` or `docs/deploy.md` for deployment config (to be added).
