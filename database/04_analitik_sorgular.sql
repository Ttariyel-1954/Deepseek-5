-- =====================================================================
--  DeepSeek-4 ERP v5 — Əlavə Analitik Sorğular (yeni sxemlər üçün)
--  ai, sened, risk, keyfiyyet, logistika, tehlike, audit sxemləri
--  Tarix: 2026-08-25
-- =====================================================================

-- ---------------------------------------------------------------------
--  AI-1. Agentlər üzrə tapşırıq yükü və effektivlik
-- ---------------------------------------------------------------------
SELECT
    ag.ad AS agent, ag.vezife,
    COUNT(t.teyinat_id) AS tapşiriq,
    COUNT(t.teyinat_id) FILTER (WHERE t.status = 'hazir') AS hazir,
    COUNT(t.teyinat_id) FILTER (WHERE t.status = 'xesver') AS xesver,
    ROUND(AVG(t.netice_qiymeti), 1) AS orta_qiymet,
    ROUND(AVG(t.eminlik), 1) AS orta_eminlik
FROM ai.ai_agent ag
LEFT JOIN ai.ai_teyinat t ON t.agent_id = ag.agent_id
LEFT JOIN ai.ai_qerar q ON q.teyinat_id = t.teyinat_id
GROUP BY ag.agent_id
ORDER BY tapşiriq DESC;

-- ---------------------------------------------------------------------
--  AI-2. AI xərclərinin izlənməsi (token/məbləğ)
-- ---------------------------------------------------------------------
SELECT
    ag.ad AS agent,
    COUNT(l.log_id) AS log_sayi,
    COALESCE(SUM(l.serf_olunan_tokens), 0) AS tokens,
    COALESCE(SUM(l.serf_olunan_xerc), 0) AS xerc_azn
FROM ai.ai_agent ag
LEFT JOIN ai.ai_log l ON l.agent_id = ag.agent_id
GROUP BY ag.agent_id
ORDER BY xerc_azn DESC;

-- ---------------------------------------------------------------------
--  AI-3. Proqnozların dəqiqliyi (proqnoz vs real)
-- ---------------------------------------------------------------------
SELECT
    l.kod, l.ad AS layihe,
    p.prognoz_novu,
    p.prognoz_deyer, p.real_deyer,
    ROUND(100.0 * (1 - ABS(p.prognoz_deyer - COALESCE(p.real_deyer, p.prognoz_deyer)) / NULLIF(p.prognoz_deyer, 0)), 2) AS doqruluk
FROM ai.ai_prognoz p
JOIN layihe.layihe l ON l.layihe_id = p.layihe_id
ORDER BY p.prognoz_id;

-- ---------------------------------------------------------------------
--  RISK-1. Layihələr üzrə risk profili
-- ---------------------------------------------------------------------
SELECT
    l.kod, l.ad AS layihe,
    COUNT(r.risk_id) AS risk_sayi,
    MAX(r.derece) AS maks_derece,
    ROUND(AVG(r.derece), 1) AS orta_derece,
    SUM(CASE WHEN r.derece >= 60 THEN 1 ELSE 0 END) AS kritik_risk
FROM layihe.layihe l
LEFT JOIN risk.risk r ON r.layihe_id = l.layihe_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id
ORDER BY kritik_risk DESC NULLS LAST;

-- ---------------------------------------------------------------------
--  RISK-2. Risk növləri üzrə paylanma
-- ---------------------------------------------------------------------
SELECT
    risk_novu,
    COUNT(*) AS sayi,
    ROUND(AVG(derece), 1) AS orta_derece,
    COUNT(*) FILTER (WHERE status = 'aciq') AS aciq_sayi
FROM risk.risk
GROUP BY risk_novu
ORDER BY sayi DESC;

-- ---------------------------------------------------------------------
--  KEYFİYYƏT-1. Yoxlama nəticələri üzrə keçid faizi
-- ---------------------------------------------------------------------
SELECT
    l.kod,
    COUNT(y.yoxlama_id) AS yoxlama,
    COUNT(y.yoxlama_id) FILTER (WHERE y.netice = 'kecdi') AS kecdi,
    COUNT(y.yoxlama_id) FILTER (WHERE y.netice = 'qeyri_kafi') AS qeyri_kafi,
    ROUND(100.0 * COUNT(y.yoxlama_id) FILTER (WHERE y.netice = 'kecdi') / NULLIF(COUNT(y.yoxlama_id), 0), 1) AS kecme_faizi
FROM keyfiyyet.yoxlama y
JOIN layihe.layihe l ON l.layihe_id = y.layihe_id
GROUP BY l.layihe_id
ORDER BY kecme_faizi;

-- ---------------------------------------------------------------------
--  KEYFİYYƏT-2. Açıq qüsurların ciddilik üzrə sayı
-- ---------------------------------------------------------------------
SELECT
    ciddilik,
    COUNT(*) AS sayi,
    COUNT(*) FILTER (WHERE status = 'aciq') AS aciq_sayi
FROM keyfiyyet.qusur
GROUP BY ciddilik
ORDER BY sayi DESC;

-- ---------------------------------------------------------------------
--  LOGİSTİKA-1. Anbar qalıqları
-- ---------------------------------------------------------------------
SELECT
    a.ad AS anbar,
    mn.ad AS material,
    SUM(CASE WHEN mh.hereket_novu = 'daxil' THEN mh.miqdar
             WHEN mh.hereket_novu = 'cixar' THEN -mh.miqdar ELSE 0 END) AS qaliq,
    mn.vahid
FROM logistika.anbar a
JOIN logistika.material_hereket mh ON mh.anbar_id = a.anbar_id
JOIN ref.material_novu mn ON mn.material_novu_id = mh.material_novu_id
GROUP BY a.anbar_id, a.ad, mn.material_novu_id, mn.ad, mn.vahid
ORDER BY a.ad, mn.ad;

-- ---------------------------------------------------------------------
--  LOGİSTİKA-2. Çatdırılma gecikmələri
-- ---------------------------------------------------------------------
SELECT
    c.catdirilma_id, tc.ad AS tedarukcu, mn.ad AS material,
    c.plan_tarix, c.real_tarix,
    (c.real_tarix - c.plan_tarix) AS gecikme_gunu,
    c.status
FROM logistika.catdirilma c
JOIN logistika.tedarukcu tc ON tc.tedarukcu_id = c.tedarukcu_id
JOIN ref.material_novu mn ON mn.material_novu_id = c.material_novu_id
WHERE c.real_tarix > c.plan_tarix
ORDER BY gecikme_gunu DESC;

-- ---------------------------------------------------------------------
--  LOGİSTİKA-3. Təchizatçı reytinqi vs çatdırılma
-- ---------------------------------------------------------------------
SELECT
    tc.ad AS tedarukcu, tc.reyting,
    COUNT(c.catdirilma_id) AS catdirilma_sayi,
    COUNT(c.catdirilma_id) FILTER (WHERE c.status = 'geqikdi') AS gecikme_sayi
FROM logistika.tedarukcu tc
LEFT JOIN logistika.catdirilma c ON c.tedarukcu_id = tc.tedarukcu_id
GROUP BY tc.tedarukcu_id
ORDER BY tc.reyting DESC;

-- ---------------------------------------------------------------------
--  TƏHLÜKƏ-1. Layihələr üzrə hadisə statistikası
-- ---------------------------------------------------------------------
SELECT
    l.kod,
    COUNT(o.olay_id) AS hadise_sayi,
    COUNT(o.olay_id) FILTER (WHERE o.ciddilik IN ('yuksek','kritik')) AS agir_hadise,
    COUNT(o.olay_id) FILTER (WHERE o.status = 'aciq') AS aciq_hadise
FROM layihe.layihe l
LEFT JOIN tehlike.olay o ON o.layihe_id = l.layihe_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id
ORDER BY hadise_sayi DESC;

-- ---------------------------------------------------------------------
--  TƏHLÜKƏ-2. İşçilərin təlim vəziyyəti
-- ---------------------------------------------------------------------
SELECT
    i.ad_soyad,
    COUNT(tl.telim_id) AS telim_sayi,
    COUNT(tl.telim_id) FILTER (WHERE tl.etibarliliq_sonu < CURRENT_DATE) AS muddeti_biten,
    MAX(tl.etibarliliq_sonu) AS son_etibarliliq
FROM kadr.isci i
LEFT JOIN tehlike.telim tl ON tl.isci_id = i.isci_id
WHERE i.status = 'aktiv'
GROUP BY i.isci_id
ORDER BY muddeti_biten DESC;

-- ---------------------------------------------------------------------
--  SƏNƏD-1. Sənəd növləri üzrə status paylanması
-- ---------------------------------------------------------------------
SELECT
    sn.ad AS sened_novu,
    COUNT(s.sened_id) AS sayi,
    COUNT(s.sened_id) FILTER (WHERE s.status = 'tesdiqlendi') AS tesdiqlendi,
    COUNT(s.sened_id) FILTER (WHERE s.status = 'tesdiqde') AS tesdiqde,
    COUNT(s.sened_id) FILTER (WHERE s.status = 'qaralama') AS qaralama
FROM sened.sened_novu sn
LEFT JOIN sened.sened s ON s.sened_novu_id = sn.sened_novu_id
GROUP BY sn.sened_novu_id, sn.ad
ORDER BY sayi DESC;

-- ---------------------------------------------------------------------
--  AUDİT-1. Ən çox dəyişiklik edilən cədvəllər
-- ---------------------------------------------------------------------
SELECT
    sxem || '.' || cedvel AS cedvel,
    emeliyyat,
    COUNT(*) AS sayi
FROM audit.audit_log
GROUP BY sxem, cedvel, emeliyyat
ORDER BY sayi DESC;

-- ---------------------------------------------------------------------
--  AUDİT-2. Uğursuz giriş cəhdləri
-- ---------------------------------------------------------------------
SELECT
    istifadeci_ad,
    ip,
    COUNT(*) FILTER (WHERE success = FALSE) AS ugursuz,
    COUNT(*) FILTER (WHERE success = TRUE) AS ugurlu
FROM audit.giris_log
GROUP BY istifadeci_ad, ip
ORDER BY ugursuz DESC;
