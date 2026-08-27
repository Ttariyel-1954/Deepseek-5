-- =====================================================================
--  DeepSeek-4 ERP — Test və Analitik Sorğular (10+)
--  Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi
--  Tarix: 2026-08-24
-- =====================================================================

-- ---------------------------------------------------------------------
--  #1. Layihə büdcəsi vs faktiki xərclər (Plan-fakt təhlili)
-- ---------------------------------------------------------------------
SELECT
    l.layihe_id, l.kod, l.ad AS layihe,
    l.plan_budce,
    COALESCE(SUM(x.mebleg), 0) AS fakt_xerc,
    l.plan_budce - COALESCE(SUM(x.mebleg), 0) AS qaliq,
    ROUND(100.0 * COALESCE(SUM(x.mebleg), 0) / NULLIF(l.plan_budce, 0), 2) AS istifade_faizi
FROM layihe.layihe l
LEFT JOIN maliyye.xerc x ON x.layihe_id = l.layihe_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id
ORDER BY l.layihe_id;

-- ---------------------------------------------------------------------
--  #2. Tender qalibləri və qənaət
-- ---------------------------------------------------------------------
SELECT
    t.kod AS tender_kod, t.ad AS tender,
    t.qiymet_serhedi AS elan_mebleg,
    ti.sirket_ad AS qalib_sirket,
    ti.teklif_mebleg,
    t.qiymet_serhedi - ti.teklif_mebleg AS qenayet,
    ROUND(100.0 * (t.qiymet_serhedi - ti.teklif_mebleg) / NULLIF(t.qiymet_serhedi, 0), 2) AS qenayet_faizi
FROM satinalma.tender t
JOIN satinalma.tender_istirakci ti ON ti.tender_id = t.tender_id AND ti.qalib = TRUE
WHERE t.status_id = (SELECT status_id FROM satinalma.tender_status WHERE kod='qalib')
ORDER BY qenayet DESC;

-- ---------------------------------------------------------------------
--  #3. Layihə üzrə işçi sayı və orta maaş (Kadr planlaması)
-- ---------------------------------------------------------------------
SELECT
    l.kod, l.ad AS layihe,
    COUNT(DISTINCT t.isci_id) AS isci_sayi,
    ROUND(AVG(i.maas), 2) AS orta_maas,
    COUNT(DISTINCT t.teyinat_id) AS teyinat_sayi
FROM layihe.layihe l
LEFT JOIN kadr.layihe_isci_teyinat t ON t.layihe_id = l.layihe_id
LEFT JOIN kadr.isci i ON i.isci_id = t.isci_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id
ORDER BY isci_sayi DESC;

-- ---------------------------------------------------------------------
--  #4. Ən çox istifadə olunan materiallar (Təchizat optimallaşdırması)
-- ---------------------------------------------------------------------
SELECT
    mn.ad AS material,
    mn.vahid,
    SUM(lm.miqdar) AS toplam_miqdar,
    SUM(lm.miqdar * lm.qiymet) AS toplam_deyer
FROM layihe.layihe_material lm
JOIN ref.material_novu mn ON mn.material_novu_id = lm.material_novu_id
GROUP BY mn.material_novu_id
ORDER BY toplam_deyer DESC;

-- ---------------------------------------------------------------------
--  #5. Regionlar üzrə layihə statistikası
-- ---------------------------------------------------------------------
SELECT
    r.ad AS region,
    COUNT(l.layihe_id) AS layihe_sayi,
    COALESCE(SUM(l.plan_budce), 0) AS plan_budce,
    COALESCE(SUM(x.mebleg), 0) AS fakt_xerc
FROM ref.region r
LEFT JOIN ref.seher s ON s.region_id = r.region_id
LEFT JOIN layihe.layihe l ON l.seher_id = s.seher_id AND l.silinib = FALSE
LEFT JOIN maliyye.xerc x ON x.layihe_id = l.layihe_id
GROUP BY r.region_id
ORDER BY plan_budce DESC;

-- ---------------------------------------------------------------------
--  #6. Müqavilə ödəniş vəziyyəti (Borc idarəsi)
-- ---------------------------------------------------------------------
SELECT
    m.nomre, m.podratci,
    m.mebleg AS muqavile_mebleg,
    COALESCE(SUM(o.mebleg), 0) AS odenen,
    m.mebleg - COALESCE(SUM(o.mebleg), 0) AS qaliq_borc,
    ROUND(100.0 * COALESCE(SUM(o.mebleg), 0) / NULLIF(m.mebleg, 0), 2) AS odenis_faizi
FROM satinalma.muqavile m
LEFT JOIN maliyye.odenis o ON o.muqavile_id = m.muqavile_id
WHERE m.aktif = TRUE
GROUP BY m.muqavile_id
ORDER BY qaliq_borc DESC;

-- ---------------------------------------------------------------------
--  #7. Təhsil müəssisələri üzrə iş dəyəri (Müştəri təhlili)
-- ---------------------------------------------------------------------
SELECT
    mue.ad AS muessise,
    mue.voen,
    COUNT(l.layihe_id) AS layihe_sayi,
    COALESCE(SUM(l.plan_budce), 0) AS plan_budce,
    COALESCE(SUM(x.mebleg), 0) AS fakt_xerc
FROM ref.muessise mue
LEFT JOIN layihe.layihe l ON l.muessise_id = mue.muessise_id AND l.silinib = FALSE
LEFT JOIN maliyye.xerc x ON x.layihe_id = l.layihe_id
GROUP BY mue.muessise_id
ORDER BY plan_budce DESC;

-- ---------------------------------------------------------------------
--  #8. İş növləri üzrə orta layihə müddəti (Müddət təhlili)
-- ---------------------------------------------------------------------
SELECT
    isn.ad AS is_novu,
    COUNT(l.layihe_id) AS layihe_sayi,
    ROUND(AVG(l.son_tarix - l.bashlama_tarixi), 0) AS orta_gun,
    ROUND(AVG(l.son_tarix - l.bashlama_tarixi) / 30.0, 1) AS orta_ay
FROM ref.is_novu isn
LEFT JOIN layihe.layihe l ON l.is_novu_id = isn.is_novu_id AND l.silinib = FALSE
WHERE l.layihe_id IS NOT NULL
GROUP BY isn.is_novu_id
ORDER BY orta_gun DESC;

-- ---------------------------------------------------------------------
--  #9. Ən yüksək maaş alan işçilər (Kadr xərcləri)
-- ---------------------------------------------------------------------
SELECT
    i.ad_soyad, i.fin,
    v.ad AS vezife,
    i.maas,
    i.status
FROM kadr.isci i
JOIN kadr.vezife v ON v.vezife_id = i.vezife_id
ORDER BY i.maas DESC
LIMIT 10;

-- ---------------------------------------------------------------------
--  #10. Ay üzrə xərclərin dinamikası (Maliyyə trendi)
-- ---------------------------------------------------------------------
SELECT
    TO_CHAR(tarix, 'YYYY-MM') AS ay,
    COUNT(xerc_id) AS xerc_sayi,
    SUM(mebleg) AS xerc_mebleg
FROM maliyye.xerc
GROUP BY TO_CHAR(tarix, 'YYYY-MM')
ORDER BY ay;

-- ---------------------------------------------------------------------
--  ƏLAVƏ: Bütün sxemlərin icmalı
-- ---------------------------------------------------------------------
SELECT schemaname, count(*) AS cedvel_sayi
FROM pg_tables
WHERE schemaname IN ('ref','layihe','satinalma','maliyye','kadr','hesabat')
GROUP BY schemaname
ORDER BY schemaname;
