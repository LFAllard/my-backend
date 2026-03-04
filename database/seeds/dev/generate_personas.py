#!/usr/bin/env python3
"""
database/seeds/dev/generate_personas.py

Generates supabase/seed.sql by combining:
  1. All prod seed files (database/seeds/prod/*.sql) in order
  2. 100 dev personas with encrypted PII

Output: supabase/seed.sql  (gitignored — contains computed secrets)

Usage:
    python database/seeds/dev/generate_personas.py

Required environment variables (or .env in project root):
    HMAC_SECRET_KEY      — arbitrary secret string for HMAC-SHA256 email blind index
    PII_ENCRYPTION_KEY   — 64 hex chars (32 bytes) for AES-256-GCM email encryption
"""

import base64
import hashlib
import hmac
import os
import pathlib
import sys

try:
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
except ImportError:
    sys.exit("Missing dependency: pip install cryptography")

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[3]
PROD_SEEDS_DIR = PROJECT_ROOT / "database" / "seeds" / "prod"
OUTPUT_FILE = PROJECT_ROOT / "supabase" / "seed.sql"
ENV_FILE = PROJECT_ROOT / ".env"


# ---------------------------------------------------------------------------
# Environment loading
# ---------------------------------------------------------------------------
def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, _, value = line.partition("=")
                env[key.strip()] = value.strip().strip("\"'")
    env.update(os.environ)  # environment variables take precedence
    return env


# ---------------------------------------------------------------------------
# Crypto helpers
# ---------------------------------------------------------------------------
def compute_email_hash(email: str, secret: str) -> bytes:
    """HMAC-SHA256 blind index — stored as BYTEA in DB."""
    return hmac.new(secret.encode(), email.encode(), hashlib.sha256).digest()


def encrypt_email(email: str, key_bytes: bytes) -> str:
    """AES-256-GCM encryption — base64-encoded for TEXT column storage.
    Wire format: 12-byte nonce || ciphertext+tag (all base64url-encoded).
    """
    nonce = os.urandom(12)
    ciphertext = AESGCM(key_bytes).encrypt(nonce, email.encode(), None)
    return base64.b64encode(nonce + ciphertext).decode()


# ---------------------------------------------------------------------------
# Persona definitions  (A–Y, 25 per group)
# ---------------------------------------------------------------------------
SWEDISH_MALES = [
    "adam", "bertil", "clas", "david", "erik",
    "fredrik", "gustav", "hans", "ivar", "johan",
    "karl", "lars", "magnus", "nils", "oskar",
    "per", "quirin", "ragnar", "sven", "thomas",
    "ulf", "viktor", "wilhelm", "xaver", "yngve",
]

SWEDISH_FEMALES = [
    "alice", "britta", "cecilia", "dagmar", "elsa",
    "frida", "gunilla", "helga", "ingrid", "johanna",
    "karin", "lena", "maria", "nina", "olivia",
    "petra", "quirina", "ragnhild", "sofia", "therese",
    "ulla", "vera", "wilma", "xenia", "yvonne",
]

IRISH_MALES = [
    "aidan", "brendan", "conor", "declan", "eoin",
    "fergus", "gavin", "hugh", "ian", "jack",
    "kevin", "liam", "michael", "niall", "owen",
    "patrick", "quinn", "ronan", "sean", "thomas",
    "ultan", "vincent", "william", "xander", "yusuf",
]

IRISH_FEMALES = [
    "aoife", "brigid", "ciara", "deirdre", "eileen",
    "fionnuala", "grace", "hannah", "iona", "jennifer",
    "kate", "lily", "maeve", "niamh", "orla",
    "patricia", "queenie", "roisin", "siobhan", "tara",
    "una", "vivienne", "winifred", "xanthe", "yvonne",
]

# Note: 'thomas' appears in both SWEDISH_MALES and IRISH_MALES.
# Different domains keep emails unique: thomas@svensson.se vs thomas@joyce.ie.

PERSONA_GROUPS = [
    (SWEDISH_MALES,   "svensson.se"),
    (SWEDISH_FEMALES, "svensson.se"),
    (IRISH_MALES,     "joyce.ie"),
    (IRISH_FEMALES,   "joyce.ie"),
]


def build_personas() -> list[dict]:
    personas = []
    uid = 1
    for names, domain in PERSONA_GROUPS:
        for name in names:
            personas.append({
                "id": uid,
                "email": f"{name}@{domain}",
                "role": "super_admin" if uid == 1 else "user",
            })
            uid += 1
    return personas


# ---------------------------------------------------------------------------
# SQL generation
# ---------------------------------------------------------------------------
def sql_literal(value: bytes) -> str:
    """Encode bytes as a PostgreSQL hex decode expression for BYTEA columns."""
    return f"decode('{value.hex()}', 'hex')"


def build_persona_sql(personas: list[dict], hmac_secret: str, pii_key: bytes) -> str:
    u_rows: list[str] = []
    el_rows: list[str] = []
    r_rows: list[str] = []

    for p in personas:
        email = p["email"]
        email_hash = compute_email_hash(email, hmac_secret)
        encrypted = encrypt_email(email, pii_key)

        u_rows.append(f"    ({p['id']})")
        el_rows.append(
            f"    ({p['id']}, {sql_literal(email_hash)}, '{encrypted}')"
        )
        r_rows.append(f"    ({p['id']}, '{p['role']}', 'global')")

    lines = ["-- Dev personas (100 users, auto-generated — do not hand-edit)\n"]

    lines.append("-- aaaaff_users")
    lines.append(
        "INSERT INTO aaaaff_users (id) OVERRIDING SYSTEM VALUE VALUES\n"
        + ",\n".join(u_rows)
        + "\nON CONFLICT (id) DO NOTHING;\n"
    )

    lines.append(
        "-- Advance the sequence past the seeded IDs so new signups don't collide"
    )
    lines.append(f"SELECT setval(pg_get_serial_sequence('aaaaff_users', 'id'), {len(personas)}, true);\n")

    lines.append("-- aaaafm_email_lookup")
    lines.append(
        "INSERT INTO aaaafm_email_lookup (user_id, email_hash, encrypted_email) VALUES\n"
        + ",\n".join(el_rows)
        + "\nON CONFLICT (user_id) DO NOTHING;\n"
    )

    lines.append("-- aaaaft_roles")
    lines.append(
        "INSERT INTO aaaaft_roles (user_id, role_key, scope_key) VALUES\n"
        + ",\n".join(r_rows)
        + "\nON CONFLICT DO NOTHING;\n"
    )

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    env = load_env()

    hmac_secret = env.get("HMAC_SECRET_KEY")
    pii_key_hex = env.get("PII_ENCRYPTION_KEY")

    if not hmac_secret:
        sys.exit("Error: HMAC_SECRET_KEY is not set.")
    if not pii_key_hex:
        sys.exit("Error: PII_ENCRYPTION_KEY is not set.")
    if len(pii_key_hex) != 64:
        sys.exit(
            f"Error: PII_ENCRYPTION_KEY must be 64 hex chars (32 bytes). Got {len(pii_key_hex)} chars."
        )

    try:
        pii_key = bytes.fromhex(pii_key_hex)
    except ValueError:
        sys.exit("Error: PII_ENCRYPTION_KEY is not valid hex.")

    # Assemble prod seed files in sorted order
    prod_files = sorted(PROD_SEEDS_DIR.glob("*.sql"))
    if not prod_files:
        sys.exit(f"Error: No .sql files found in {PROD_SEEDS_DIR}")

    sections: list[str] = [
        "-- AUTO-GENERATED SEED FILE — DO NOT HAND-EDIT\n"
        "-- Regenerate with: python database/seeds/dev/generate_personas.py\n",
        "BEGIN;\n",
    ]

    for path in prod_files:
        sections.append(f"-- === {path.name} ===")
        sections.append(path.read_text().strip() + "\n")

    personas = build_personas()
    sections.append("-- === dev/personas ===")
    sections.append(build_persona_sql(personas, hmac_secret, pii_key))

    sections.append("COMMIT;")

    output = "\n".join(sections)
    OUTPUT_FILE.write_text(output)
    print(f"✓ seed.sql written — {len(personas)} personas, {len(prod_files)} prod files")
    print(f"  → {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
