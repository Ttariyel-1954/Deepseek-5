-- =====================================================================
--  DeepSeek-4 ERP v5 — Əlavə Analitik View-lər (10 yeni)
--  Tarix: 2026-08-25
-- =====================================================================

BEGIN;

-- Layihənin tam icmalı (bütün göstəricilər bir yerdə)
CREATE OR REPLACE VIEW hesabat.layihe_tam_icmal AS
SELECT
    l.layihe_id, l.kod, l.ad AS layihe_adi,
    mue.ad AS muessise, st.ad AS status, seh.ad AS seher,
    l.plan_budce,
    COALESCE(x.fakt_xerc, 0) AS fakt_xerc,
    l.plan_budce - COALESCE(x.fakt_xerc, 0) AS qaliq,
    l.progres,
    (SELECT COUNT(*) FROM risk.risk r WHERE r.layihe_id = l.layihe_id) AS risk_sayi,
    (SELECT COUNT(*) FROM keyfiyyet.qusur q
     JOIN keyfiyyet.yoxlama y ON y.yoxlama_id = q.yoxlama_id
     WHERE y.layihe_id = l.layihe_id AND q.status != 'baglanib') AS aciq_qusur,
    (SELECT COUNT(DISTINCT t.isci_id) FROM kadr.layihe_isci_teyinat t
     WHERE t.layihe_id = l.layihe_id) AS isci_sayi,
    l.bashlama_tarixi, l.son_tarix
FROM layihe.layihe l
JOIN ref.muessise mue ON mue.muessise_id = l.muessise_id
JOIN layihe.layihe_status st ON st.status_id = l.status_id
LEFT JOIN ref.seher seh ON seh.seher_id = l.seher_id
LEFT JOIN (SELECT layihe_id, SUM(mebleg) AS fakt_xerc FROM maliyye.xerc GROUP BY layihe_id) x
       ON x.layihe_id = l.layihe_id
WHERE l.silinib = FALSE;

-- AI fəaliyyət icmalı
CREATE OR REPLACE VIEW hesabat.ai_faaliyyet AS
SELECT
    a.ad AS agent, a.vezife,
    COUNT(t.teyinat_id) AS tapşiriq_sayi,
    COUNT(t.teyinat_id) FILTER (WHERE t.status = 'hazir') AS hazir_sayi,
    COUNT(t.teyinat_id) FILTER (WHERE t.status = 'xesver') AS xesver_sayi,
    COUNT(t.teyinat_id) FILTER (WHERE t.tesdiq_status = 'tesdiqlendi') AS tesdiq_sayi,
    ROUND(AVG(t.netice_qiymeti), 2) AS orta_netice
FROM ai.ai_agent a
LEFT JOIN ai.ai_teyinat t ON t.agent_id = a.agent_id
GROUP BY a.agent_id, a.ad, a.vezife
ORDER BY a.ad;

-- Layihə risk icmalı
CREATE OR REPLACE VIEW hesabat.layihe_risk_icmali AS
SELECT
    l.kod, l.ad AS layihe,
    COUNT(r.risk_id) AS risk_sayi,
    COALESCE(SUM(CASE WHEN r.derece >= 60 THEN 1 ELSE 0 END), 0) AS yuksek_risk,
    COALESCE(ROUND(AVG(r.derece), 1), 0) AS orta_derece,
    COUNT(r.risk_id) FILTER (WHERE r.status = 'aciq' OR r.status = 'aktiv') AS aktiv_risk
FROM layihe.layihe l
LEFT JOIN risk.risk r ON r.layihe_id = l.layihe_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id
ORDER BY orta_derece DESC;

-- Anbar qalıqları (hər material üçün son balans)
CREATE OR REPLACE VIEW hesabat.anbar_qaliqlari AS
SELECT
    a.ad AS anbar,
    mn.ad AS material,
    mn.vahid,
    COALESCE(SUM(CASE WHEN mh.hereket_novu = 'daxil' THEN mh.miqdar
                      WHEN mh.hereket_novu = 'cixar' THEN -mh.miqdar
                      ELSE 0 END), 0) AS qaliq
FROM logistika.anbar a
CROSS JOIN ref.material_novu mn
LEFT JOIN logistika.material_hereket mh
       ON mh.anbar_id = a.anbar_id AND mh.material_novu_id = mn.material_novu_id
GROUP BY a.anbar_id, a.ad, mn.material_novu_id, mn.ad, mn.vahid
HAVING COALESCE(SUM(CASE WHEN mh.hereket_novu = 'daxil' THEN mh.miqdar
                         WHEN mh.hereket_novu = 'cixar' THEN -mh.miqdar ELSE 0 END), 0) != 0
ORDER BY a.ad, mn.ad;

-- Material hərəkət icmalı
CREATE OR REPLACE VIEW hesabat.material_hereket_icmali AS
SELECT
    mn.ad AS material, mn.vahid,
    mh.hereket_novu,
    COUNT(mh.hereket_id) AS hereket_sayi,
    SUM(mh.miqdar) AS toplam_miqdar,
    MAX(mh.tarix) AS son_tarix
FROM logistika.material_hereket mh
JOIN ref.material_novu mn ON mn.material_novu_id = mh.material_novu_id
GROUP BY mn.material_novu_id, mn.ad, mn.vahid, mh.hereket_novu
ORDER BY mn.ad, mh.hereket_novu;

-- Keyfiyyət icmalı (yoxlamalar + açıq qüsurlar)
CREATE OR REPLACE VIEW hesabat.keyfiyyet_icmali AS
SELECT
    l.kod, l.ad AS layihe,
    COUNT(DISTINCT y.yoxlama_id) AS yoxlama_sayi,
    COUNT(DISTINCT y.yoxlama_id) FILTER (WHERE y.netice = 'kecdi') AS kecdi_sayi,
    COUNT(DISTINCT y.yoxlama_id) FILTER (WHERE y.netice = 'qeyri_kafi') AS qeyri_kafi_sayi,
    COUNT(q.qusur_id) AS qusur_sayi,
    COUNT(q.qusur_id) FILTER (WHERE q.status != 'baglanib') AS aciq_qusur
FROM layihe.layihe l
LEFT JOIN keyfiyyet.yoxlama y ON y.layihe_id = l.layihe_id
LEFT JOIN keyfiyyet.qusur q ON q.yoxlama_id = y.yoxlama_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id
ORDER BY aciq_qusur DESC NULLS LAST;

-- Büdcə maddələri üzrə xərclər
CREATE OR REPLACE VIEW hesabat.xerc_budce_madde AS
SELECT
    bm.ad AS madde, bm.kod,
    COUNT(x.xerc_id) AS xerc_sayi,
    SUM(x.mebleg) AS toplam_xerc,
    ROUND(AVG(x.mebleg), 2) AS orta_xerc
FROM maliyye.budce_madde bm
LEFT JOIN maliyye.xerc x ON x.madde_id = bm.madde_id
WHERE bm.tip = 'xerc'
GROUP BY bm.madde_id, bm.ad, bm.kod
ORDER BY toplam_xerc DESC NULLS LAST;

-- Aylıq ödəniş vs xərc
CREATE OR REPLACE VIEW hesabat.ayliq_odenis_xerc AS
SELECT
    TO_CHAR(tarix, 'YYYY-MM') AS ay,
    SUM(mebleg) AS xerc_mebleg
FROM maliyye.xerc
GROUP BY 1
UNION ALL
SELECT
    TO_CHAR(tarix, 'YYYY-MM') AS ay,
    -SUM(mebleg) AS xerc_mebleg
FROM maliyye.odenis
GROUP BY 1;

-- Tender effektivliyi (ay üzrə qənaət)
CREATE OR REPLACE VIEW hesabat.tender_effektivlik AS
SELECT
    TO_CHAR(t.elan_tarixi, 'YYYY-MM') AS ay,
    COUNT(t.tender_id) AS tender_sayi,
    COALESCE(SUM(t.qiymet_serhedi - ti.teklif_mebleg), 0) AS toplam_qenayet,
    ROUND(COALESCE(AVG(
        100.0 * (t.qiymet_serhedi - ti.teklif_mebleg) / NULLIF(t.qiymet_serhedi, 0)
    ), 0), 2) AS orta_qenayet_faizi
FROM satinalma.tender t
LEFT JOIN satinalma.tender_istirakci ti ON ti.tender_id = t.tender_id AND ti.qalib = TRUE
WHERE t.elan_tarixi IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- İşçi əmək təhlükəsizliyi icmalı
CREATE OR REPLACE VIEW hesabat.isci_tehlike AS
SELECT
    i.ad_soyad, i.fin,
    v.ad AS vezife,
    (SELECT COUNT(*) FROM tehlike.telim tl WHERE tl.isci_id = i.isci_id) AS telim_sayi,
    (SELECT COUNT(*) FROM tehlike.olay o WHERE o.tesevver_eden = i.isci_id) AS olay_sayi,
    CASE WHEN (SELECT COUNT(*) FROM tehlike.telim tl
               WHERE tl.isci_id = i.isci_id AND tl.etibarliliq_sonu < CURRENT_DATE) > 0
         THEN 'Muddəti bitib' ELSE 'Ok' END AS sertifikat_status
FROM kadr.isci i
JOIN kadr.vezife v ON v.vezife_id = i.vezife_id
WHERE i.status = 'aktiv'
ORDER BY i.ad_soyad;

-- Sənəd status icmalı
CREATE OR REPLACE VIEW hesabat.sened_status_icmali AS
SELECT
    sn.ad AS sened_novu,
    COUNT(s.sened_id) AS sened_sayi,
    COUNT(s.sened_id) FILTER (WHERE s.status = 'tesdiqlendi') AS tesdiq_sayi,
    COUNT(s.sened_id) FILTER (WHERE s.status = 'qaralama') AS qaralama_sayi,
    COUNT(s.sened_id) FILTER (WHERE s.status = 'tesdiqde') AS tesdiqde_sayi
FROM sened.sened_novu sn
LEFT JOIN sened.sened s ON s.sened_novu_id = sn.sened_novu_id
GROUP BY sn.sened_novu_id, sn.ad
ORDER BY sened_sayi DESC;

COMMIT;
