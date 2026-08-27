-- =====================================================================
--  DeepSeek-4 ERP v5 — Yeni Cədvəllər üçün Seed Məlumatlar
--  Sxemlər: ai, sened, risk, keyfiyyet, logistika, tehlike, audit
--  Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi
--  Mövcud seed-ə istinadlar: layihe_id=1..5, isci_id=1..8, muqavile_id=1..2,
--      material_novu_id=8..14 (SB-01..DM-02), merhele_id=1..7, seher_id=1..9
--  Tarix: 2026-08-25
-- =====================================================================

BEGIN;

-- =====================================================================
--  ai SXEMİ — SÜNİ İNTELLEKT İDARƏETMƏ QATI
-- =====================================================================

-- ---------------------------------------------------------------------
--  ai.ai_model — AI modelləri
-- ---------------------------------------------------------------------
INSERT INTO ai.ai_model (ad, provider, model_ref, rolu, max_tokens, temperature, qiymet_1000_input, qiymet_1000_output, aktif, qeyd) VALUES
('DeepSeek Chat',        'deepseek',  'deepseek-chat',     'analitik',      4096, 0.30, 0.1400, 0.2800, TRUE,  'Ümumi tapşırıqlar üçün sürətli və iqtisadi model'),
('DeepSeek Reasoner',    'deepseek',  'deepseek-reasoner', 'nezaretci',     4096, 0.10, 0.5500, 1.1900, TRUE,  'Dərin analiz və əsaslandırma tələb edən tapşırıqlar'),
('GPT-4o',               'openai',    'gpt-4o',            'cavablandiran', 8192, 0.30, 2.5000, 10.000, TRUE, 'Ümumi mətn əməliyyatları və hesabat yazımı'),
('Claude Opus',          'anthropic', 'claude-opus-4',     'planlayici',    8192, 0.20, 15.000, 75.000, TRUE, 'Strateji planlaşdırma və mürəkkəb qərarlar'),
('Claude Sonnet',        'anthropic', 'claude-sonnet-4',   'analitik',      8192, 0.30, 3.0000, 15.000, TRUE, 'Risk və keyfiyyət analitikası üçün balanslı model')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  ai.ai_agent — AI agentləri
-- ---------------------------------------------------------------------
INSERT INTO ai.ai_agent (model_id, ad, vezife, tesvir, status, aktif) VALUES
((SELECT model_id FROM ai.ai_model WHERE model_ref='deepseek-reasoner'), 'Layihə Planlayıcısı',        'planlayici',                'Layihə mərhələlərini planlaşdırır, vaxt və resurs bölgüsü edir', 'aktiv', TRUE),
((SELECT model_id FROM ai.ai_model WHERE model_ref='gpt-4o'),            'Tender Analitiki',          'tender_analitiki',          'Tender təkliflərini qiymətləndirir, qalib təklifini tövsiyə edir', 'aktiv', TRUE),
((SELECT model_id FROM ai.ai_model WHERE model_ref='claude-sonnet-4'),   'Risk Nəzarətçisi',          'risk_nezaretcisi',          'Layihə risklərini izləyir, müdaxilə planları təklif edir', 'aktiv', TRUE),
((SELECT model_id FROM ai.ai_model WHERE model_ref='deepseek-chat'),     'Xərc Analitiki',            'xerc_analitiki',            'Büdcə proqnozları verir, xərc aşırlıqlarını xəbərdar edir', 'aktiv', TRUE),
((SELECT model_id FROM ai.ai_model WHERE model_ref='claude-opus-4'),     'Keyfiyyət Müfəttişi',       'keyfiyyet_mufettisi',       'Yoxlama nəticələrini təhlil edir, qüsur və qəbul aktlarını hazırlayır', 'aktiv', TRUE),
((SELECT model_id FROM ai.ai_model WHERE model_ref='deepseek-chat'),     'Təchizat Optimallaşdırıcısı','techizat_optimallashdiricisi','Material tədarükü və anbar hərəkətlərini optimallaşdırır', 'aktiv', TRUE)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  ai.ai_teyinat — AI tapşırıqları
-- ---------------------------------------------------------------------
INSERT INTO ai.ai_teyinat (agent_id, layihe_id, teyinat_novu, giris_json, cixis_json, prompt, status, ustunluk, netice_qiymeti, tesdiq_status, yaradan, tamamlanma_tarixi) VALUES
((SELECT agent_id FROM ai.ai_agent WHERE ad='Xərc Analitiki'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 'budce_prognozu',
 '{"plan_budce": 850000, "xerc_umumi": 68700, "progres": 60}'::jsonb,
 '{"prognoz_budce": 823000, "sapma_faizi": -3.2, "tovsiye": "Material alışını rübün sonuna saxlayın"}'::jsonb,
 'L-2026-001 layihəsinin tamamlanma büdcəsini cari xərc və progresə əsasən proqnozlaşdır.',
 'hazir', 7, 92.00, 'tesdiqlendi', 1, '2026-08-10 14:30:00+04'),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Tender Analitiki'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 'tender_qiymetlendirme',
 '{"qiymet_serhedi": 2400000, "teklifler": 4}'::jsonb,
 '{"en_yaxsi_teklif": 2210000, "tovsiye_edilen": "AZKURTİK MMC", "eminlik": 87}'::jsonb,
 'Korpus tikintisi üzrə tender təkliflərini qiymət və texniki meyarlara görə dərəcələndir.',
 'hazir', 8, 85.50, 'golecek', 1, '2026-08-20 11:00:00+04'),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Risk Nəzarətçisi'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 'risk_analizi',
 '{"riskler": ["material_qiymet", "hava"], "ehtimal_ort": 57}'::jsonb,
 '{"kritik_risk": "material_qiymet", "derece": 42, "mudaxile_plani": "Alternativ təchizatçı ilə opsion müqavilə"}'::jsonb,
 'Fasad təmiri layihəsinin risklərini təhlil edib prioritetləşdir.',
 'hazir', 9, 90.00, 'tesdiqlendi', 1, '2026-08-05 09:15:00+04'),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Xərc Analitiki'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'),
 'xerc_asirliq_xeberdarligi',
 '{"plan_budce": 240000, "xerc_umumi": 245500, "merhele": "dahliz"}'::jsonb,
 NULL,
 'Gimnaziya dəhliz təmirində büdcə aşırlığını təhlil et və xəbərdarlıq hazırla.',
 'islemede', 10, NULL, 'golecek', 1, NULL),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Layihə Planlayıcısı'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'),
 'budce_prognozu',
 '{"plan_budce": 180000, "bashlama": "2026-08-15", "son": "2026-11-30"}'::jsonb,
 NULL,
 'Günəş bağçasının cari təmiri üçün mərhələli vaxt-büdcə cədvəli hazırla.',
 'golecek', 4, NULL, 'golecek', NULL, NULL),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Təchizat Optimallaşdırıcısı'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 'material_planlamasi',
 '{"telabat": {"sement_t": 420, "kerpic_adet": 145000}}'::jsonb,
 '{"optimal_sifaris": "2 partiya", "qenaet_faizi": 8.5}'::jsonb,
 'Korpus tikintisi üçün material sifarişlərini optimallaşdır.',
 'islemede', 6, NULL, 'golecek', 1, NULL),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Keyfiyyət Müfəttişi'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 'keyfiyyet_hesabati',
 '{"yoxlama_sayi": 3, "qusur_sayi": 2}'::jsonb,
 '{"umumi_netice": "qenaetbexsh", "tovsiye": "Sistem quraşdırması üzrə əlavə yoxlama"}'::jsonb,
 'Dam təmiri layihəsində keyfiyyət göstəriciləri üzrə hesabat hazırla.',
 'hazir', 5, 78.00, 'tesdiqlendi', 1, '2026-08-08 16:45:00+04'),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Risk Nəzarətçisi'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 'risk_analizi',
 '{"riskler": ["torpaq", "tedaruk"], "merhele": "temel"}'::jsonb,
 NULL,
 'Korpus tikintisində torpaq və tədarük risklərini qiymətləndir.',
 'xesver', 3, NULL, 'redd_edildi', 1, NULL),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Xərc Analitiki'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 'budce_prognozu',
 '{"plan_budce": 620000, "xerc_umumi": 138150, "progres": 100}'::jsonb,
 '{"final_xerc": 602000, "qenaet": 18000}'::jsonb,
 'Tamamlanmış dam təmiri layihəsinin yekun xərc təhlilini apar.',
 'hazir', 7, 95.00, 'tesdiqlendi', 1, '2026-08-01 10:00:00+04')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  ai.ai_qerar — AI qərarları
-- ---------------------------------------------------------------------
INSERT INTO ai.ai_qerar (teyinat_id, qerar_novu, mezmun, esaslandirma, eminlik, tesdiq_eden, tesdiq_tarixi, status) VALUES
((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='budce_prognozu' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001')),
 'budce_tovsiyesi',
 '{"aksiya": "Material alışını 4-cü rübə saxla", "gozlenilen_qenaet": 27000}'::jsonb,
 'Cari xərc-progres nisbəti göstərir ki, büdcə 3.2% aşağı tamamlanacaq.',
 92.50, 1, '2026-08-12 09:00:00+04', 'icra_olundu'),

((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='tender_qiymetlendirme'),
 'tender_qiymet_tovsiyesi',
 '{"qalib": "AZKURTİK MMC", "teklif": 2210000, "doviz": "AZN"}'::jsonb,
 'Ən aşağı qiymət və texniki meyarlara əsasən AZKURTİK MMC optimal seçimdir.',
 87.00, 1, '2026-08-21 12:00:00+04', 'tesdiqlendi'),

((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='risk_analizi' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001')),
 'risk_qebulu',
 '{"qerar": "Material qiymət riskini opsion müqavilə ilə hedj et"}'::jsonb,
 'Risk dərəcəsi 42-dir və əsas büdcəyə təsir göstərə bilər.',
 78.50, 1, '2026-08-06 15:30:00+04', 'icra_olunur'),

((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='xerc_asirliq_xeberdarligi'),
 'xerc_mehdudlashdirme',
 '{"aksiya": "Dahliz təmirində slave işləri dayandır", "limit": 240000}'::jsonb,
 'Büdcə 2.3% aşılıb, əlavə xərclər dayandırılmalıdır.',
 65.00, NULL, NULL, 'teklif'),

((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='keyfiyyet_hesabati'),
 'keyfiyyet_yeniden_yoxlama',
 '{"aksiya": "Sistem quraşdırması üzrə əlavə yoxlama keçir"}'::jsonb,
 'Qüsurların sayı normaldır, lakin quraşdırma mərhələsi nəzarət tələb edir.',
 81.00, NULL, NULL, 'teklif'),

((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='budce_prognozu' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004')),
 'budce_artimi_teklifi',
 '{"aksiya": "Artim_telabi_yox", "final_xerc": 602000}'::jsonb,
 'Layihə 18000 AZN qənaətlə tamamlanıb, artım tələbi əsassızdır.',
 55.00, NULL, NULL, 'redd_edildi')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  ai.ai_prognoz — AI proqnozları
-- ---------------------------------------------------------------------
INSERT INTO ai.ai_prognoz (layihe_id, prognoz_novu, prognoz_deyer, real_deyer, ehtimal, tarix, doqruluk, qeyd) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'xerc_asirliq',     823000.00, NULL, 65.00, '2026-08-10 14:30:00+04', NULL, 'Fasad təmiri üzrə büdcə proqnozu'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'muddet_gecikmesi', 30.00,     NULL, 45.00, '2026-08-10 14:30:00+04', NULL, 'Suvaq işlərinin gecikməsi səbəbindən təhvil tarixinin dəyişmə ehtimalı'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), 'budce_sapmasi',    2500000.00,NULL, 55.00, '2026-08-20 11:00:00+04', NULL, 'Korpus tikintisində ilkin smeta artımı riski'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'), 'xerc_asirliq',     195000.00, NULL, 35.00, '2026-08-22 09:30:00+04', NULL, 'Bağça təmirində əlavə material ehtiyacı proqnozu'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 'muddet_gecikmesi', 15.00,     0.00, 25.00, '2026-06-20 10:00:00+04', 78.00, 'Dam təmiri planlaşdırılan müddətdə tamamlandı'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'), 'material_qitligi', 12000.00,  NULL, 40.00, '2026-08-15 16:00:00+04', NULL, 'Boyaq materialının qıtlığı proqnozu')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  ai.ai_mesaj — AI mesajları
-- ---------------------------------------------------------------------
INSERT INTO ai.ai_mesaj (agent_id, layihe_id, alici_id, movzu, mezmun, onem, oxunub) VALUES
((SELECT agent_id FROM ai.ai_agent WHERE ad='Risk Nəzarətçisi'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 1, 'Risk artımı xəbərdarlığı',
 'L-2026-001 layihəsində material qiymətlərinin artması riski yüksəkdir. Alternativ təchizatçı ilə opsion müqavilə tövsiyə olunur.',
 'yuksek', FALSE),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Xərc Analitiki'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'),
 1, 'Xərc büdcəni aşır',
 'Gimnaziya dəhliz təmirində ümumi xərc 245,500 AZN ilə planı (240,000 AZN) 2.3% aşıb. Əlavə işlər dayandırılmalıdır.',
 'kritik', FALSE),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Tender Analitiki'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 1, 'Tender təklifləri hazırdır',
 'Korpus tikintisi üzrə 4 təklif qiymətləndirilib. Ən optimal təklif AZKURTİK MMC tərəfindən verilib (2,210,000 AZN).',
 'normal', FALSE),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Layihə Planlayıcısı'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'),
 1, 'Büdcə proqnozu yeniləndi',
 'Günəş bağçasının cari təmirində proqnoz büdcə 195,000 AZN təşkil edir. Mərhələli cədvəl təsdiqə hazırdır.',
 'asagi', TRUE),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Təchizat Optimallaşdırıcısı'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 1, 'Material çatışmazlığı riski',
 'Korpus tikintisi üçün sement və kərpic ehtiyatı plana görə 85% təmin edilib. Növbəti partiya sifarişi 2 həftəyə çatdırılmalıdır.',
 'yuksek', FALSE),

((SELECT agent_id FROM ai.ai_agent WHERE ad='Keyfiyyət Müfəttişi'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 1, 'Keyfiyyət yoxlaması tamamlandı',
 'Dam təmiri layihəsində keçirilən yoxlamalar qənaətbəxşdir. Sistem quraşdırması üzrə əlavə nəzarət tövsiyə olunur.',
 'normal', TRUE)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  ai.ai_log — AI icra loqları
-- ---------------------------------------------------------------------
INSERT INTO ai.ai_log (teyinat_id, agent_id, hadise, mesaj, serf_olunan_tokens, serf_olunan_xerc) VALUES
((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='budce_prognozu' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001')),
 (SELECT agent_id FROM ai.ai_agent WHERE ad='Xərc Analitiki'),
 'bitdi', 'Büdcə proqnozu uğurla tamamlandı', 12500, 0.45),
((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='tender_qiymetlendirme'),
 (SELECT agent_id FROM ai.ai_agent WHERE ad='Tender Analitiki'),
 'bitdi', 'Tender təklifləri dərəcələndi', 28400, 2.10),
((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='risk_analizi' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001')),
 (SELECT agent_id FROM ai.ai_agent WHERE ad='Risk Nəzarətçisi'),
 'bitdi', 'Risk analizi tamamlandı', 9800, 0.85),
((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='risk_analizi' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002')),
 (SELECT agent_id FROM ai.ai_agent WHERE ad='Risk Nəzarətçisi'),
 'xesver', 'Model limiti aşıldı, tapşırıq xətaya düşdü', 3200, 0.30),
((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='xerc_asirliq_xeberdarligi'),
 (SELECT agent_id FROM ai.ai_agent WHERE ad='Xərc Analitiki'),
 'basladi', 'Xərc aşırlığı analizi başladı', 0, 0.00),
((SELECT teyinat_id FROM ai.ai_teyinat WHERE teyinat_novu='material_planlamasi'),
 (SELECT agent_id FROM ai.ai_agent WHERE ad='Təchizat Optimallaşdırıcısı'),
 'bitdi', 'Material planlaması tamamlandı', 15300, 0.60)
ON CONFLICT DO NOTHING;

-- =====================================================================
--  sened SXEMİ — SƏNƏD İDARƏETMƏSİ
-- =====================================================================

-- ---------------------------------------------------------------------
--  sened.sened_novu — Sənəd növləri
-- ---------------------------------------------------------------------
INSERT INTO sened.sened_novu (ad, kod, mucebri, aktif) VALUES
('Smeta',           'smeta',        TRUE,  TRUE),
('Texniki akt',     'texniki_akt',  TRUE,  TRUE),
('İcra aktı',       'icra_akti',    TRUE,  TRUE),
('Müqavilə',        'muqavile',     TRUE,  TRUE),
('Hesabat',         'hesabat',      FALSE, TRUE),
('Məktub',          'mektub',       FALSE, TRUE),
('Tender sənədi',   'tender_senedi',TRUE,  TRUE),
('Protokol',        'protokol',     FALSE, TRUE)
ON CONFLICT (ad) DO NOTHING;

-- ---------------------------------------------------------------------
--  sened.sened — Sənədlər
--  Qeyd: trg_sened_versiya triggeri UPDATE zamanı versiyanı avtomatik
--  artırır, buna görə INSERT-də versiya default (1) saxlanılır.
-- ---------------------------------------------------------------------
INSERT INTO sened.sened (sened_novu_id, layihe_id, muqavile_id, ad, nomre, fayl_yolu, tarix, status, yaradan) VALUES
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='smeta'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 'Fasad təmiri smeta hesabatı', 'SM-2026-045', '/senedler/smeta/L-2026-001_smeta_v2.pdf', '2026-03-05', 'tesdiqlendi', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='icra_akti'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-015'),
 'Mart ayı icra aktı', 'IA-2026-011', '/senedler/icra/L-2026-001_mart_icra.pdf', '2026-04-05', 'tesdiqlendi', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='icra_akti'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT muqavile_id FROM satinalma.muqavile WHERE nomre='MQ-2026-008'),
 'May ayı icra aktı', 'IA-2026-028', '/senedler/icra/L-2026-004_may_icra.pdf', '2026-06-05', 'tesdiqlendi', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='tender_senedi'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 NULL,
 'Korpus tikintisi tender sənədləri', 'TS-2026-003', '/senedler/tender/L-2026-002_senedler.pdf', '2026-08-15', 'tesdiqde', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='hesabat'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'),
 NULL,
 'Bağça təmirinin ilkin hesabatı', 'HB-2026-017', NULL, '2026-08-25', 'qaralama', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='mektub'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'),
 NULL,
 'Təhvil-təslim barədə məktub', 'MK-2026-009', '/senedler/mektub/L-2026-005_mektub.pdf', '2026-08-20', 'tesdiqlendi', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='texniki_akt'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 NULL,
 'Dam örtüyünün texniki yoxlama aktı', 'TA-2026-031', '/senedler/akt/L-2026-004_texniki_akt.pdf', '2026-05-20', 'tesdiqlendi', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='protokol'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 NULL,
 'Tender komissiyası protokolu', 'PR-2026-005', '/senedler/protokol/L-2026-002_protokol.pdf', '2026-09-10', 'tesdiqde', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='hesabat'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 NULL,
 'Rüblük icra hesabatı', 'RB-2026-002', NULL, '2026-08-31', 'qaralama', 1),
((SELECT sened_novu_id FROM sened.sened_novu WHERE kod='muqavile'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 NULL,
 'Podrat müqaviləsinin layihəsi', 'MQ-2026-0XX', NULL, '2026-09-15', 'qaralama', 1)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  sened.sened_versiya — Sənəd versiyaları
-- ---------------------------------------------------------------------
INSERT INTO sened.sened_versiya (sened_id, versiya_nomresi, fayl_yolu, deyisiklik_qeydi, deyisen) VALUES
((SELECT sened_id FROM sened.sened WHERE nomre='SM-2026-045'), 1, '/senedler/smeta/L-2026-001_smeta_v1.pdf', 'İlkin smeta təqdim edildi', 1),
((SELECT sened_id FROM sened.sened WHERE nomre='SM-2026-045'), 2, '/senedler/smeta/L-2026-001_smeta_v2.pdf', 'Qiymətlər yeniləndi, qüvvəyə mindi', 1),
((SELECT sened_id FROM sened.sened WHERE nomre='TS-2026-003'), 1, '/senedler/tender/L-2026-002_senedler.pdf', 'İlkin tender sənədləri hazırlandı', 1),
((SELECT sened_id FROM sened.sened WHERE nomre='PR-2026-005'), 1, '/senedler/protokol/L-2026-002_protokol.pdf', 'Protokolun layihəsi yaradıldı', 1),
((SELECT sened_id FROM sened.sened WHERE nomre='RB-2026-002'), 1, NULL, 'Rüblük hesabatın ilkin variantı', 1)
ON CONFLICT (sened_id, versiya_nomresi) DO NOTHING;

-- ---------------------------------------------------------------------
--  sened.tesdiq — Sənəd təsdiqləri
--  Qeyd: trg_tesdiq_emeliyyat status='tesdiqlendi' olduqda sənədin
--  statusunu avtomatik yeniləyir.
-- ---------------------------------------------------------------------
INSERT INTO sened.tesdiq (sened_id, tesdiq_eden, vezife, status, rey, tesdiq_tarixi) VALUES
((SELECT sened_id FROM sened.sened WHERE nomre='SM-2026-045'), 1, 'Layihə rəhbəri', 'tesdiqlendi', 'Smeta təsdiq olundu', '2026-03-06 10:30:00+04'),
((SELECT sened_id FROM sened.sened WHERE nomre='IA-2026-011'), 2, 'Mühəndis-tikintiçi', 'tesdiqlendi', 'Mart icra aktı təsdiqləndi', '2026-04-06 09:00:00+04'),
((SELECT sened_id FROM sened.sened WHERE nomre='TS-2026-003'), NULL, NULL, 'golecek', 'Baxılır', NULL),
((SELECT sened_id FROM sened.sened WHERE nomre='MK-2026-009'), 1, 'Layihə rəhbəri', 'tesdiqlendi', 'Məktub təsdiqləndi', '2026-08-21 14:00:00+04'),
((SELECT sened_id FROM sened.sened WHERE nomre='TA-2026-031'), 2, 'Mühəndis-tikintiçi', 'tesdiqlendi', 'Texniki akt qəbul olundu', '2026-05-21 11:00:00+04')
ON CONFLICT DO NOTHING;

-- =====================================================================
--  risk SXEMİ — RİSK İDARƏETMƏSİ
-- =====================================================================

-- ---------------------------------------------------------------------
--  risk.risk — Risk qeydləri
--  Qeyd: derece kolonu GENERATED STORED-dur — avtomatik hesablanır,
--  ona yazılmır!
-- ---------------------------------------------------------------------
INSERT INTO risk.risk (layihe_id, risk_novu, tesvir, ehtimal, tesir, sahibi, mitedaxile_plani, status) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'maliyye',
 'Material qiymətlərinin artması büdcəni aşa bilər', 60, 70, 5,
 'Alternativ təchizatçılarla opsion müqavilə bağlamaq', 'aktiv'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'hava',
 'Payız yağışları suvaq işlərini ləngidə bilər', 55, 40, 2,
 'Yağışa davamlı örtükdən istifadə və iş qrafikinin dəyişdirilməsi', 'nezaretde'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), 'texniki',
 'Torpaq şəraitinə uyğunsuzluq təməl işlərini çətinləşdirə bilər', 40, 80, 2,
 'Əlavə geoloji tədqiqat işlərinin aparılması', 'aktiv'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), 'tedaruk',
 'Sement tədarükündə gecikmə müddəti uzada bilər', 50, 60, 5,
 'Sement ehtiyatının ilkin yaradılması', 'aktiv'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'), 'kadr',
 'Mövsümi işçi çatışmazlığı işin sürətini azalda bilər', 45, 50, 7,
 'Mövsümi işçilərin erkən cəlb edilməsi', 'nezaretde'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 'hava',
 'Yaz aylarında güclü külək dam işlərini dayandıra bilər', 30, 55, 7,
 'Küləkli günlər üçün ehtiyat iş qrafiki', 'qapanib'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'), 'tehlike',
 'Sanitar qovşaqların sökülməsində işçi zədələnmə riski', 35, 65, 2,
 'İşçilərə əlavə təhlükəsizlik təlimi keçirmək', 'aktiv'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'huquqi',
 'Qonşu ərazidən şikayət əsasında işin dayandırılması', 20, 70, 1,
 'İcazə sənədlərinin yenilənməsi və ərazi ilə əlaqə', 'aktiv')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  risk.risk_mitedaxile — Risk müdaxilələri
-- ---------------------------------------------------------------------
INSERT INTO risk.risk_mitedaxile (risk_id, tesvir, mezul_isci, plan_tarix, real_tarix, effektiv) VALUES
((SELECT risk_id FROM risk.risk WHERE risk_novu='maliyye' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001')),
 'Alternativ təchizatçılarla qiymət danışıqları', (SELECT isci_id FROM kadr.isci WHERE fin='FIN005'), '2026-04-01', '2026-04-15', 80.00),
((SELECT risk_id FROM risk.risk WHERE risk_novu='texniki' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002')),
 'Əlavə geoloji tədqiqat işlərinin aparılması', (SELECT isci_id FROM kadr.isci WHERE fin='FIN002'), '2026-09-10', NULL, NULL),
((SELECT risk_id FROM risk.risk WHERE risk_novu='kadr' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003')),
 'Mövsümi işçilərin erkən cəlb edilməsi', (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), '2026-08-01', '2026-08-10', 60.00),
((SELECT risk_id FROM risk.risk WHERE risk_novu='tedaruk' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002')),
 'Sement ehtiyatının ilkin yaradılması', (SELECT isci_id FROM kadr.isci WHERE fin='FIN005'), '2026-09-01', NULL, NULL),
((SELECT risk_id FROM risk.risk WHERE risk_novu='tehlike' AND layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005')),
 'İşçilərə təhlükəsizlik təliminin keçirilməsi', (SELECT isci_id FROM kadr.isci WHERE fin='FIN002'), '2026-07-01', '2026-07-05', 90.00)
ON CONFLICT DO NOTHING;

-- =====================================================================
--  keyfiyyet SXEMİ — KEYFİYYƏTƏ NƏZARƏT
-- =====================================================================

-- ---------------------------------------------------------------------
--  keyfiyyet.yoxlama — Keyfiyyət yoxlamaları
-- ---------------------------------------------------------------------
INSERT INTO keyfiyyet.yoxlama (layihe_id, merhele_id, yoxlama_novu, yoxlayan, tarix, netice, qeyd) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001') AND ad='İzolyasiya işləri'),
 'keyfiyyet', (SELECT isci_id FROM kadr.isci WHERE fin='FIN002'), '2026-05-15', 'kecdi',
 'İzolyasiya işləri norma üzrə aparılıb'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001') AND ad='Suvaq işləri'),
 'texniki', (SELECT isci_id FROM kadr.isci WHERE fin='FIN002'), '2026-06-20', 'yeniden_yoxlama',
 'Suvaqda çatlar aşkar edildi, yenidən yoxlama tələb olunur'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004') AND ad='Yeni örtük və izolyasiya'),
 'texniki', (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), '2026-05-20', 'kecdi',
 'Dam örtüyü qüsursuz, ölçülər normaya uyğundur'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004') AND ad='Sistemlərin quraşdırılması'),
 'ekoloji', (SELECT isci_id FROM kadr.isci WHERE fin='FIN003'), '2026-06-20', 'kecdi',
 'Tullantıların yığılması və çıxarılması qaydalara uyğundur'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'),
 NULL,
 'tehlike', (SELECT isci_id FROM kadr.isci WHERE fin='FIN003'), '2026-06-10', 'qeyri_kafi',
 'Sanitar qovşaqda fəhlələrin qoruyucu vasitələrlə təminatı zəifdir'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001') AND ad='Skele (iskala) və hazırlıq işləri'),
 'texniki', (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), '2026-03-25', 'kecdi',
 'İskala quraşdırılması təhlükəsizlik tələblərinə cavab verir'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'),
 NULL,
 'keyfiyyet', (SELECT isci_id FROM kadr.isci WHERE fin='FIN001'), '2026-08-20', 'golecek',
 'Təməl işlərindən əvvəl ilkin yoxlama planlaşdırılıb')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  keyfiyyet.qusur — Qüsurlar
-- ---------------------------------------------------------------------
INSERT INTO keyfiyyet.qusur (yoxlama_id, tesvir, ciddilik, status, duzelis_plan_tarix, duzelis_real_tarix) VALUES
((SELECT yoxlama_id FROM keyfiyyet.yoxlama WHERE qeyd='Suvaqda çatlar aşkar edildi, yenidən yoxlama tələb olunur'),
 'Suvaq səthində çatlar', 'orta', 'duzelisde', '2026-06-30', NULL),
((SELECT yoxlama_id FROM keyfiyyet.yoxlama WHERE qeyd='Sanitar qovşaqda fəhlələrin qoruyucu vasitələrlə təminatı zəifdir'),
 'Qoruyucu vasitələrin olmaması', 'yuksek', 'aciq', '2026-07-01', NULL),
((SELECT yoxlama_id FROM keyfiyyet.yoxlama WHERE qeyd='İzolyasiya işləri norma üzrə aparılıb'),
 'İzolyasiya təbəqəsinin qalınlığı normadan aşağıdır', 'asagi', 'baglanib', '2026-05-20', '2026-05-22'),
((SELECT yoxlama_id FROM keyfiyyet.yoxlama WHERE qeyd='Dam örtüyü qüsursuz, ölçülər normaya uyğundur'),
 'Bir neçə dam panelində cızıqlar', 'asagi', 'baglanib', '2026-05-25', '2026-05-26'),
((SELECT yoxlama_id FROM keyfiyyet.yoxlama WHERE qeyd='Suvaqda çatlar aşkar edildi, yenidən yoxlama tələb olunur'),
 'Pəncərə yamaclarında qeyri-bərabər suvaq', 'orta', 'aciq', '2026-07-05', NULL)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  keyfiyyet.qebul_akt — Qəbul aktları
-- ---------------------------------------------------------------------
INSERT INTO keyfiyyet.qebul_akt (layihe_id, merhele_id, nomre, tarix, status, qeyd) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001') AND ad='Skele (iskala) və hazırlıq işləri'),
 'QA-2026-001', '2026-03-25', 'tesdiqlendi', 'Skele və hazırlıq işləri qəbul edildi'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004') AND ad='Köhnə örtüyün sökülməsi'),
 'QA-2026-002', '2026-02-05', 'tesdiqlendi', 'Köhnə örtüyün sökülməsi başa çatdı'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004') AND ad='Yeni örtük və izolyasiya'),
 'QA-2026-003', '2026-05-20', 'tesdiqde', 'Yeni örtük qəbulu prosesi'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'),
 (SELECT merhele_id FROM layihe.layihe_merhele WHERE layihe_id=(SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001') AND ad='İzolyasiya işləri'),
 'QA-2026-004', '2026-05-15', 'tesdiqlendi', 'İzolyasiya işləri qəbul edildi'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'),
 NULL,
 'QA-2026-005', '2026-08-25', 'qaralama', 'Dəhliz təmiri qəbul aktının layihəsi')
ON CONFLICT DO NOTHING;

-- =====================================================================
--  logistika SXEMİ — MATERIAL LOGİSTİKASI VƏ ANBAR
-- =====================================================================

-- ---------------------------------------------------------------------
--  logistika.anbar — Anbarlar
-- ---------------------------------------------------------------------
INSERT INTO logistika.anbar (ad, seher_id, unvan, mesul_isci, aktif) VALUES
('Mərkəzi Anbar', (SELECT seher_id FROM ref.seher WHERE ad='Bakı'), 'Bakı, Binəqədi r., Sənaye qəsəbəsi', (SELECT isci_id FROM kadr.isci WHERE fin='FIN005'), TRUE),
('Qərb Anbarı',   (SELECT seher_id FROM ref.seher WHERE ad='Gəncə'), 'Gəncə, Sənaye zonası, 3-cü küçə', (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), TRUE),
('Şimal Anbarı',  (SELECT seher_id FROM ref.seher WHERE ad='Sumqayıt'), 'Sumqayıt, Kimyaçılar prospekti, 15', (SELECT isci_id FROM kadr.isci WHERE fin='FIN005'), TRUE)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  logistika.tedarukcu — Təchizatçılar
-- ---------------------------------------------------------------------
INSERT INTO logistika.tedarukcu (ad, voen, elaqe_shexs, telefon, email, unvan, reyting, aktif) VALUES
('AZMAT-TİKİNTİ MMC',     '8100000001', 'İlham Qəhrəmanov', '+994 50 234 56 01', 'info@azmattikinti.az', 'Bakı, Əhmədli qəsəbəsi', 4.50, TRUE),
('BETON-SERVİS MMC',      '8100000002', 'Rəşad Qasımov',    '+994 55 234 56 02', 'sifaris@betonservis.az', 'Sumqayıt, Sənaye qəsəbəsi', 4.20, TRUE),
('TİKƏM-MATERİAL MMC',    '8100000003', 'Emin Səfərov',     '+994 70 234 56 03', 'satis@tikem.az', 'Gəncə, Sənaye zonası', 3.80, TRUE),
('QAFQAZ TAĞTA MMC',      '8100000004', 'Zaur Həsənov',     '+994 51 234 56 04', 'info@qafqaztagta.az', 'Bakı, Qaradağ r.', 4.00, TRUE),
('ELEKTRA-SAN MMC',       '8100000005', 'Kənan Məlikov',    '+994 55 234 56 05', 'sales@elektra.az', 'Bakı, Yasamal r.', 4.70, TRUE),
('BOYAQ-MİX MMC',         '8100000006', 'Tərlan Ağayev',    '+994 50 234 56 06', 'info@boyaqmix.az', 'Gəncə, Nizami küç.', 4.10, TRUE)
ON CONFLICT (voen) DO NOTHING;

-- ---------------------------------------------------------------------
--  logistika.material_hereket — Material hərəkətləri
-- ---------------------------------------------------------------------
INSERT INTO logistika.material_hereket (anbar_id, material_novu_id, hereket_novu, miqdar, vahid, tarix, sened_id, layihe_id, icraci, qeyd) VALUES
((SELECT anbar_id FROM logistika.anbar WHERE ad='Mərkəzi Anbar'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-01'), 'daxil', 500, 'kq', '2026-03-20 10:00:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 5, 'Akril boyaq partiyası anbara qəbul edildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Mərkəzi Anbar'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-02'), 'daxil', 6000, 'kq', '2026-03-22 11:30:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 5, 'Suvac qarışığı anbara qəbul edildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Mərkəzi Anbar'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-01'), 'cixar', 300, 'kq', '2026-04-10 09:00:00+04',
 (SELECT sened_id FROM sened.sened WHERE nomre='IA-2026-011'),
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 2, 'Fasad işlərinə akril boyaq verildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Mərkəzi Anbar'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-02'), 'cixar', 4500, 'kq', '2026-04-12 14:00:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 2, 'Suvaq işlərinə qarışıq verildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Qərb Anbarı'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='SB-01'), 'daxil', 120, 't', '2026-08-25 09:30:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), 5, 'Portland sement partiyası qəbul edildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Qərb Anbarı'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='KR-01'), 'daxil', 50000, 'ədəd', '2026-08-26 10:00:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), 5, 'Tikinti kərpici qəbul edildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Qərb Anbarı'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='SB-01'), 'cixar', 80, 't', '2026-08-28 08:00:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), 2, 'Təməl işlərinə sement verildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Şimal Anbarı'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='DM-02'), 'daxil', 3100, 'm²', '2026-02-15 13:00:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 5, 'Buruq örtük anbara qəbul edildi'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Mərkəzi Anbar'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='DM-01'), 'transfer', 500, 'm²', '2026-03-05 15:30:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 5, 'Şimal anbarından Mərkəzi anbara transfer'),
((SELECT anbar_id FROM logistika.anbar WHERE ad='Mərkəzi Anbar'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-01'), 'cixar', 120, 'kq', '2026-08-20 12:00:00+04', NULL,
 (SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'), 2, 'Gimnaziya dəhliz təmirinə boyaq verildi')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  logistika.catdirilma — Çatdırılmalar
-- ---------------------------------------------------------------------
INSERT INTO logistika.catdirilma (tedarukcu_id, material_novu_id, miqdar, vahid, qiymet, plan_tarix, real_tarix, status, qeyd) VALUES
((SELECT tedarukcu_id FROM logistika.tedarukcu WHERE voen='8100000001'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='SB-01'), 120, 't', 25200.00, '2026-08-30', NULL, 'yolda', 'Sement yük maşını ilə yoldadır'),
((SELECT tedarukcu_id FROM logistika.tedarukcu WHERE voen='8100000004'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='DM-02'), 3100, 'm²', 82150.00, '2026-02-10', '2026-02-15', 'catdirildi', 'Buruq örtük vaxtında çatdırıldı'),
((SELECT tedarukcu_id FROM logistika.tedarukcu WHERE voen='8100000003'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='KR-01'), 50000, 'ədəd', 22500.00, '2026-09-05', NULL, 'planlasdirilib', 'Kərpic sifarişi planlaşdırılıb'),
((SELECT tedarukcu_id FROM logistika.tedarukcu WHERE voen='8100000006'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-01'), 850, 'kq', 10030.00, '2026-03-01', '2026-03-10', 'geqikdi', 'Çatdırılma 9 gün gecikdi'),
((SELECT tedarukcu_id FROM logistika.tedarukcu WHERE voen='8100000002'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='SB-02'), 350, 'm³', 42000.00, '2026-09-01', NULL, 'yolda', 'Beton qarışığı sifariş edilib'),
((SELECT tedarukcu_id FROM logistika.tedarukcu WHERE voen='8100000006'),
 (SELECT material_novu_id FROM ref.material_novu WHERE kod='BM-02'), 6000, 'kq', 4680.00, '2026-04-01', '2026-04-05', 'catdirildi', 'Suvac qarışığı çatdırıldı')
ON CONFLICT DO NOTHING;

-- =====================================================================
--  tehlike SXEMİ — ƏMƏK TƏHLÜKƏSİZLİYİ
-- =====================================================================

-- ---------------------------------------------------------------------
--  tehlike.olay — Hadisələr
-- ---------------------------------------------------------------------
INSERT INTO tehlike.olay (layihe_id, olay_novu, tarix, ciddilik, tesvir, tesevver_eden, status) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), 'zedelenme', '2026-04-12 09:30:00+04', 'orta',
 'İskalada işləyən fəhlə ayağından zədələnib, ilk yardım göstərilib', (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), 'baglanib'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'), 'xsst_insident', '2026-06-18 12:00:00+04', 'asagi',
 'Fəhlələr arasında yüngül qida zəhərlənməsi hadisəsi', (SELECT isci_id FROM kadr.isci WHERE fin='FIN003'), 'arashdirilir'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), 'ekoloji', '2026-08-15 16:00:00+04', 'yuksek',
 'Tikinti sahəsində tikinti tullantılarının qaydasız atılması aşkar edilib', (SELECT isci_id FROM kadr.isci WHERE fin='FIN001'), 'aciq'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), 'yangin', '2026-04-28 14:20:00+04', 'kritik',
 'Qaynaq işləri zamanı yanğın təhlükəsi yaranıb, vaxtında söndürülüb', (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), 'baglanib'),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-003'), 'zedelenme', '2026-08-22 11:45:00+04', 'orta',
 'Material daşınarkən fəhlənin əli zədələnib', (SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), 'arashdirilir')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  tehlike.yoxlama — Təhlükəsizlik yoxlamaları
-- ---------------------------------------------------------------------
INSERT INTO tehlike.yoxlama (layihe_id, tarix, netice, tapinti, yoxlayan) VALUES
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), '2026-04-10', 'kecdi',
 'İş yeri ümumi təhlükəsizlik tələblərinə cavab verir', (SELECT isci_id FROM kadr.isci WHERE fin='FIN002')),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-002'), '2026-08-20', 'qeyri_kafi',
 'Təhlükəsizlik dəbilqələri ilə təminat zəifdir, işçilər xəbərdar edilib', (SELECT isci_id FROM kadr.isci WHERE fin='FIN003')),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-004'), '2026-03-15', 'kecdi',
 'Hündürlükdə işlər təhlükəsizlik kəməri ilə aparılır', (SELECT isci_id FROM kadr.isci WHERE fin='FIN002')),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-005'), '2026-07-05', 'kecdi',
 'Sanitar qovşaqlarda işıqlandırma və havalandırma normadadır', (SELECT isci_id FROM kadr.isci WHERE fin='FIN003')),
((SELECT layihe_id FROM layihe.layihe WHERE kod='L-2026-001'), '2026-07-25', 'golecek',
 'Növbəti rüblük təhlükəsizlik yoxlaması planlaşdırılıb', (SELECT isci_id FROM kadr.isci WHERE fin='FIN002'))
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  tehlike.telim — Təlimlər
-- ---------------------------------------------------------------------
INSERT INTO tehlike.telim (isci_id, movzu, tarix, sertifikat, etibarliliq_sonu, kechdi, qeyd) VALUES
((SELECT isci_id FROM kadr.isci WHERE fin='FIN007'), 'Hündürlükdə işlərin təhlükəsizliyi', '2026-03-10', 'SERT-2026-001', '2027-03-10', TRUE, 'İllik keçirilən təlim'),
((SELECT isci_id FROM kadr.isci WHERE fin='FIN002'), 'İlk yardım və təcili tibbi yardım qaydaları', '2026-02-20', 'SERT-2026-002', '2027-02-20', TRUE, 'Praktiki məşğələ keçirildi'),
((SELECT isci_id FROM kadr.isci WHERE fin='FIN008'), 'Yanğın təhlükəsizliyi', '2026-04-05', 'SERT-2026-003', '2027-04-05', TRUE, 'Yanğınsöndürən cihazlarla istifadə təlimi'),
((SELECT isci_id FROM kadr.isci WHERE fin='FIN003'), 'Ekoloji normalar və tullantı idarəetməsi', '2026-05-15', 'SERT-2026-004', '2027-05-15', FALSE, 'İmtahan verilməyib, təkrar təlim tələb olunur'),
((SELECT isci_id FROM kadr.isci WHERE fin='FIN005'), 'Tikinti materiallarının təhlükəsiz daşınması', '2026-06-10', 'SERT-2026-005', '2027-06-10', TRUE, 'Anbar işçiləri üçün təlim'),
((SELECT isci_id FROM kadr.isci WHERE fin='FIN001'), 'Əməyin mühafizəsi üzrə yenidənhazırlıq', '2026-08-01', NULL, NULL, TRUE, 'Yenidənhazırlıq başa çatıb')
ON CONFLICT DO NOTHING;

-- =====================================================================
--  audit SXEMİ — AUDİT VƏ SİSTEM QEYDLƏRİ
-- =====================================================================

-- ---------------------------------------------------------------------
--  audit.audit_log — Nümunə audit qeydləri (əl ilə INSERT)
--  Qeyd: triggerlər də avtomatik qeyd yaradır, bura əlavə nümunədir.
-- ---------------------------------------------------------------------
INSERT INTO audit.audit_log (sxem, cedvel, qeyd_id, emeliyyat, kohne_deyer, yeni_deyer, istifadeci_id, ip) VALUES
('layihe', 'layihe', 1, 'INSERT', NULL,
 '{"layihe_id": 1, "kod": "L-2026-001", "plan_budce": 850000, "status_id": 3}'::jsonb, 1, '10.0.0.15'),
('layihe', 'layihe', 1, 'UPDATE',
 '{"status_id": 1}'::jsonb,
 '{"status_id": 3}'::jsonb, 1, '10.0.0.15'),
('kadr', 'isci', 5, 'UPDATE',
 '{"isci_id": 5, "status": "aktiv"}'::jsonb,
 '{"isci_id": 5, "status": "aktiv", "maas": 2200}'::jsonb, 2, '10.0.0.22'),
('satinalma', 'tender', 1, 'UPDATE',
 '{"tender_id": 1, "status_id": 3}'::jsonb,
 '{"tender_id": 1, "status_id": 4, "qalib_istirakci_id": 1}'::jsonb, 1, '10.0.0.15')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  audit.sistem_log — Sistem loqları
-- ---------------------------------------------------------------------
INSERT INTO audit.sistem_log (seviyye, menbe, mesaj, kontekst) VALUES
('info', 'sistem', 'ERP sistemi işə salındı', '{"versiya": "v5", "modul": "kernel"}'::jsonb),
('warn', 'budce_nezaret', 'Layihə L-2026-005 (5) büdcə həddini aşır: plan=240000, toplam xərc=245500', '{"layihe_id": 5}'::jsonb),
('error', 'login', 'Giriş cəhdi uğursuz oldu: şifrə səhv daxil edildi', '{"istifadeci_ad": "ramin.eliyev"}'::jsonb),
('info', 'backup', 'Gündəlik ehtiyat nüsxə uğurla yaradıldı', '{"fayl": "backup_20260825.dump", "olcu_mb": 128}'::jsonb)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
--  audit.giris_log — Giriş qeydləri
-- ---------------------------------------------------------------------
INSERT INTO audit.giris_log (istifadeci_id, istifadeci_ad, ip, success) VALUES
(1, 'elcin.memmedov', '10.0.0.15', TRUE),
(2, 'ramin.eliyev',   '10.0.0.22', FALSE),
(1, 'elcin.memmedov', '10.0.0.15', FALSE),
(3, 'nigar.quliyeva', '10.0.0.31', TRUE),
(2, 'ramin.eliyev',   '10.0.0.22', TRUE)
ON CONFLICT DO NOTHING;

COMMIT;
