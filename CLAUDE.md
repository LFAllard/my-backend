# CLAUDE.md — Project Context for AI Assistant

## 1. PROJECT OVERVIEW

**What:** Greenfield migration of a mobile app backend from PHP/Slim to Python.
**Why:** "Sovereign Architecture" — full ownership of identity/auth with high security standards.
**Phase:** Active rebuild. DB schema is near-stable; Python application layer is being built from scratch.
**Stability:** Unstable. Prioritize async, type-safety, and performance in all decisions.

---

## 2. TECH STACK

| Layer      | Choice                                               | Notes                              |
|------------|------------------------------------------------------|------------------------------------|
| Language   | Python 3.11+                                         | Type hints required everywhere     |
| Framework  | FastAPI                                              | Async-first                        |
| ORM/Driver | SQLAlchemy (Async)                                   | Schema must be respected — no renames |
| Auth       | Custom OTP + JWT (HS256)                             | Custom-built; no library adequate  |
| Mail       | MailerSend API via `httpx`                           |                                    |
| Database   | PostgreSQL (Supabase-hosted)                         | RLS enforced at app layer          |

---

## 3. KEY DIRECTORIES

```
src/app/
├── core/config.py          # Type-safe env vars (Pydantic Settings)
├── db/session.py           # Async session manager + RLS injection
├── services/auth.py        # OTP, JWT, PII encryption
└── api/v1/endpoints/       # Route handlers (one file per domain)

database/
├── definitions/            # Source-of-truth SQL — edit here, never in migrations
│   └── core/
└── seeds/
    ├── prod/               # Static reference data (01–11, committed)
    └── dev/generate_personas.py  # Generates supabase/seed.sql (gitignored)

supabase/migrations/        # Assembled by build.sh — do not hand-edit

tests/                      # Shell-script curl tests
test-output/                # Auto-generated (gitignored)
```

---

## 4. NON-NEGOTIABLE RULES

### RLS — must never be skipped
Every authenticated request must execute this at the start of the transaction:
```sql
SET LOCAL app.current_user_id = '<uid>';
```

### Table names — never rename or alias
See `.claude/docs/database.md` for the full list.

### PII discipline
- Raw email is never stored. It is HMAC-hashed (blind index) and AES-256-GCM encrypted.
- See `.claude/docs/database.md` for the encryption scheme and env vars.
- Never log or expose raw PII.

### Test scripts
- Allowed tools: `grep`, `cut`, `awk`, `sed` — **no `jq`**
- Always separate headers (`-D headers.txt`) from body (`body.txt`)
- Output to: `test-output/<name>-<timestamp>/`

---

## 5. COMMANDS

```bash
# Install dependencies
pip install -r requirements.txt

# Dev server
uvicorn app.main:app --reload --port 8000

# DB: build migration, lint, apply
bash database/build.sh
bash lint.sh
python database/seeds/dev/generate_personas.py
supabase db reset --linked

# Run a test
bash tests/auth/test_otp_request.sh
```

---

## 6. SPECIALIST DOCS

| Topic                         | File                          |
|-------------------------------|-------------------------------|
| DB schema, tables, workflow   | `.claude/docs/database.md`    |
| API design, auth flow, env vars | `.claude/docs/api.md`       |
