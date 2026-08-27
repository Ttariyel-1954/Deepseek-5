-- =====================================================================
--  DeepSeek-4 ERP v5 — Yeni Sxemlər və Cədvəllər (7 sxem, 26 cədvəl)
--  Yeni sxemlər: ai, sened, risk, keyfiyyet, logistika, tehlike, audit
--  Mövcud 6 sxem / 22 cədvəl + bu 7 sxem / 26 cədvəl = 13 sxem / 48 cədvəl
--  Tarix: 2026-08-25
-- =====================================================================

BEGIN;

-- =====================================================================
--  ai SXEMİ — SÜNİ İNTELLEKT İDARƏETMƏ QATI
--  ERP-nin fəaliyyətinin AI tərəfindən tam idarə olunması üçün əsas
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS ai;

-- AI model konfiqurasiyaları
CREATE TABLE IF NOT EXISTS ai.ai_model (
    model_id            SERIAL PRIMARY KEY,
    ad                  VARCHAR(100) NOT NULL,
    provider            VARCHAR(50) NOT NULL,          -- 'deepseek','openai','anthropic','lokal'
    model_ref           VARCHAR(100) NOT NULL,         -- 'deepseek-chat','gpt-4o',...
    rolu                VARCHAR(50) DEFAULT 'assistent', -- 'planlayici','analitik','nezaretci','cavablandiran'
    max_tokens          INTEGER DEFAULT 4096,
    temperature         NUMERIC(3,2) DEFAULT 0.3,
    qiymet_1000_input   NUMERIC(8,4) DEFAULT 0,        -- $ / 1k giriş tokeni
    qiymet_1000_output  NUMERIC(8,4) DEFAULT 0,
    aktif               BOOLEAN DEFAULT TRUE,
    qeyd                TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI agentləri (her biri müəyyən funksiya üzrə ixtisaslaşıb)
CREATE TABLE IF NOT EXISTS ai.ai_agent (
    agent_id    SERIAL PRIMARY KEY,
    model_id    INTEGER REFERENCES ai.ai_model(model_id),
    ad          VARCHAR(100) NOT NULL,
    vezife      VARCHAR(60) NOT NULL,   -- 'planlayici','tender_analitiki','risk_nezaretcisi',...
    tesvir      TEXT,
    status      VARCHAR(20) DEFAULT 'aktiv' CHECK (status IN ('aktiv','passiv','xaric')),
    aktif       BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI tapşırıqları (agentlərə verilən vəzifələr)
CREATE TABLE IF NOT EXISTS ai.ai_teyinat (
    teyinat_id      SERIAL PRIMARY KEY,
    agent_id        INTEGER REFERENCES ai.ai_agent(agent_id),
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    teyinat_novu    VARCHAR(60) NOT NULL, -- 'budce_prognozu','tender_qiymetlendirme','risk_analizi',...
    giris_json      JSONB,               -- giriş məlumatları
    cixis_json      JSONB,               -- nəticə
    prompt          TEXT,
    status          VARCHAR(20) DEFAULT 'golecek' CHECK (status IN ('golecek','islemede','hazir','xesver')),
    ustunluk        INTEGER DEFAULT 5,
    netice_qiymeti  NUMERIC(5,2),        -- nəticə qiymətləndirməsi 0-100
    tesdiq_status   VARCHAR(20) DEFAULT 'golecek' CHECK (tesdiq_status IN ('golecek','tesdiqlendi','redd_edildi')),
    yaradan         INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tamamlanma_tarixi TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI qərarları (avtomatik qəbul edilən və ya tövsiyə edilən qərarlar)
CREATE TABLE IF NOT EXISTS ai.ai_qerar (
    qerar_id        SERIAL PRIMARY KEY,
    teyinat_id      INTEGER REFERENCES ai.ai_teyinat(teyinat_id),
    qerar_novu      VARCHAR(60) NOT NULL,
    mezmun          JSONB,               -- qərarın məzmunu
    esaslandirma    TEXT,                -- əsaslandırma
    eminlik         NUMERIC(5,2),        -- etimad faizi
    tesdiq_eden     INTEGER,             -- insan tərəfindən təsdiq (auth.users)
    tesdiq_tarixi   TIMESTAMPTZ,
    status          VARCHAR(20) DEFAULT 'teklif' CHECK (status IN ('teklif','tesdiqlendi','redd_edildi','icra_olunur','icra_olundu')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI proqnozları (xərc, müddət, material, risk proqnozları)
CREATE TABLE IF NOT EXISTS ai.ai_prognoz (
    prognoz_id      SERIAL PRIMARY KEY,
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    prognoz_novu    VARCHAR(60) NOT NULL, -- 'xerc_asirliq','muddet_gecikmesi','material_qitligi','budce_sapmasi'
    prognoz_deyer   NUMERIC(14,2),
    real_deyer      NUMERIC(14,2),        -- reallaşdıqdan sonra
    ehtimal         NUMERIC(5,2),         -- ehtimal faizi
    tarix           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    doqruluk        NUMERIC(5,2),         -- proqnoz dəqiqliyi %
    qeyd            TEXT
);

-- AI mesajları (AI-nın insanlara göndərdiyi xəbərdarlıq/məlumatlar)
CREATE TABLE IF NOT EXISTS ai.ai_mesaj (
    mesaj_id    SERIAL PRIMARY KEY,
    agent_id    INTEGER REFERENCES ai.ai_agent(agent_id),
    layihe_id   INTEGER REFERENCES layihe.layihe(layihe_id),
    alici_id    INTEGER,                  -- auth.users
    movzu       VARCHAR(150),
    mezmun      TEXT,
    onem        VARCHAR(20) DEFAULT 'normal' CHECK (onem IN ('asagi','normal','yuksek','kritik')),
    oxunub      BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI icra loqları (token/xərc izləmə)
CREATE TABLE IF NOT EXISTS ai.ai_log (
    log_id          SERIAL PRIMARY KEY,
    teyinat_id      INTEGER REFERENCES ai.ai_teyinat(teyinat_id),
    agent_id        INTEGER REFERENCES ai.ai_agent(agent_id),
    hadise          VARCHAR(50),          -- 'basladi','bitdi','xesver','tekrar'
    mesaj           TEXT,
    serf_olunan_tokens INTEGER,
    serf_olunan_xerc NUMERIC(10,4),       -- AZN
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  sened SXEMİ — SƏNƏD İDARƏETMƏSİ
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS sened;

CREATE TABLE IF NOT EXISTS sened.sened_novu (
    sened_novu_id   SERIAL PRIMARY KEY,
    ad              VARCHAR(100) NOT NULL UNIQUE,
    kod             VARCHAR(30) UNIQUE,   -- 'smeta','akt','muqavile','hesabat','mektub','tender'
    mucebri         BOOLEAN DEFAULT FALSE,
    aktif           BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sened.sened (
    sened_id        SERIAL PRIMARY KEY,
    sened_novu_id   INTEGER REFERENCES sened.sened_novu(sened_novu_id),
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    muqavile_id     INTEGER REFERENCES satinalma.muqavile(muqavile_id),
    ad              VARCHAR(255) NOT NULL,
    nomre           VARCHAR(50),
    fayl_yolu       TEXT,
    tarix           DATE DEFAULT CURRENT_DATE,
    status          VARCHAR(20) DEFAULT 'qaralama' CHECK (status IN ('qaralama','tesdiqde','tesdiqlendi','legv')),
    versiya         INTEGER NOT NULL DEFAULT 1,
    yaradan         INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sened.sened_versiya (
    versiya_id          SERIAL PRIMARY KEY,
    sened_id            INTEGER REFERENCES sened.sened(sened_id) ON DELETE CASCADE,
    versiya_nomresi     INTEGER NOT NULL,
    fayl_yolu           TEXT,
    deyisiklik_qeydi    TEXT,
    deyisen             INTEGER,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (sened_id, versiya_nomresi)
);

CREATE TABLE IF NOT EXISTS sened.tesdiq (
    tesdiq_id       SERIAL PRIMARY KEY,
    sened_id        INTEGER REFERENCES sened.sened(sened_id) ON DELETE CASCADE,
    tesdiq_eden     INTEGER,             -- auth.users
    vezife          VARCHAR(100),
    status          VARCHAR(20) DEFAULT 'golecek' CHECK (status IN ('golecek','tesdiqlendi','redd_edildi')),
    rey             TEXT,
    tesdiq_tarixi   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  risk SXEMİ — RİSK İDARƏETMƏSİ
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS risk;

CREATE TABLE IF NOT EXISTS risk.risk (
    risk_id         SERIAL PRIMARY KEY,
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    risk_novu       VARCHAR(50) NOT NULL, -- 'maliyye','texniki','tedaruk','kadr','tehlike','hava','huquqi'
    tesvir          TEXT NOT NULL,
    ehtimal         NUMERIC(5,2) DEFAULT 50,   -- ehtimal %
    tesir           NUMERIC(5,2) DEFAULT 50,   -- təsir dərəcəsi (1-100)
    derece          NUMERIC(5,2) GENERATED ALWAYS AS (ehtimal * tesir / 100) STORED,
    sahibi          INTEGER,
    mitedaxile_plani TEXT,
    status          VARCHAR(20) DEFAULT 'aktiv' CHECK (status IN ('aktiv','nezaretde','qapanib')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS risk.risk_mitedaxile (
    mitedaxile_id   SERIAL PRIMARY KEY,
    risk_id         INTEGER REFERENCES risk.risk(risk_id) ON DELETE CASCADE,
    tesvir          TEXT NOT NULL,
    mezul_isci      INTEGER REFERENCES kadr.isci(isci_id),
    plan_tarix      DATE,
    real_tarix      DATE,
    effektiv        NUMERIC(5,2),        -- effektivlik %
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  keyfiyyet SXEMİ — KEYFİYYƏTƏ NƏZARƏT
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS keyfiyyet;

CREATE TABLE IF NOT EXISTS keyfiyyet.yoxlama (
    yoxlama_id      SERIAL PRIMARY KEY,
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    merhele_id      INTEGER REFERENCES layihe.layihe_merhele(merhele_id),
    yoxlama_novu    VARCHAR(50) NOT NULL, -- 'texniki','keyfiyyet','tehlike','ekoloji'
    yoxlayan        INTEGER REFERENCES kadr.isci(isci_id),
    tarix           DATE DEFAULT CURRENT_DATE,
    netice          VARCHAR(20) DEFAULT 'golecek' CHECK (netice IN ('golecek','kecdi','qeyri_kafi','yeniden_yoxlama')),
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS keyfiyyet.qusur (
    qusur_id            SERIAL PRIMARY KEY,
    yoxlama_id          INTEGER REFERENCES keyfiyyet.yoxlama(yoxlama_id) ON DELETE CASCADE,
    tesvir              TEXT NOT NULL,
    ciddilik            VARCHAR(20) DEFAULT 'orta' CHECK (ciddilik IN ('asagi','orta','yuksek','kritik')),
    status              VARCHAR(20) DEFAULT 'aciq' CHECK (status IN ('aciq','duzelisde','baglanib')),
    duzelis_plan_tarix  DATE,
    duzelis_real_tarix  DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS keyfiyyet.qebul_akt (
    akt_id          SERIAL PRIMARY KEY,
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    merhele_id      INTEGER REFERENCES layihe.layihe_merhele(merhele_id),
    nomre           VARCHAR(50),
    tarix           DATE DEFAULT CURRENT_DATE,
    status          VARCHAR(20) DEFAULT 'qaralama' CHECK (status IN ('qaralama','tesdiqde','tesdiqlendi','redd_edildi')),
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  logistika SXEMİ — MATERIAL LOGİSTİKASI VƏ ANBAR
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS logistika;

CREATE TABLE IF NOT EXISTS logistika.anbar (
    anbar_id        SERIAL PRIMARY KEY,
    ad              VARCHAR(100) NOT NULL,
    seher_id        INTEGER REFERENCES ref.seher(seher_id),
    unvan           VARCHAR(200),
    mesul_isci      INTEGER REFERENCES kadr.isci(isci_id),
    aktif           BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS logistika.tedarukcu (
    tedarukcu_id    SERIAL PRIMARY KEY,
    ad              VARCHAR(200) NOT NULL,
    voen            VARCHAR(20) UNIQUE,
    elaqe_shexs     VARCHAR(100),
    telefon         VARCHAR(50),
    email           VARCHAR(100),
    unvan           VARCHAR(200),
    reyting         NUMERIC(3,2) DEFAULT 0,   -- təchizatçı reytinqi 0-5
    aktif           BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS logistika.material_hereket (
    hereket_id      SERIAL PRIMARY KEY,
    anbar_id        INTEGER REFERENCES logistika.anbar(anbar_id),
    material_novu_id INTEGER REFERENCES ref.material_novu(material_novu_id),
    hereket_novu    VARCHAR(20) NOT NULL CHECK (hereket_novu IN ('daxil','cixar','transfer')),
    miqdar          NUMERIC(12,2) NOT NULL,
    vahid           VARCHAR(20) NOT NULL,
    tarix           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sened_id        INTEGER REFERENCES sened.sened(sened_id),
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    icraci          INTEGER,
    qeyd            TEXT
);

CREATE TABLE IF NOT EXISTS logistika.catdirilma (
    catdirilma_id   SERIAL PRIMARY KEY,
    tedarukcu_id    INTEGER REFERENCES logistika.tedarukcu(tedarukcu_id),
    material_novu_id INTEGER REFERENCES ref.material_novu(material_novu_id),
    miqdar          NUMERIC(12,2) NOT NULL,
    vahid           VARCHAR(20) NOT NULL,
    qiymet          NUMERIC(12,2),
    plan_tarix      DATE,
    real_tarix      DATE,
    status          VARCHAR(20) DEFAULT 'planlasdirilib' CHECK (status IN ('planlasdirilib','yolda','catdirildi','geqikdi','legv')),
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  tehlike SXEMİ — ƏMƏK TƏHLÜKƏSİZLİYİ
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS tehlike;

CREATE TABLE IF NOT EXISTS tehlike.olay (
    olay_id         SERIAL PRIMARY KEY,
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    olay_novu       VARCHAR(50) NOT NULL, -- 'xsst_insident','yangin','zedelenme','ekoloji'
    tarix           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ciddilik        VARCHAR(20) DEFAULT 'orta' CHECK (ciddilik IN ('asagi','orta','yuksek','kritik')),
    tesvir          TEXT NOT NULL,
    tesevver_eden   INTEGER REFERENCES kadr.isci(isci_id),
    status          VARCHAR(20) DEFAULT 'aciq' CHECK (status IN ('aciq','arashdirilir','baglanib')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tehlike.yoxlama (
    yoxlama_id      SERIAL PRIMARY KEY,
    layihe_id       INTEGER REFERENCES layihe.layihe(layihe_id),
    tarix           DATE DEFAULT CURRENT_DATE,
    netice          VARCHAR(20) DEFAULT 'golecek' CHECK (netice IN ('golecek','kecdi','qeyri_kafi')),
    tapinti         TEXT,
    yoxlayan        INTEGER REFERENCES kadr.isci(isci_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tehlike.telim (
    telim_id        SERIAL PRIMARY KEY,
    isci_id         INTEGER REFERENCES kadr.isci(isci_id),
    movzu           VARCHAR(200) NOT NULL,
    tarix           DATE,
    sertifikat      VARCHAR(50),
    etibarliliq_sonu DATE,
    kechdi          BOOLEAN DEFAULT TRUE,
    qeyd            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
--  audit SXEMİ — AUDİT VƏ SİSTEM QEYDLƏRİ
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.audit_log (
    audit_id        SERIAL PRIMARY KEY,
    sxem            VARCHAR(50) NOT NULL,
    cedvel          VARCHAR(50) NOT NULL,
    qeyd_id         INTEGER,
    emeliyyat       VARCHAR(10) NOT NULL CHECK (emeliyyat IN ('INSERT','UPDATE','DELETE')),
    kohne_deyer     JSONB,
    yeni_deyer      JSONB,
    istifadeci_id   INTEGER,
    ip              VARCHAR(45),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit.sistem_log (
    log_id          SERIAL PRIMARY KEY,
    seviyye         VARCHAR(10) NOT NULL DEFAULT 'info' CHECK (seviyye IN ('debug','info','warn','error','fatal')),
    menbe           VARCHAR(100),
    mesaj           TEXT NOT NULL,
    kontekst        JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit.giris_log (
    giris_id        SERIAL PRIMARY KEY,
    istifadeci_id   INTEGER,
    istifadeci_ad   VARCHAR(50),
    ip              VARCHAR(45),
    success         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;
