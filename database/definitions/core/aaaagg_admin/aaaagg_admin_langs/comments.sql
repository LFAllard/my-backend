COMMENT ON TABLE aaaagg_admin_langs IS 'Registry of supported languages, with user/app usage flags.';
COMMENT ON COLUMN aaaagg_admin_langs.code IS 'Language code (BCP 47 or ISO), e.g., "en-US", "zh-Hant".';
COMMENT ON COLUMN aaaagg_admin_langs.is_user_lang IS 'Indicates if users can select this language in profile.';
COMMENT ON COLUMN aaaagg_admin_langs.is_app_lang IS 'Indicates if this language is supported for content/UI.';