-- database/seeds/prod/01_langs.sql

INSERT INTO aaaagg_admin_langs (code, label, is_user_lang, is_app_lang) VALUES
  ('en-US',    'English (US)',              TRUE, TRUE),
  ('es',       'Spanish',                   TRUE, TRUE),
  ('fr',       'French',                    TRUE, TRUE),
  ('pt-BR',    'Portuguese (Brazil)',        TRUE, TRUE),
  ('ar',       'Arabic',                    TRUE, TRUE),
  ('hi',       'Hindi',                     TRUE, TRUE),
  ('zh-Hans',  'Chinese (Simplified)',       TRUE, TRUE),
  ('zh-Hant',  'Chinese (Traditional)',      TRUE, TRUE),
  ('sv',       'Swedish',                   TRUE, FALSE)
ON CONFLICT DO NOTHING;
