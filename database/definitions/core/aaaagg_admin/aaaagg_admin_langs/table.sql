-- 🌐 Language table: unified with boolean flags
CREATE TABLE aaaagg_admin_langs (
  code TEXT PRIMARY KEY, -- BCP 47 or ISO language code
  label TEXT NOT NULL,   -- Human-readable name
  is_user_lang BOOLEAN NOT NULL DEFAULT FALSE,
  is_app_lang BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT app_subset_user CHECK (NOT is_app_lang OR is_user_lang)
);