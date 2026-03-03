# CLAUDE.md — Project Context for AI Assistant

## 1. PROJECT OVERVIEW

**What:** Greenfield migration of a mobile app backend from PHP/Slim to Python.
**Why:** "Sovereign Architecture" — full ownership of identity/auth with high security standards.
**Phase:** Active rebuild. DB schema is near-stable; application layer is being built from scratch.
**Base URL:** `https://my-app-2-6c18.onrender.com`
**Stability:** Unstable. Prioritize async, type-safety, and performance in all decisions.

---

## 2. TECH STACK

| Layer        | Choice                                | Notes                                      |
|--------------|---------------------------------------|--------------------------------------------|
| Language     | Python 3.11+                          | Type hints required everywhere             |
| Framework    | FastAPI *(preferred)* or Litestar     | Must be async-first                        |
| ORM/Driver   | SQLAlchemy (Async) *(preferred)* or Prisma Client Python | Existing schema must be respected — no renames |
| Auth         | Custom OTP + JWT (HS256)              | Replaces `firebase/php-jwt`                |
| Mail         | MailerSend API via `httpx`            |                                            |
| Database     | PostgreSQL (Supabase-hosted)          | RLS enforced at app layer                  |

---

## 3. KEY DIRECTORIES & PURPOSES

```
src/
└── app/
    ├── core/
    │   └── config.py         # Type-safe env vars (Pydantic Settings)
    ├── db/
    │   └── session.py        # Async DB session manager + RLS injection
    ├── services/
    │   └── auth.py           # OTP generation, JWT issuance, PII encryption
    └── api/
        └── v1/
            └── endpoints/    # Route handlers (one file per domain)

database/
└── definitions/              # Source-of-truth SQL, organised by table
    ├── core/
    └── shared/

supabase/
└── migrations/               # Assembled migration file (do not hand-edit)

tests/                        # Shell-script based curl tests
test-output/                  # Auto-generated test results (gitignored)
```

---

## 4. CRITICAL ARCHITECTURE RULES

### RLS Enforcement (Non-negotiable)
Every authenticated request **must** execute this at the start of the transaction:
```sql
SET LOCAL app.current_user_id = '<uid>';
```
Failure to do this bypasses Row Level Security. Never skip it.

### Database Table Names
Do **not** rename or alias existing tables. Exact names must be preserved:

| Purpose             | Table Name                         |
|---------------------|------------------------------------|
| Users               | `aaaaff_ljus_users`                |
| Email lookup (PII)  | `aaaafm_email_lookup`              |
| OTP ledger          | `aaaaki_admin_otp_requests`        |
| OTP rate limits     | `aaaakj_admin_otp_counters`        |
| Invitations         | `aaaakk_admin_invitations`         |
| Registration policy | `aaaakl_admin_registration_policy` |

### PII Handling
- Emails stored with HMAC/encryption in `aaaafm_email_lookup`
- Never log or expose raw PII

---

## 5. BUILD & TEST COMMANDS

```bash
# Install dependencies
pip install -r requirements.txt

# Run dev server (FastAPI example)
uvicorn app.main:app --reload --port 8000

# Run a test script
bash tests/auth/test_otp_request.sh

# Test output lands in:
# test-output/<test-name>-<timestamp>/
#   headers.txt   (curl -D output)
#   body.txt      (response body)
```

### Test Script Rules
- **Tools allowed:** `grep`, `cut`, `awk`, `sed` — **NO `jq`**
- Always separate headers (`-D headers.txt`) from body (`body.txt`)
- Output directory: `test-output/<n>-<timestamp>/`

---

## 6. SQL LINTING WITH SQUAWK

### How the workflow fits together
- SQL is authored in `database/definitions/` (one file per concern per table)
- The migration is assembled by `build.sh` into `supabase/migrations/`
- **Squawk lints the assembled migration file** — not the individual definition files
- After linting and fixing, run `supabase db reset --linked` to apply

### Running the linter
```bash
./lint.sh
```
Always run this after editing any definition file and before running `supabase db reset --linked`.

### What Claude should do when running the linter
1. Run `./lint.sh`
2. Read every warning carefully
3. Identify which definition file contains the offending SQL
4. Fix the issue in the correct definition file (never directly in the migration)
5. Report back with a clear summary: what warnings were found, which files were changed, what was changed, and why

### Excluded rules
Three rules are intentionally excluded. Reasons are documented inside `lint.sh`.
Do not suppress additional warnings with inline `-- squawk:ignore` comments without
explaining the reason to the user first.

### Config note
`.squawk.toml` exists in the project root but is not used — the installed version of
Squawk does not reliably read it. Rules are passed via `--exclude` in `lint.sh` instead.

---

## 7. ADDITIONAL DOCUMENTATION TO CHECK

When working on specific areas, consult these files if they exist:

| Area                  | File to Check                          |
|-----------------------|----------------------------------------|
| DB schema details     | `docs/schema.md` or Supabase dashboard |
| Auth flow             | `docs/auth-flow.md`                    |
| OTP policy rules      | `docs/otp-policy.md`                   |
| API contract          | `docs/api-v1.md` or OpenAPI spec       |
| Environment variables | `.env.example`                         |
| Deployment config     | `render.yaml` or `docs/deploy.md`      |