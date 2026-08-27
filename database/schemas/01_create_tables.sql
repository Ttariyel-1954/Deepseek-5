-- =====================================================================
--  DeepSeek-4 ERP — Verilənlər Bazası Sxemi
--  Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi
--  Sxemlər: ref, layihe, satinalma, maliyye, kadr, hesabat (6 sxem)
--  Cədvəllər: 22
--  Tarix: 2026-08-24
-- =====================================================================

BEGIN;

-- =====================================================================
--  SXEMLƏRİN YARADILMASI
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS ref;        -- İstinad məlumatları
CREATE SCHEMA IF NOT EXISTS layihe;     -- Layihə idarəetməsi
CREATE SCHEMA IF NOT EXISTS satinalma;  -- Tender, müqavilə, tədarük
CREATE SCHEMA IF NOT EXISTS maliyye;    -- Büdcə, xərc, ödəniş
CREATE SCHEMA IF NOT EXISTS kadr;       -- Vəzifə, işçi, təyinat
CREATE SCHEMA IF NOT EXISTS hesabat;    -- Analitik view-lər

-- =====================================================================
--  ref SXEMİ — İSTİNAD MƏLUMATLARI
-- =====================================================================

-- İqtisadi rayonlar
CREATE TABLE IF NOT EXISTS ref.region (
    region_id   SERIAL PRIMARY KEY,
    ad          VARCHAR(100) NOT NULL UNIQUE,
    kod         VARCHAR(10)  UNIQUE,
    qeyd        TEXT,
    aktif       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Şəhərlər / rayonlar
CREATE TABLE IF NOT EXISTS ref.seher (
    seher_id    SERIAL PRIMARY KEY,
    region_id   INTEGER NOT NULL REFERENCES ref.region(region_id),
    ad          VARCHAR(100) NOT NULL,
    UNIQUE (region_id, ad),
    aktif       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Təhsil müəssisəsi növləri (məktəb, bağça, lisey, kollec...)
CREATE TABLE IF NOT EXISTS ref.muessise_novu (
    nov_id      SERIAL PRIMARY KEY,
    ad          VARCHAR(100) NOT NULL UNIQUE,
    qeyd        TEXT,
    aktif       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Təhsil müəssisələri (müştərilər)
CREATE TABLE IF NOT EXISTS ref.muessise (
    muessise_id SERIAL PRIMARY KEY,
    seher_id    INTEGER NOT NULL REFERENCES ref.seher(seher_id),
    nov_id      INTEGER NOT NULL REFERENCES ref.muessise_novu(nov_id),
    ad          VARCHAR(200) NOT NULL UNIQUE,
    voen        VARCHAR(20)  UNIQUE,
    unvan       VARCHAR(255),
    telefon     VARCHAR(50),
    email       VARCHAR(100),
    kontakt_ad  VARCHAR(100),
    aktif       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tikinti / təmir iş növləri (hierarxik — parent_id self FK)
CREATE TABLE IF NOT EXISTS ref.is_novu (
    is_novu_id  SERIAL PRIMARY KEY,
    parent_id   INTEGER REFERENCES ref.is_novu(is_novu_id),
    ad          VARCHAR(150) NOT NULL,
    kod         VARCHAR(20),
    vahid       VARCHAR(20) DEFAULT 'm²',
    aktif       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tikinti materialları növləri (hierarxik — parent_id self FK)
CREATE TABLE IF NOT EXISTS ref.material_novu (
    material_novu_id SERIAL PRIMARY KEY,
    parent_id   INTEGER REFERENCES ref.material_novu(material_novu_id),
    ad          VARCHAR(150) NOT NULL,
    kod         VARCHAR(20),
    vahid       VARCHAR(20) NOT NULL DEFAULT 'ədəd',
    aktif       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  layihe SXEMİ — LAYİHƏ İDARƏETMƏSİ
-- =====================================================================

-- Layihə statusları
CREATE TABLE IF NOT EXISTS layihe.layihe_status (
    status_id   SERIAL PRIMARY KEY,
    ad          VARCHAR(50) NOT NULL UNIQUE,
    kod         VARCHAR(30) UNIQUE,     -- plan, tenderde, icra, tamam, dayandi
    reng        VARCHAR(20) DEFAULT '#3b82f6',
    sira        INTEGER NOT NULL DEFAULT 0
);

-- Əsas layihə cədvəli
CREATE TABLE IF NOT EXISTS layihe.layihe (
    layihe_id       SERIAL PRIMARY KEY,
    muessise_id     INTEGER NOT NULL REFERENCES ref.muessise(muessise_id),
    is_novu_id      INTEGER NOT NULL REFERENCES ref.is_novu(is_novu_id),
    status_id       INTEGER NOT NULL DEFAULT 1 REFERENCES layihe.layihe_status(status_id),
    seher_id        INTEGER REFERENCES ref.seher(seher_id),
    kod             VARCHAR(30) UNIQUE,
    ad              VARCHAR(255) NOT NULL,
    tesvir          TEXT,
    plan_budce      NUMERIC(14,2) NOT NULL DEFAULT 0,
    bashlama_tarixi DATE,
    son_tarix       DATE,
    olcu            NUMERIC(12,2),
    vahid           VARCHAR(20) DEFAULT 'm²',
    silinib         BOOLEAN NOT NULL DEFAULT FALSE,   -- soft delete
    created_by      INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Layihə mərhələləri
CREATE TABLE IF NOT EXISTS layihe.layihe_merhele (
    merhele_id      SERIAL PRIMARY KEY,
    layihe_id       INTEGER NOT NULL REFERENCES layihe.layihe(layihe_id) ON DELETE CASCADE,
    ad              VARCHAR(150) NOT NULL,
    plan_faiz       NUMERIC(5,2) NOT NULL DEFAULT 0,
    real_faiz       NUMERIC(5,2) NOT NULL DEFAULT 0,
    plan_tarix      DATE,
    real_tarix      DATE,
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Layihə materialları
CREATE TABLE IF NOT EXISTS layihe.layihe_material (
    layihe_material_id SERIAL PRIMARY KEY,
    layihe_id       INTEGER NOT NULL REFERENCES layihe.layihe(layihe_id) ON DELETE CASCADE,
    material_novu_id INTEGER NOT NULL REFERENCES ref.material_novu(material_novu_id),
    miqdar          NUMERIC(12,2) NOT NULL DEFAULT 0,
    vahid           VARCHAR(20) NOT NULL DEFAULT 'ədəd',
    qiymet          NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Layihə işçiləri (müvəqqəti)
CREATE TABLE IF NOT EXISTS layihe.layihe_isci (
    layihe_isci_id  SERIAL PRIMARY KEY,
    layihe_id       INTEGER NOT NULL REFERENCES layihe.layihe(layihe_id) ON DELETE CASCADE,
    ad_soyad        VARCHAR(150) NOT NULL,
    vezife          VARCHAR(100),
    gunelik_mebleg  NUMERIC(10,2) NOT NULL DEFAULT 0,
    bashlama_tarixi DATE,
    son_tarix       DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  satinalma SXEMİ — TENDER, MÜQAVİLƏ, TƏDARÜK
-- =====================================================================

-- Tender statusları
CREATE TABLE IF NOT EXISTS satinalma.tender_status (
    status_id   SERIAL PRIMARY KEY,
    ad          VARCHAR(50) NOT NULL UNIQUE,
    kod         VARCHAR(30) UNIQUE,     -- elan, qebul, qiymetlendirme, qalib, legv
    reng        VARCHAR(20) DEFAULT '#f59e0b',
    sira        INTEGER NOT NULL DEFAULT 0
);

-- Tenderlər
CREATE TABLE IF NOT EXISTS satinalma.tender (
    tender_id       SERIAL PRIMARY KEY,
    layihe_id       INTEGER NOT NULL REFERENCES layihe.layihe(layihe_id),
    status_id       INTEGER NOT NULL DEFAULT 1 REFERENCES satinalma.tender_status(status_id),
    kod             VARCHAR(30) UNIQUE,
    ad              VARCHAR(255) NOT NULL,
    elan_tarixi     DATE,
    son_tarix       DATE,
    qiymet_serhedi  NUMERIC(14,2) NOT NULL DEFAULT 0,
    qalib_istirakci_id INTEGER,
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tender iştirakçıları
CREATE TABLE IF NOT EXISTS satinalma.tender_istirakci (
    istirakci_id    SERIAL PRIMARY KEY,
    tender_id       INTEGER NOT NULL REFERENCES satinalma.tender(tender_id) ON DELETE CASCADE,
    sirket_ad       VARCHAR(200) NOT NULL,
    voen            VARCHAR(20),
    teklif_mebleg   NUMERIC(14,2) NOT NULL DEFAULT 0,
    teklif_tarixi   DATE,
    qalib           BOOLEAN NOT NULL DEFAULT FALSE,
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Müqavilələr
CREATE TABLE IF NOT EXISTS satinalma.muqavile (
    muqavile_id     SERIAL PRIMARY KEY,
    tender_id       INTEGER REFERENCES satinalma.tender(tender_id),
    layihe_id       INTEGER NOT NULL REFERENCES layihe.layihe(layihe_id),
    nomre           VARCHAR(50) UNIQUE,
    podratci        VARCHAR(200) NOT NULL,
    imzalanma_tarixi DATE,
    bashlama_tarixi DATE,
    son_tarix       DATE,
    mebleg          NUMERIC(14,2) NOT NULL DEFAULT 0,
    qeyd            TEXT,
    aktif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Material tədarükü (müqavilə üzrə)
CREATE TABLE IF NOT EXISTS satinalma.material_tedaruk (
    tedaruk_id      SERIAL PRIMARY KEY,
    muqavile_id     INTEGER NOT NULL REFERENCES satinalma.muqavile(muqavile_id) ON DELETE CASCADE,
    material_novu_id INTEGER NOT NULL REFERENCES ref.material_novu(material_novu_id),
    miqdar          NUMERIC(12,2) NOT NULL DEFAULT 0,
    vahid           VARCHAR(20) NOT NULL DEFAULT 'ədəd',
    qiymet          NUMERIC(12,2) NOT NULL DEFAULT 0,
    çatdırılma_tarixi DATE,
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  maliyye SXEMİ — BÜDCƏ, XƏRC, ÖDƏNİŞ
-- =====================================================================

-- Büdcə maddələri (hierarxik)
CREATE TABLE IF NOT EXISTS maliyye.budce_madde (
    madde_id        SERIAL PRIMARY KEY,
    parent_id       INTEGER REFERENCES maliyye.budce_madde(madde_id),
    ad              VARCHAR(150) NOT NULL,
    kod             VARCHAR(20),
    tip             VARCHAR(10) NOT NULL DEFAULT 'xerc' CHECK (tip IN ('xerc','gelir')),
    aktif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Xərclər
CREATE TABLE IF NOT EXISTS maliyye.xerc (
    xerc_id         SERIAL PRIMARY KEY,
    layihe_id       INTEGER NOT NULL REFERENCES layihe.layihe(layihe_id),
    muqavile_id     INTEGER REFERENCES satinalma.muqavile(muqavile_id),
    madde_id        INTEGER NOT NULL REFERENCES maliyye.budce_madde(madde_id),
    mebleg          NUMERIC(14,2) NOT NULL CHECK (mebleg >= 0),
    tarix           DATE NOT NULL DEFAULT CURRENT_DATE,
    tesvir          TEXT,
    sened_nomresi   VARCHAR(50),
    created_by      INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ödənişlər (müqavilə üzrə)
CREATE TABLE IF NOT EXISTS maliyye.odenis (
    odenis_id       SERIAL PRIMARY KEY,
    muqavile_id     INTEGER NOT NULL REFERENCES satinalma.muqavile(muqavile_id),
    mebleg          NUMERIC(14,2) NOT NULL CHECK (mebleg >= 0),
    tarix           DATE NOT NULL DEFAULT CURRENT_DATE,
    odenis_novu     VARCHAR(30) DEFAULT 'bank' CHECK (odenis_novu IN ('bank','nağd','hesab')),
    qeyd            TEXT,
    sened_nomresi   VARCHAR(50),
    created_by      INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  kadr SXEMİ — VƏZİFƏ, İŞÇİ, TƏYİNAT
-- =====================================================================

-- Vəzifələr
CREATE TABLE IF NOT EXISTS kadr.vezife (
    vezife_id       SERIAL PRIMARY KEY,
    ad              VARCHAR(100) NOT NULL UNIQUE,
    maas_alt        NUMERIC(10,2) NOT NULL DEFAULT 0,
    maas_ust        NUMERIC(10,2) NOT NULL DEFAULT 0,
    qeyd            TEXT,
    aktif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- İşçilər
CREATE TABLE IF NOT EXISTS kadr.isci (
    isci_id         SERIAL PRIMARY KEY,
    vezife_id       INTEGER NOT NULL REFERENCES kadr.vezife(vezife_id),
    ad_soyad        VARCHAR(150) NOT NULL,
    fin             VARCHAR(7) UNIQUE,
    seriya_no       VARCHAR(20),
    dogum_tarixi    DATE,
    telefon         VARCHAR(50),
    email           VARCHAR(100),
    maas            NUMERIC(10,2) NOT NULL DEFAULT 0,
    ise_bashlama    DATE,
    isden_ayrilma   DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'aktiv' CHECK (status IN ('aktiv','passiv')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- İşçi təyinatları (layihə üzrə)
CREATE TABLE IF NOT EXISTS kadr.layihe_isci_teyinat (
    teyinat_id      SERIAL PRIMARY KEY,
    layihe_id       INTEGER NOT NULL REFERENCES layihe.layihe(layihe_id),
    isci_id         INTEGER NOT NULL REFERENCES kadr.isci(isci_id),
    vezife_id       INTEGER REFERENCES kadr.vezife(vezife_id),
    gunelik_mebleg  NUMERIC(10,2) NOT NULL DEFAULT 0,
    bashlama_tarixi DATE,
    son_tarix       DATE,
    UNIQUE (layihe_id, isci_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  hesabat SXEMİ — ANALİTİK VIEW-LƏR
-- =====================================================================

-- Layihə üzrə plan-fakt (büdcə vs xərc)
CREATE OR REPLACE VIEW hesabat.layihe_budce_fakt AS
SELECT
    l.layihe_id,
    l.kod,
    l.ad AS layihe_adi,
    l.plan_budce,
    COALESCE(SUM(x.mebleg), 0) AS fakt_xerc,
    l.plan_budce - COALESCE(SUM(x.mebleg), 0) AS qaliq,
    CASE WHEN l.plan_budce > 0
         THEN ROUND(100.0 * COALESCE(SUM(x.mebleg), 0) / l.plan_budce, 2)
         ELSE 0 END AS faiz
FROM layihe.layihe l
LEFT JOIN maliyye.xerc x ON x.layihe_id = l.layihe_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id
ORDER BY l.layihe_id;

-- Müqavilə ödəniş vəziyyəti
CREATE OR REPLACE VIEW hesabat.muqavile_odenis_veziyyeti AS
SELECT
    m.muqavile_id,
    m.nomre,
    m.podratci,
    m.mebleg AS muqavile_mebleg,
    COALESCE(SUM(o.mebleg), 0) AS odenen,
    m.mebleg - COALESCE(SUM(o.mebleg), 0) AS qaliq_borc,
    CASE WHEN m.mebleg > 0
         THEN ROUND(100.0 * COALESCE(SUM(o.mebleg), 0) / m.mebleg, 2)
         ELSE 0 END AS odenis_faizi
FROM satinalma.muqavile m
LEFT JOIN maliyye.odenis o ON o.muqavile_id = m.muqavile_id
WHERE m.aktif = TRUE
GROUP BY m.muqavile_id
ORDER BY m.muqavile_id;

COMMIT;
