-- =====================================================================
--  DeepSeek-4 ERP v5 — Bütün Cədvəllərin Silinməsi
--  Diqqət: Bu skript bütün sxemləri silir — yalnız sıfırdan qurmaq üçün!
--  13 sxem (6 əsas + 7 yeni: ai, sened, risk, keyfiyyet, logistika, tehlike, audit)
--  Tarix: 2026-08-25
-- =====================================================================

BEGIN;

DROP SCHEMA IF EXISTS hesabat   CASCADE;
DROP SCHEMA IF EXISTS audit     CASCADE;
DROP SCHEMA IF EXISTS tehlike   CASCADE;
DROP SCHEMA IF EXISTS logistika CASCADE;
DROP SCHEMA IF EXISTS keyfiyyet CASCADE;
DROP SCHEMA IF EXISTS risk      CASCADE;
DROP SCHEMA IF EXISTS sened     CASCADE;
DROP SCHEMA IF EXISTS ai        CASCADE;
DROP SCHEMA IF EXISTS kadr      CASCADE;
DROP SCHEMA IF EXISTS maliyye   CASCADE;
DROP SCHEMA IF EXISTS satinalma CASCADE;
DROP SCHEMA IF EXISTS layihe    CASCADE;
DROP SCHEMA IF EXISTS ref       CASCADE;
DROP SCHEMA IF EXISTS auth      CASCADE;

COMMIT;
