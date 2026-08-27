-- =====================================================================
--  DeepSeek-4 ERP — Migration 002: İstifadəçilər Cədvəli
--  Dərs 2-də (Auth/JWT) yaradılıb
--  Parollar backend tərəfində bcrypt ilə heşlənir
--  Tarix: 2026-08-24
-- =====================================================================

BEGIN;

-- Auth cədvəli üçün sxem (mövcud deyilsə)
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
    user_id     SERIAL PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    email       VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name   VARCHAR(150),
    role        VARCHAR(30) NOT NULL DEFAULT 'istifadeci'
                CHECK (role IN ('admin','mudir','muellim','istifadeci','auditor')),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    last_login  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- İlkin admin istifadəçi
-- Şifrə: admin123 (bcrypt hash-i istehsal vaxtı yenilənir)
-- Qeyd: İstehsal mühitində ilkin şifrə dərhal dəyişdirilməlidir!
-- INSERT ... aşağıda backend tərəfindən (seed) icra olunur
-- Bu fayl yalnız cədvəl strukturu üçündür.

COMMIT;
