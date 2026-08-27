-- =====================================================================
--  DeepSeek-5 ERP — AI Nümayiş Sorğuları (~20 sorğu)
--  Məqsəd: AI agentlərinə (Claude/DeepSeek) bazanın bütün aspektlərini
--  nümayiş etdirmək — hər sxem, funksiya, trigger və view.
--  Hər sorğu bir biznes sualına cavab verir.
--  Tarix: 2026-08-25
-- =====================================================================

-- =============================================================
--  ref SXEMİ — İSTİNAD MƏLUMATLARI
-- =============================================================

-- Q1. Regionlar və şəhərlər xəritəsi
SELECT r.ad AS region, s.ad AS seher
FROM ref.region r
LEFT JOIN ref.seher s ON s.region_id = r.region_id
ORDER BY r.ad, s.ad;

-- Q2. Təhsil müəssisələri üzrə məlumat (müştəri bazası)
SELECT m.ad AS muessise, m.voen, s.ad AS seher, n.ad AS novu, m.telefon
FROM ref.muessise m
JOIN ref.seher s ON s.seher_id = m.seher_id
JOIN ref.muessise_novu n ON n.nov_id = m.nov_id
ORDER BY m.ad;

-- Q3. İş növləri (hierarxik quruluş)
SELECT parent.ad AS parent_novu, child.ad AS child_novu, child.kod
FROM ref.is_novu child
LEFT JOIN ref.is_novu parent ON parent.is_novu_id = child.parent_id
ORDER BY parent_novu NULLS FIRST, child_novu;

-- Q4. Material kataloqu (hierarxik)
SELECT parent.ad AS kategoriya, child.ad AS material, child.vahid
FROM ref.material_novu child
LEFT JOIN ref.material_novu parent ON parent.material_novu_id = child.parent_id
ORDER BY kategoriya NULLS FIRST, material;

-- =============================================================
--  layihe SXEMİ — LAYİHƏ İDARƏETMƏSİ
-- =============================================================

-- Q5. Bütün layihələrin tam icmalı (plan-fakt, progress, status)
SELECT l.kod, l.ad AS layihe, st.ad AS status,
       l.plan_budce,
       COALESCE(SUM(x.mebleg), 0) AS fakt_xerc,
       l.plan_budce - COALESCE(SUM(x.mebleg), 0) AS qaliq,
       l.progres || '%' AS progress
FROM layihe.layihe l
JOIN layihe.layihe_status st ON st.status_id = l.status_id
LEFT JOIN maliyye.xerc x ON x.layihe_id = l.layihe_id
WHERE l.silinib = FALSE
GROUP BY l.layihe_id, st.ad
ORDER BY l.layihe_id;

-- Q6. Layihə mərhələləri və real progress
SELECT l.kod, m.ad AS merhele, m.plan_faiz, m.real_faiz,
       m.plan_tarix, m.real_tarix,
       CASE WHEN m.real_tarix > m.plan_tarix THEN 'GEÇİKİB' ELSE 'VAXTINDA' END AS veziyyet
FROM layihe.layihe_merhele m
JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
ORDER BY l.layihe_id, m.merhele_id;

-- Q7. Layihə materialları və qiymətləndirmə
SELECT l.kod, mn.ad AS material, lm.miqdar, lm.vahid, lm.qiymet,
       lm.miqdar * lm.qiymet AS toplam
FROM layihe.layihe_material lm
JOIN layihe.layihe l ON l.layihe_id = lm.layihe_id
JOIN ref.material_novu mn ON mn.material_novu_id = lm.material_novu_id
ORDER BY l.kod, mn.ad;

-- =============================================================
--  satinalma SXEMİ — TENDER, MÜQAVİLƏ, TƏDARÜK
-- =============================================================

-- Q8. Tender qalibləri və qənaət təhlili
SELECT t.kod, t.ad AS tender, st.ad AS status,
       t.qiymet_serhedi, ti.sirket_ad AS qalib,
       ti.teklif_mebleg,
       t.qiymet_serhedi - ti.teklif_mebleg AS qenayet,
       ROUND(100.0 * (t.qiymet_serhedi - ti.teklif_mebleg) / t.qiymet_serhedi, 2) AS qenayet_faizi
FROM satinalma.tender t
JOIN satinalma.tender_status st ON st.status_id = t.status_id
LEFT JOIN satinalma.tender_istirakci ti ON ti.tender_id = t.tender_id AND ti.qalib = TRUE
WHERE t.status_id = (SELECT status_id FROM satinalma.tender_status WHERE kod='qalib')
ORDER BY qenayet DESC;

-- Q9. Müqavilə ödəniş vəziyyəti (borc idarəsi)
SELECT m.nomre, m.podratci, l.kod AS layihe,
       m.mebleg AS muqavile_mebleg,
       COALESCE(SUM(o.mebleg), 0) AS odenen,
       m.mebleg - COALESCE(SUM(o.mebleg), 0) AS qaliq_borc,
       ROUND(100.0 * COALESCE(SUM(o.mebleg), 0) / m.mebleg, 1) AS odenis_faizi
FROM satinalma.muqavile m
JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
LEFT JOIN maliyye.odenis o ON o.muqavile_id = m.muqavile_id
GROUP BY m.muqavile_id, l.kod
ORDER BY qaliq_borc DESC;

-- Q10. Material tədarükü üzrə icmal
SELECT m.nomre, mn.ad AS material, mt.miqdar, mt.vahid, mt.qiymet
FROM satinalma.material_tedaruk mt
JOIN satinalma.muqavile m ON m.muqavile_id = mt.muqavile_id
JOIN ref.material_novu mn ON mn.material_novu_id = mt.material_novu_id
ORDER BY m.nomre;

-- =============================================================
--  maliyye SXEMİ — BÜDCƏ, XƏRC, ÖDƏNİŞ
-- =============================================================

-- Q11. Büdcə maddələri üzrə xərclər
SELECT bm.ad AS madde, bm.kod, COUNT(x.xerc_id) AS xerc_sayi, SUM(x.mebleg) AS toplam
FROM maliyye.budce_madde bm
LEFT JOIN maliyye.xerc x ON x.madde_id = bm.madde_id
WHERE bm.tip = 'xerc'
GROUP BY bm.madde_id
ORDER BY toplam DESC NULLS LAST;

-- Q12. Ay üzrə xərc dinamikası (maliyyə trendi)
SELECT TO_CHAR(tarix, 'YYYY-MM') AS ay, COUNT(*) AS xerc_sayi, SUM(mebleg) AS mebleg
FROM maliyye.xerc
GROUP BY 1 ORDER BY 1;

-- Q13. Ödənişlər üzrə icmal
SELECT o.odenis_id, m.nomre, o.mebleg, o.tarix, o.odenis_novu
FROM maliyye.odenis o
JOIN satinalma.muqavile m ON m.muqavile_id = o.muqavile_id
ORDER BY o.tarix;

-- =============================================================
--  kadr SXEMİ — VƏZİFƏ, İŞÇİ, TƏYİNAT
-- =============================================================

-- Q14. İşçilər və vəzifələri (maaş təhlili)
SELECT i.ad_soyad, i.fin, v.ad AS vezife, i.maas, i.status
FROM kadr.isci i
JOIN kadr.vezife v ON v.vezife_id = i.vezife_id
ORDER BY i.maas DESC;

-- Q15. Layihə üzrə işçi təyinatları (kadr planlaması)
SELECT l.kod, i.ad_soyad, v.ad AS vezife, t.gunelik_mebleg,
       t.bashlama_tarixi, t.son_tarix
FROM kadr.layihe_isci_teyinat t
JOIN layihe.layihe l ON l.layihe_id = t.layihe_id
JOIN kadr.isci i ON i.isci_id = t.isci_id
JOIN kadr.vezife v ON v.vezife_id = COALESCE(t.vezife_id, i.vezife_id)
ORDER BY l.kod;

-- =============================================================
--  ai SXEMİ — AI İDARƏETMƏ QATI
-- =============================================================

-- Q16. AI agentləri və model konfiqurasiyası
SELECT a.ad AS agent, a.vezife, m.ad AS model, m.provider, m.model_ref
FROM ai.ai_agent a
JOIN ai.ai_model m ON m.model_id = a.model_id
WHERE a.aktif = TRUE
ORDER BY a.ad;

-- Q17. AI tapşırıqları və həyat dövrü (iş əmrləri)
SELECT a.ad AS agent, t.teyinat_novu, t.status, t.tesdiq_status,
       t.netice_qiymeti, l.kod AS layihe
FROM ai.ai_teyinat t
JOIN ai.ai_agent a ON a.agent_id = t.agent_id
LEFT JOIN layihe.layihe l ON l.layihe_id = t.layihe_id
ORDER BY t.teyinat_id DESC;

-- Q18. AI qərarları — eminlik və təsdiq vəziyyəti
SELECT q.qerar_novu, q.eminlik, q.status, q.esaslandirma,
       a.ad AS agent
FROM ai.ai_qerar q
JOIN ai.ai_teyinat t ON t.teyinat_id = q.teyinat_id
JOIN ai.ai_agent a ON a.agent_id = t.agent_id
ORDER BY q.eminlik DESC;

-- Q19. AI proqnozları — proqnoz vs real (dəqiqlik)
SELECT l.kod, p.prognoz_novu, p.prognoz_deyer, p.real_deyer, p.ehtimal, p.doqruluk
FROM ai.ai_prognoz p
JOIN layihe.layihe l ON l.layihe_id = p.layihe_id
ORDER BY p.prognoz_id;

-- Q20. AI mesajları — xəbərdarlıq sistemi
SELECT m.movzu, m.onem, m.oxunub, a.ad AS agent, l.kod AS layihe
FROM ai.ai_mesaj m
JOIN ai.ai_agent a ON a.agent_id = m.agent_id
LEFT JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
ORDER BY m.mesaj_id;

-- Q21. AI xərclərinin izlənməsi (token/məbləğ)
SELECT a.ad AS agent, COUNT(l.log_id) AS log_sayi,
       COALESCE(SUM(l.serf_olunan_tokens), 0) AS tokens,
       COALESCE(SUM(l.serf_olunan_xerc), 0) AS xerc_azn
FROM ai.ai_agent a
LEFT JOIN ai.ai_log l ON l.agent_id = a.agent_id
GROUP BY a.agent_id ORDER BY xerc_azn DESC;

-- =============================================================
--  sened / risk / keyfiyyet SXEMLƏRİ
-- =============================================================

-- Q22. Sənədlər və statusları
SELECT sn.ad AS novu, s.ad AS sened, s.nomre, s.status, s.versiya
FROM sened.sened s
JOIN sened.sened_novu sn ON sn.sened_novu_id = s.sened_novu_id
ORDER BY sn.ad, s.sened_id;

-- Q23. Risk profili (ehtimal × təsir)
SELECT l.kod, r.risk_novu, r.tesvir, r.ehtimal, r.tesir, r.derece,
       CASE WHEN r.derece >= 60 THEN 'KRİTİK' WHEN r.derece >= 30 THEN 'ORTA' ELSE 'AZ' END AS seviyye
FROM risk.risk r
JOIN layihe.layihe l ON l.layihe_id = r.layihe_id
ORDER BY r.derece DESC;

-- Q24. Keyfiyyət yoxlamaları və qüsurlar
SELECT l.kod, y.yoxlama_novu, y.netice, y.tarix,
       COUNT(q.qusur_id) AS qusur_sayi,
       COUNT(q.qusur_id) FILTER (WHERE q.status = 'aciq') AS aciq_qusur
FROM keyfiyyet.yoxlama y
JOIN layihe.layihe l ON l.layihe_id = y.layihe_id
LEFT JOIN keyfiyyet.qusur q ON q.yoxlama_id = y.yoxlama_id
GROUP BY y.yoxlama_id, l.kod
ORDER BY l.kod;

-- =============================================================
--  logistika / tehlike SXEMLƏRİ
-- =============================================================

-- Q25. Anbar qalıqları
SELECT a.ad AS anbar, mn.ad AS material,
       SUM(CASE WHEN mh.hereket_novu = 'daxil' THEN mh.miqdar
                WHEN mh.hereket_novu = 'cixar' THEN -mh.miqdar ELSE 0 END) AS qaliq,
       mn.vahid
FROM logistika.anbar a
JOIN logistika.material_hereket mh ON mh.anbar_id = a.anbar_id
JOIN ref.material_novu mn ON mn.material_novu_id = mh.material_novu_id
GROUP BY a.anbar_id, a.ad, mn.material_novu_id, mn.ad, mn.vahid
ORDER BY a.ad, mn.ad;

-- Q26. Çatdırılma gecikmələri
SELECT tc.ad AS tedarukcu, mn.ad AS material, c.plan_tarix, c.real_tarix,
       (c.real_tarix - c.plan_tarix) AS gecikme_gunu, c.status
FROM logistika.catdirilma c
JOIN logistika.tedarukcu tc ON tc.tedarukcu_id = c.tedarukcu_id
JOIN ref.material_novu mn ON mn.material_novu_id = c.material_novu_id
WHERE c.real_tarix > c.plan_tarix
ORDER BY gecikme_gunu DESC;

-- Q27. Əmək təhlükəsizliyi — hadisələr və təlimlər
SELECT i.ad_soyad, COUNT(tl.telim_id) AS telim_sayi,
       COUNT(tl.telim_id) FILTER (WHERE tl.etibarliliq_sonu < CURRENT_DATE) AS muddeti_biten,
       COUNT(o.olay_id) AS hadise_sayi
FROM kadr.isci i
LEFT JOIN tehlike.telim tl ON tl.isci_id = i.isci_id
LEFT JOIN tehlike.olay o ON o.tesevver_eden = i.isci_id
WHERE i.status = 'aktiv'
GROUP BY i.isci_id ORDER BY hadise_sayi DESC;

-- =============================================================
--  audit SXEMİ + FUNKSİYALAR
-- =============================================================

-- Q28. Audit izi — ən çox dəyişiklik edilən cədvəllər
SELECT sxem || '.' || cedvel AS cedvel, emeliyyat, COUNT(*) AS sayi
FROM audit.audit_log
GROUP BY sxem, cedvel, emeliyyat
ORDER BY sayi DESC;

-- Q29. Funksiya nümayişi — layihə progressi və büdcə istifadəsi
SELECT l.kod,
       layihe.layihe_progres(l.layihe_id) AS progress_faizi,
       maliyye.layihe_budce_istifade(l.layihe_id) AS budce_istifade_faizi,
       maliyye.layihe_umumi_xerc(l.layihe_id) AS umumi_xerc,
       maliyye.muqavile_borcu(COALESCE(
         (SELECT muqavile_id FROM satinalma.muqavile WHERE layihe_id = l.layihe_id LIMIT 1), 0)) AS muqavile_borcu
FROM layihe.layihe l
WHERE l.silinib = FALSE
ORDER BY l.layihe_id;

-- Q30. AI funksiyası — büdcə proqnozu (hər layihə üçün)
SELECT l.kod, l.plan_budce, maliyye.layihe_umumi_xerc(l.layihe_id) AS indi_xerc,
       ai.ai_plan_budce_prognozu(l.layihe_id) AS proqnoz_son_deyer
FROM layihe.layihe l
WHERE l.silinib = FALSE
ORDER BY l.layihe_id;

-- =============================================================
--  VIEW-LƏR (hesabat sxemi)
-- =============================================================

-- Q31. Hesabat view: layihə tam icmalı
SELECT * FROM hesabat.layihe_tam_icmal ORDER BY layihe_id;

-- Q32. Hesabat view: AI fəaliyyət statistikası
SELECT * FROM hesabat.ai_faaliyyet;

-- Q33. Hesabat view: layihə risk icmalı
SELECT * FROM hesabat.layihe_risk_icmali;

-- Q34. Hesabat view: müqavilə ödəniş vəziyyəti
SELECT * FROM hesabat.muqavile_odenis_veziyyeti;

-- Q35. Hesabat view: tender effektivlik
SELECT * FROM hesabat.tender_effektivlik;

-- =============================================================
--  YEKUN: Sxem üzrə cədvəl sayı (AI-ya baza xəritəsi)
-- =============================================================

-- Q36. Bütün sxemlər və cədvəl sayı
SELECT schemaname, COUNT(*) AS cedvel_sayi
FROM pg_tables
WHERE schemaname IN ('ref','layihe','satinalma','maliyye','kadr','hesabat','ai','sened','risk','keyfiyyet','logistika','tehlike','audit')
GROUP BY schemaname ORDER BY schemaname;
