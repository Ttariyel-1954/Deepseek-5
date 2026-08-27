-- =====================================================================
--  DeepSeek-4 ERP v5 — Migration 005: Layihə progress kolonu
--  Mərhələ triggeri bu kolonu avtomatik yeniləyir
--  Tarix: 2026-08-25
-- =====================================================================

BEGIN;

ALTER TABLE layihe.layihe
    ADD COLUMN IF NOT EXISTS progres NUMERIC(5,2) NOT NULL DEFAULT 0;

COMMIT;
