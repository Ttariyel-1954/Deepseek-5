-- =====================================================================
--  DeepSeek-4 ERP — İlkin Məlumatlar (Seed)
--  Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi
--  Tarix: 2026-08-24
-- =====================================================================

BEGIN;

-- =====================================================================
--  ref.region — İqtisadi rayonlar
-- =====================================================================
INSERT INTO ref.region (ad, kod) VALUES
('Bakı',                    'BAK'),
('Abşeron-Xızı',            'ABX'),
('Gəncə-Daşkəsən',          'GDK'),
('Qarabağ',                 'QRB'),
('Qazax-Tovuz',             'QTZ'),
('Quba-Xaçmaz',             'QXZ'),
('Lənkəran-Astara',         'LAS'),
('Mərkəzi Aran',            'MAR'),
('Mil-Muğan',               'MMG'),
('Naxçıvan',                'NAX'),
('Şəki-Zaqatala',           'SZA'),
('Şərqi Zəngəzur',          'SZZ'),
('Dağlıq Şirvan',           'DSV')
ON CONFLICT (ad) DO NOTHING;

-- =====================================================================
--  ref.seher — Şəhərlər
-- =====================================================================
INSERT INTO ref.seher (region_id, ad) VALUES
((SELECT region_id FROM ref.region WHERE kod='BAK'), 'Bakı'),
((SELECT region_id FROM ref.region WHERE kod='BAK'), 'Sumqayıt'),
((SELECT region_id FROM ref.region WHERE kod='BAK'), 'Xırdalan'),
((SELECT region_id FROM ref.region WHERE kod='GDK'), 'Gəncə'),
((SELECT region_id FROM ref.region WHERE kod='MAR'), 'Mingəçevir'),
((SELECT region_id FROM ref.region WHERE kod='MAR'), 'Şirvan'),
((SELECT region_id FROM ref.region WHERE kod='SZA'), 'Şəki'),
((SELECT region_id FROM ref.region WHERE kod='LAS'), 'Lənkəran'),
((SELECT region_id FROM ref.region WHERE kod='QXZ'), 'Quba')
ON CONFLICT (region_id, ad) DO NOTHING;

-- =====================================================================
--  ref.muessise_novu — Təhsil müəssisəsi növləri
-- =====================================================================
INSERT INTO ref.muessise_novu (ad) VALUES
('Ümumtəhsil məktəbi'),
('Məktəbəqədər təhsil müəssisəsi (bağça)'),
('Lisey'),
('Gimnaziya'),
('Kollec'),
('Peşə təhsili müəssisəsi'),
('Məktəbdənkənar təhsil müəssisəsi')
ON CONFLICT (ad) DO NOTHING;

-- =====================================================================
--  ref.muessise — Təhsil müəssisələri (müştərilər)
-- =====================================================================
INSERT INTO ref.muessise (seher_id, nov_id, ad, voen, unvan, telefon) VALUES
((SELECT seher_id FROM ref.seher WHERE ad='Bakı'),
 (SELECT nov_id FROM ref.muessise_novu WHERE ad='Ümumtəhsil məktəbi'),
 'N. Nərimanov adına 20 nömrəli tam orta məktəb', '1234567890', 'Bakı, Nərimanov r.', '+994 12 123 45 01'),
((SELECT seher_id FROM ref.seher WHERE ad='Gəncə'),
 (SELECT nov_id FROM ref.muessise_novu WHERE ad='Lisey'),
 'Gəncə şəhər 1 nömrəli lisey', '2234567890', 'Gəncə, Nizami küç.', '+994 22 123 45 02'),
((SELECT seher_id FROM ref.seher WHERE ad='Mingəçevir'),
 (SELECT nov_id FROM ref.muessise_novu WHERE ad='Məktəbəqədər təhsil müəssisəsi (bağça)'),
 'Mingəçevir "Günəş" uşaq bağçası', '3234567890', 'Mingəçevir, Gənclik pros.', '+994 24 123 45 03'),
((SELECT seher_id FROM ref.seher WHERE ad='Sumqayıt'),
 (SELECT nov_id FROM ref.muessise_novu WHERE ad='Ümumtəhsil məktəbi'),
 'Sumqayıt 12 nömrəli tam orta məktəb', '4234567890', 'Sumqayıt, 8-ci mkr.', '+994 18 123 45 04'),
((SELECT seher_id FROM ref.seher WHERE ad='Şəki'),
 (SELECT nov_id FROM ref.muessise_novu WHERE ad='Gimnaziya'),
 'Şəki şəhər humanitar gimnaziyası', '5234567890', 'Şəki, Ə. Nəvvab küç.', '+994 24 123 45 05'),
((SELECT seher_id FROM ref.seher WHERE ad='Bakı'),
 (SELECT nov_id FROM ref.muessise_novu WHERE ad='Kollec'),
 'Bakı Dövlət Təhsil Kolleci', '6234567890', 'Bakı, Xətai r.', '+994 12 123 45 06'),
((SELECT seher_id FROM ref.seher WHERE ad='Lənkəran'),
 (SELECT nov_id FROM ref.muessise_novu WHERE ad='Ümumtəhsil məktəbi'),
 'Lənkəran 7 nömrəli tam orta məktəb', '7234567890', 'Lənkəran, H. Əliyev küç.', '+994 25 123 45 07')
ON CONFLICT (ad) DO NOTHING;

-- =====================================================================
--  ref.is_novu — Tikinti / təmir iş növləri (hierarxik)
-- =====================================================================
INSERT INTO ref.is_novu (parent_id, ad, kod, vahid) VALUES
(NULL, 'Tikinti-quraşdırma işləri', 'TQ', 'm²'),
(NULL, 'Əsaslı təmir', 'ET', 'm²'),
(NULL, 'Cari təmir', 'CT', 'm²'),
(NULL, 'Santexnika işləri', 'SN', 'mb'),
(NULL, 'Elektrik işləri', 'EL', 'mb'),
(NULL, 'İstilik sistemləri', 'IS', 'ədəd'),
(NULL, 'Dam örtüyü', 'DAM', 'm²');

INSERT INTO ref.is_novu (parent_id, ad, kod, vahid) VALUES
((SELECT is_novu_id FROM ref.is_novu WHERE kod='TQ'), 'Yeni binanın tikintisi', 'TQ-01', 'm²'),
((SELECT is_novu_id FROM ref.is_novu WHERE kod='TQ'), 'Əlavə korpusun tikintisi', 'TQ-02', 'm²'),
((SELECT is_novu_id FROM ref.is_novu WHERE kod='ET'), 'Fasadın əsaslı təmiri', 'ET-01', 'm²'),
((SELECT is_novu_id FROM ref.is_novu WHERE kod='ET'), 'Damın əsaslı təmiri', 'ET-02', 'm²'),
((SELECT is_novu_id FROM ref.is_novu WHERE kod='CT'), 'Sinif otaqlarının cari təmiri', 'CT-01', 'm²'),
((SELECT is_novu_id FROM ref.is_novu WHERE kod='CT'), 'Dəhliz və sanitar qovşaqların təmiri', 'CT-02', 'm²');

-- =====================================================================
--  ref.material_novu — Tikinti materialları (hierarxik)
-- =====================================================================
INSERT INTO ref.material_novu (parent_id, ad, kod, vahid) VALUES
(NULL, 'Sement və beton', 'SB', 't'),
(NULL, 'Kərpic', 'KR', 'ədəd'),
(NULL, 'Boyaq materialları', 'BM', 'kq'),
(NULL, 'Dam örtüyü materialları', 'DM', 'm²'),
(NULL, 'Santexnika materialları', 'SM', 'ədəd'),
(NULL, 'Elektrik materialları', 'EM', 'ədəd'),
(NULL, 'Taxta materiallar', 'TM', 'm³');

INSERT INTO ref.material_novu (parent_id, ad, kod, vahid) VALUES
((SELECT material_novu_id FROM ref.material_novu WHERE kod='SB'), 'Portland sement M500', 'SB-01', 't'),
((SELECT material_novu_id FROM ref.material_novu WHERE kod='SB'), 'Beton B25', 'SB-02', 'm³'),
((SELECT material_novu_id FROM ref.material_novu WHERE kod='KR'), 'Tikinti kərpici', 'KR-01', 'ədəd'),
((SELECT material_novu_id FROM ref.material_novu WHERE kod='BM'), 'Akril boyaq', 'BM-01', 'kq'),
((SELECT material_novu_id FROM ref.material_novu WHERE kod='BM'), 'Suvac qarışığı', 'BM-02', 'kq'),
((SELECT material_novu_id FROM ref.material_novu WHERE kod='DM'), 'Metallik dam örtüyü', 'DM-01', 'm²'),
((SELECT material_novu_id FROM ref.material_novu WHERE kod='DM'), 'Buruq (profil) örtük', 'DM-02', 'm²');

-- =====================================================================
--  layihe.layihe_status — Layihə statusları
-- =====================================================================
INSERT INTO layihe.layihe_status (ad, kod, reng, sira) VALUES
('Planlaşdırma', 'plan',   '#3b82f6', 1),
('Tenderdə',     'tenderde', '#f59e0b', 2),
('İcra olunur',  'icra',   '#22c55e', 3),
('Tamamlanıb',   'tamam',  '#14b8a6', 4),
('Dayandırılıb', 'dayandi', '#ef4444', 5);

-- =====================================================================
--  layihe.layihe — Əsas layihələr
-- =====================================================================
INSERT INTO layihe.layihe (muessise_id, is_novu_id, status_id, seher_id, kod, ad, tesvir, plan_budce, bashlama_tarixi, son_tarix, olcu) VALUES
((SELECT muessise_id FROM ref.muessise WHERE voen='1234567890'),
 (SELECT is_novu_id FROM ref.is_novu WHERE kod='ET-01'),
 (SELECT status_id FROM layihe.layihe_status WHERE kod='icra'),
 (SELECT seher_id FROM ref.seher WHERE ad='Bakı'),
 'L-2026-001', '20 nömrəli məktəbin fasadının əsaslı təmiri',
 'Fasadın izolyasiyası, suvaq və boyaq işləri', 850000.00, '2026-03-01', '2026-09-30', 4200.00),

((SELECT muessise_id FROM ref.muessise WHERE voen='2234567890'),
 (SELECT is_novu_id FROM ref.is_novu WHERE kod='TQ-02'),
 (SELECT status_id FROM layihe.layihe_status WHERE kod='tenderde'),
 (SELECT seher_id FROM ref.seher WHERE ad='Gəncə'),
 'L-2026-002', '1 nömrəli liseyə əlavə korpusun tikintisi',
 '2 mərtəbəli, 12 sinif otaqlı korpus', 2400000.00, '2026-10-01', '2027-06-30', 1800.00),

((SELECT muessise_id FROM ref.muessise WHERE voen='3234567890'),
 (SELECT is_novu_id FROM ref.is_novu WHERE kod='CT-01'),
 (SELECT status_id FROM layihe.layihe_status WHERE kod='plan'),
 (SELECT seher_id FROM ref.seher WHERE ad='Mingəçevir'),
 'L-2026-003', '"Günəş" bağçasında sinif otaqlarının cari təmiri',
 '8 otağın suvaq-boyaq işləri, döşəmə yenilənməsi', 180000.00, '2026-08-15', '2026-11-30', 950.00),

((SELECT muessise_id FROM ref.muessise WHERE voen='4234567890'),
 (SELECT is_novu_id FROM ref.is_novu WHERE kod='ET-02'),
 (SELECT status_id FROM layihe.layihe_status WHERE kod='tamam'),
 (SELECT seher_id FROM ref.seher WHERE ad='Sumqayıt'),
 'L-2026-004', '12 nömrəli məktəbin damının əsaslı təmiri',
 'Buruq örtüyün dəyişdirilməsi, izolyasiya', 620000.00, '2026-01-15', '2026-06-30', 3100.00),

((SELECT muessise_id FROM ref.muessise WHERE voen='5234567890'),
 (SELECT is_novu_id FROM ref.is_novu WHERE kod='CT-02'),
 (SELECT status_id FROM layihe.layihe_status WHERE kod='icra'),
 (SELECT seher_id FROM ref.seher WHERE ad='Şəki'),
 'L-2026-005', 'Humanitar gimnaziyada dəhlizlərin təmiri',
 'Dəhliz və sanitar qovşaqların yenilənməsi', 240000.00, '2026-05-01', '2026-08-31', 780.00);

-- =====================================================================
--  layihe.layihe_merhele — Mərhələlər
-- =====================================================================
INSERT INTO layihe.layihe_merhele (layihe_id, ad, plan_faiz, real_faiz, plan_tarix, real_tarix) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'Skele (iskala) və hazırlıq işləri', 20, 20, '2026-03-01', '2026-03-20'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'İzolyasiya işləri', 35, 30, '2026-04-15', '2026-05-10'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'Suvaq işləri', 25, 10, '2026-06-01', NULL),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'Boyaq və təhvil', 20, 0, '2026-08-01', NULL),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 'Köhnə örtüyün sökülməsi', 25, 25, '2026-01-15', '2026-02-01'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 'Yeni örtük və izolyasiya', 55, 55, '2026-03-01', '2026-05-15'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 'Sistemlərin quraşdırılması', 20, 20, '2026-06-01', '2026-06-25');

-- =====================================================================
--  layihe.layihe_material — Layihə materialları
-- =====================================================================
INSERT INTO layihe.layihe_material (layihe_id, material_novu_id, miqdar, vahid, qiymet) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-01'), 850, 'kq', 12.50),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-02'), 12000, 'kq', 0.85),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='DM-02'), 3100, 'm²', 28.00),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-01'), 280, 'kq', 12.50),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='SB-01'), 420, 't', 210.00),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='KR-01'), 145000, 'ədəd', 0.45);

-- =====================================================================
--  satinalma.tender_status — Tender statusları
-- =====================================================================
INSERT INTO satinalma.tender_status (ad, kod, reng, sira) VALUES
('Elan olunub',      'elan',          '#3b82f6', 1),
('Təkliflər qəbulu', 'qebul',         '#f59e0b', 2),
('Qiymətləndirmə',   'qiymetlendirme', '#8b5cf6', 3),
('Qalib müəyyən olunub', 'qalib',     '#22c55e', 4),
('Ləğv olunub',      'legv',          '#ef4444', 5);

-- =====================================================================
--  satinalma.tender — Tenderlər
-- =====================================================================
INSERT INTO satinalma.tender (layihe_id, status_id, kod, ad, elan_tarixi, son_tarix, qiymet_serhedi) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT status_id FROM satinalma.tender_status WHERE kod='qalib'),
 'T-2026-001', 'Fasad təmiri üzrə tender', '2026-02-01', '2026-02-20', 850000.00),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 (SELECT status_id FROM satinalma.tender_status WHERE kod='qebul'),
 'T-2026-002', 'Korpus tikintisi üzrə tender', '2026-08-10', '2026-09-15', 2400000.00),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT status_id FROM satinalma.tender_status WHERE kod='qalib'),
 'T-2026-003', 'Dam təmiri üzrə tender', '2026-01-05', '2026-01-20', 620000.00);

-- =====================================================================
--  satinalma.tender_istirakci — İştirakçılar
-- =====================================================================
INSERT INTO satinalma.tender_istirakci (tender_id, sirket_ad, voen, teklif_mebleg, teklif_tarixi, qalib) VALUES
((SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-001'), 'AZKURTİK MMC', '1122334455', 780000.00, '2026-02-18', TRUE),
((SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-001'), 'İNŞA-2020 MMC', '2211334455', 820000.00, '2026-02-19', FALSE),
((SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-001'), 'QAFQAZ TİKİNTİ MMC', '3311224455', 845000.00, '2026-02-19', FALSE),
((SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-003'), 'SUMQAYIT-DAM MMC', '4411223355', 590000.00, '2026-01-18', TRUE),
((SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-003'), 'DAVAMAT MMC', '5511223344', 615000.00, '2026-01-19', FALSE);

-- Qalib iştirakçının tender cədvəlinə yazılması
UPDATE satinalma.tender SET qalib_istirakci_id =
  (SELECT istirakci_id FROM satinalma.tender_istirakci
   WHERE tender_id = (SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-001') AND qalib=TRUE)
WHERE kod='T-2026-001';

UPDATE satinalma.tender SET qalib_istirakci_id =
  (SELECT istirakci_id FROM satinalma.tender_istirakci
   WHERE tender_id = (SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-003') AND qalib=TRUE)
WHERE kod='T-2026-003';

-- =====================================================================
--  satinalma.muqavile — Müqavilələr
-- =====================================================================
INSERT INTO satinalma.muqavile (tender_id, layihe_id, nomre, podratci, imzalanma_tarixi, bashlama_tarixi, son_tarix, mebleg) VALUES
((SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-001'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 'MQ-2026-015', 'AZKURTİK MMC', '2026-03-01', '2026-03-01', '2026-09-30', 780000.00),
((SELECT tender_id FROM satinalma.tender WHERE kod='T-2026-003'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 'MQ-2026-008', 'SUMQAYIT-DAM MMC', '2026-01-25', '2026-02-01', '2026-06-30', 590000.00);

-- =====================================================================
--  satinalma.material_tedaruk — Material tədarükü
-- =====================================================================
INSERT INTO satinalma.material_tedaruk (muqavile_id, material_novu_id, miqdar, vahid, qiymet) VALUES
((SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-01'), 850, 'kq', 11.80),
((SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-02'), 12000, 'kq', 0.78),
((SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-008'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='DM-02'), 3100, 'm²', 26.50);

-- =====================================================================
--  maliyye.budce_madde — Büdcə maddələri (hierarxik)
-- =====================================================================
INSERT INTO maliyye.budce_madde (parent_id, ad, kod, tip) VALUES
(NULL, 'Tikinti materialları', 'MAT', 'xerc'),
(NULL, 'İşçi qüvvəsi', 'IQ', 'xerc'),
(NULL, 'Mexanizm və avadanlıq', 'MEX', 'xerc'),
(NULL, 'Digər xərclər', 'DIG', 'xerc'),
(NULL, 'Maliyyələşmə (gəlir)', 'MAL', 'gelir');

INSERT INTO maliyye.budce_madde (parent_id, ad, kod, tip) VALUES
((SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT'), 'Sement və beton', 'MAT-01', 'xerc'),
((SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT'), 'Boyaq materialları', 'MAT-02', 'xerc'),
((SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT'), 'Dam örtüyü', 'MAT-03', 'xerc'),
((SELECT madde_id FROM maliyye.budce_madde WHERE kod='IQ'), 'Mühəndis-texniki işçilər', 'IQ-01', 'xerc'),
((SELECT madde_id FROM maliyye.budce_madde WHERE kod='IQ'), 'Fəhlə işçilər', 'IQ-02', 'xerc');

-- =====================================================================
--  maliyye.xerc — Xərclər
-- =====================================================================
INSERT INTO maliyye.xerc (layihe_id, muqavile_id, madde_id, mebleg, tarix, tesvir) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 (SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT-02'), 10500.00, '2026-04-10', 'Akril boyaq alışı'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 (SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT-02'), 10200.00, '2026-05-12', 'Suvac qarışığı alışı'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 (SELECT madde_id FROM maliyye.budce_madde WHERE kod='IQ-02'), 48000.00, '2026-05-30', 'Fəhlə işçilərin əməkhaqqı (aprel-may)'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-008'),
 (SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT-03'), 82150.00, '2026-03-20', 'Buruq örtük alışı'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-008'),
 (SELECT madde_id FROM maliyye.budce_madde WHERE kod='IQ-02'), 56000.00, '2026-05-25', 'Fəhlə işçilərin əməkhaqqı'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 (SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT-02'), 4500.00, '2026-06-15', 'Gimnaziya üçün boyaq'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'),
 NULL,
 (SELECT madde_id FROM maliyye.budce_madde WHERE kod='MAT-02'), 3500.00, '2026-08-20', 'Bağça üçün ilkin material alışı');

-- =====================================================================
--  maliyye.odenis — Ödənişlər
-- =====================================================================
INSERT INTO maliyye.odenis (muqavile_id, mebleg, tarix, odenis_novu) VALUES
((SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'), 300000.00, '2026-03-15', 'bank'),
((SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'), 200000.00, '2026-05-20', 'bank'),
((SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-008'), 250000.00, '2026-02-10', 'bank'),
((SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-008'), 200000.00, '2026-04-15', 'bank');

-- =====================================================================
--  kadr.vezife — Vəzifələr
-- =====================================================================
INSERT INTO kadr.vezife (ad, maas_alt, maas_ust) VALUES
('Mühəndis-tikintiçi', 1800, 3500),
('Layihə rəhbəri', 3000, 5000),
('Smetaçı', 1500, 2800),
('Təchizat üzrə mütəxəssis', 1400, 2600),
('Usta (böyük ustа)', 1200, 2400),
('Fəhlə', 800, 1500),
('Mühasib', 1600, 3000);

-- =====================================================================
--  kadr.isci — İşçilər
-- =====================================================================
INSERT INTO kadr.isci (vezife_id, ad_soyad, fin, seriya_no, telefon, maas, ise_bashlama, status) VALUES
((SELECT vezife_id FROM kadr.vezife WHERE ad='Layihə rəhbəri'), 'Elçin Məmmədov', 'FIN001', 'AZE123456', '+994 50 123 45 01', 4800, '2020-01-15', 'aktiv'),
((SELECT vezife_id FROM kadr.vezife WHERE ad='Mühəndis-tikintiçi'), 'Ramin Əliyev', 'FIN002', 'AZE123457', '+994 55 123 45 02', 3200, '2021-03-01', 'aktiv'),
((SELECT vezife_id FROM kadr.vezife WHERE ad='Mühəndis-tikintiçi'), 'Tural Hüseynov', 'FIN003', 'AZE123458', '+994 70 123 45 03', 2900, '2022-06-10', 'aktiv'),
((SELECT vezife_id FROM kadr.vezife WHERE ad='Smetaçı'), 'Nigar Quliyeva', 'FIN004', 'AZE123459', '+994 51 123 45 04', 2500, '2021-09-01', 'aktiv'),
((SELECT vezife_id FROM kadr.vezife WHERE ad='Təchizat üzrə mütəxəssis'), 'Səbuhi Rzayev', 'FIN005', 'AZE123460', '+994 55 123 45 05', 2200, '2020-11-20', 'aktiv'),
((SELECT vezife_id FROM kadr.vezife WHERE ad='Mühasib'), 'Aygün İsmayılova', 'FIN006', 'AZE123461', '+994 50 123 45 06', 2800, '2019-04-15', 'aktiv'),
((SELECT vezife_id FROM kadr.vezife WHERE ad='Usta (böyük ustа)'), 'Vüqar Nəbiyev', 'FIN007', 'AZE123462', '+994 70 123 45 07', 2300, '2022-02-14', 'aktiv'),
((SELECT vezife_id FROM kadr.vezife WHERE ad='Fəhlə'), 'Orxan Babayev', 'FIN008', 'AZE123463', '+994 51 123 45 08', 1200, '2023-05-01', 'aktiv');

-- =====================================================================
--  kadr.layihe_isci_teyinat — Layihə üzrə təyinatlar
-- =====================================================================
INSERT INTO kadr.layihe_isci_teyinat (layihe_id, isci_id, vezife_id, gunelik_mebleg, bashlama_tarixi, son_tarix) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT isci_id FROM kadr.isci WHERE fin='FIN001'),
 (SELECT vezife_id FROM kadr.vezife WHERE ad='Layihə rəhbəri'), 200, '2026-03-01', '2026-09-30'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT isci_id FROM kadr.isci WHERE fin='FIN002'),
 (SELECT vezife_id FROM kadr.vezife WHERE ad='Mühəndis-tikintiçi'), 150, '2026-03-01', '2026-09-30'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'),
 (SELECT vezife_id FROM kadr.vezife WHERE ad='Usta (böyük ustа)'), 110, '2026-02-01', '2026-06-30'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'),
 (SELECT isci_id FROM kadr.isci WHERE fin='FIN003'),
 (SELECT vezife_id FROM kadr.vezife WHERE ad='Mühəndis-tikintiçi'), 130, '2026-05-01', '2026-08-31');

-- =====================================================================
--  istifadəçilər (backend migration 002 ilə qovuşur)
--  hesabat.layihe_budce_fakt view-i sxemdə yaradılıb
-- =====================================================================

COMMIT;
