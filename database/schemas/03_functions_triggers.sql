-- =====================================================================
--  DeepSeek-4 ERP v5 — Funksiyalar və Triggerlər
--  Tarix: 2026-08-25
-- =====================================================================

BEGIN;

-- =====================================================================
--  KÖMƏKÇİ FUNKSİYALAR
-- =====================================================================

-- updated_at avtomatik yenilənməsi üçün ümumi funksiya
CREATE OR REPLACE FUNCTION ref.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Mətnin axtarış üçün normallaşdırılması (azərbaycan hərfləri ilə)
CREATE OR REPLACE FUNCTION ref.normalize_text(t TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN lower(translate(t, 'ƏəÖöÜüÇçŞşIİ', 'AaOoUuCcSsIi'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================
--  BİZNES FUNKSİYALARI
-- =====================================================================

-- Layihənin mərhələlər üzrə orta progressi (%)
CREATE OR REPLACE FUNCTION layihe.layihe_progres(p_layihe_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_progres NUMERIC(5,2);
BEGIN
    SELECT COALESCE(AVG(real_faiz), 0)
    INTO v_progres
    FROM layihe.layihe_merhele
    WHERE layihe_id = p_layihe_id;
    RETURN ROUND(v_progres, 2);
END;
$$ LANGUAGE plpgsql;

-- Layihə üzrə ümumi xərc
CREATE OR REPLACE FUNCTION maliyye.layihe_umumi_xerc(p_layihe_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_toplam NUMERIC(14,2);
BEGIN
    SELECT COALESCE(SUM(mebleg), 0)
    INTO v_toplam
    FROM maliyye.xerc
    WHERE layihe_id = p_layihe_id;
    RETURN v_toplam;
END;
$$ LANGUAGE plpgsql;

-- Layihə büdcəsinin istifadə faizi
CREATE OR REPLACE FUNCTION maliyye.layihe_budce_istifade(p_layihe_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_faiz NUMERIC(5,2);
    v_plan NUMERIC(14,2);
    v_xerc NUMERIC(14,2);
BEGIN
    SELECT plan_budce INTO v_plan FROM layihe.layihe WHERE layihe_id = p_layihe_id;
    v_xerc := maliyye.layihe_umumi_xerc(p_layihe_id);
    IF v_plan IS NULL OR v_plan = 0 THEN
        RETURN 0;
    END IF;
    v_faiz := ROUND(100.0 * v_xerc / v_plan, 2);
    RETURN LEAST(v_faiz, 999.99);
END;
$$ LANGUAGE plpgsql;

-- Müqavilə üzrə qalıq borc
CREATE OR REPLACE FUNCTION maliyye.muqavile_borcu(p_muqavile_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_borc NUMERIC(14,2);
BEGIN
    SELECT m.mebleg - COALESCE(SUM(o.mebleg), 0)
    INTO v_borc
    FROM satinalma.muqavile m
    LEFT JOIN maliyye.odenis o ON o.muqavile_id = m.muqavile_id
    WHERE m.muqavile_id = p_muqavile_id
    GROUP BY m.muqavile_id;
    RETURN COALESCE(v_borc, 0);
END;
$$ LANGUAGE plpgsql;

-- Tenderin qənaət məbləği (elan həddi - qalib təklif)
CREATE OR REPLACE FUNCTION satinalma.tender_qenayeti(p_tender_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_qenayet NUMERIC(14,2);
BEGIN
    SELECT t.qiymet_serhedi - ti.teklif_mebleg
    INTO v_qenayet
    FROM satinalma.tender t
    JOIN satinalma.tender_istirakci ti
      ON ti.tender_id = t.tender_id AND ti.qalib = TRUE
    WHERE t.tender_id = p_tender_id;
    RETURN COALESCE(v_qenayet, 0);
END;
$$ LANGUAGE plpgsql;

-- Risk dərəcəsinin hesablanması (ehtimal × təsir / 100)
CREATE OR REPLACE FUNCTION risk.risk_derecesi(p_ehtimal NUMERIC, p_tesir NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_ehtimal * p_tesir / 100, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Layihə üzrə kadr xərci (təyinat üzrə günlük məbləğ × gün sayı)
CREATE OR REPLACE FUNCTION kadr.layihe_kadr_deyeri(p_layihe_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_deyer NUMERIC(14,2);
BEGIN
    SELECT COALESCE(SUM(
        gunelik_mebleg * COALESCE(
            (COALESCE(son_tarix, CURRENT_DATE) - COALESCE(bashlama_tarixi, CURRENT_DATE)),
            0
        )
    ), 0)
    INTO v_deyer
    FROM kadr.layihe_isci_teyinat
    WHERE layihe_id = p_layihe_id;
    RETURN v_deyer;
END;
$$ LANGUAGE plpgsql;

-- AI proqnoz funksiyası: büdcə sapması proqnozu
-- Sadə model: cari progressə görə son xərcin proqnozu
CREATE OR REPLACE FUNCTION ai.ai_plan_budce_prognozu(p_layihe_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_plan NUMERIC(14,2);
    v_xerc NUMERIC(14,2);
    v_progres NUMERIC(5,2);
    v_prognoz NUMERIC(14,2);
BEGIN
    SELECT plan_budce INTO v_plan FROM layihe.layihe WHERE layihe_id = p_layihe_id;
    v_xerc := maliyye.layihe_umumi_xerc(p_layihe_id);
    v_progres := layihe.layihe_progres(p_layihe_id);
    IF v_progres <= 0 THEN
        v_prognoz := v_plan;  -- hələ başlanmayıb
    ELSE
        -- Cari xərc / progress → tamamlanmış proqnoz
        v_prognoz := ROUND(v_xerc * 100.0 / v_progres, 2);
    END IF;
    RETURN v_prognoz;
END;
$$ LANGUAGE plpgsql;

-- Aylıq maliyyə hesabatı (xərc vs ödəniş)
CREATE OR REPLACE FUNCTION hesabat.ayliq_maliyye_hesabati(p_ay DATE)
RETURNS TABLE(ay_adi TEXT, xerc_mebleg NUMERIC, odenis_mebleg NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(p_ay, 'YYYY-MM'),
        (SELECT COALESCE(SUM(mebleg), 0) FROM maliyye.xerc
         WHERE TO_CHAR(tarix, 'YYYY-MM') = TO_CHAR(p_ay, 'YYYY-MM')),
        (SELECT COALESCE(SUM(mebleg), 0) FROM maliyye.odenis
         WHERE TO_CHAR(tarix, 'YYYY-MM') = TO_CHAR(p_ay, 'YYYY-MM'));
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
--  AUDİT TRIGGER FUNKSİYASI (ümumi)
-- =====================================================================
CREATE OR REPLACE FUNCTION audit.audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    old_json JSONB := NULL;
    new_json JSONB := NULL;
    rec_id INTEGER := NULL;
    k TEXT;
BEGIN
    IF TG_OP IN ('UPDATE','DELETE') THEN old_json := to_jsonb(OLD); END IF;
    IF TG_OP IN ('INSERT','UPDATE') THEN new_json := to_jsonb(NEW); END IF;

    -- Əsas açarı tap (ilk '_id' ilə bitən açar, parent_id istisna)
    FOR k IN SELECT jsonb_object_keys(COALESCE(new_json, old_json)) LOOP
        IF k LIKE '%\_id' AND k NOT IN ('parent_id','teyinat_id','istirakci_id') THEN
            BEGIN
                rec_id := (COALESCE(new_json, old_json) ->> k)::INTEGER;
                EXIT;
            EXCEPTION WHEN OTHERS THEN
                CONTINUE;
            END;
        END IF;
    END LOOP;

    INSERT INTO audit.audit_log (sxem, cedvel, qeyd_id, emeliyyat, kohne_deyer, yeni_deyer)
    VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, rec_id, TG_OP, old_json, new_json);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
--  TRIGGERLƏR
-- =====================================================================

-- 1) updated_at avtomatik yenilənməsi
CREATE TRIGGER trg_region_uat BEFORE UPDATE ON ref.region
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_seher_uat BEFORE UPDATE ON ref.seher
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_muessise_novu_uat BEFORE UPDATE ON ref.muessise_novu
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_muessise_uat BEFORE UPDATE ON ref.muessise
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_is_novu_uat BEFORE UPDATE ON ref.is_novu
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_material_novu_uat BEFORE UPDATE ON ref.material_novu
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_layihe_uat BEFORE UPDATE ON layihe.layihe
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_tender_uat BEFORE UPDATE ON satinalma.tender
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_muqavile_uat BEFORE UPDATE ON satinalma.muqavile
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_isci_uat BEFORE UPDATE ON kadr.isci
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_vezife_uat BEFORE UPDATE ON kadr.vezife
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_ai_model_uat BEFORE UPDATE ON ai.ai_model
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_ai_agent_uat BEFORE UPDATE ON ai.ai_agent
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_ai_teyinat_uat BEFORE UPDATE ON ai.ai_teyinat
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_risk_uat BEFORE UPDATE ON risk.risk
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_sened_uat BEFORE UPDATE ON sened.sened
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_tedarukcu_uat BEFORE UPDATE ON logistika.tedarukcu
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();
CREATE TRIGGER trg_anbar_uat BEFORE UPDATE ON logistika.anbar
    FOR EACH ROW EXECUTE FUNCTION ref.set_updated_at();

-- 2) Audıt: kritik cədvəllərdə dəyişikliklərin izlənməsi
CREATE TRIGGER trg_audit_layihe AFTER INSERT OR UPDATE OR DELETE ON layihe.layihe
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();
CREATE TRIGGER trg_audit_isci AFTER INSERT OR UPDATE OR DELETE ON kadr.isci
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();
CREATE TRIGGER trg_audit_xerc AFTER INSERT OR UPDATE OR DELETE ON maliyye.xerc
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();
CREATE TRIGGER trg_audit_muqavile AFTER INSERT OR UPDATE OR DELETE ON satinalma.muqavile
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();
CREATE TRIGGER trg_audit_tender AFTER INSERT OR UPDATE OR DELETE ON satinalma.tender
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();
CREATE TRIGGER trg_audit_odenis AFTER INSERT OR UPDATE OR DELETE ON maliyye.odenis
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();
CREATE TRIGGER trg_audit_muessise AFTER INSERT OR UPDATE OR DELETE ON ref.muessise
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();
CREATE TRIGGER trg_audit_ai_teyinat AFTER INSERT OR UPDATE OR DELETE ON ai.ai_teyinat
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_func();

-- 3) Tender qalib müəyyən ediləndə avtomatik yenilənmə
CREATE OR REPLACE FUNCTION satinalma.tender_qalib_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.qalib = TRUE THEN
        UPDATE satinalma.tender
        SET qalib_istirakci_id = NEW.istirakci_id,
            status_id = (SELECT status_id FROM satinalma.tender_status WHERE kod = 'qalib')
        WHERE tender_id = NEW.tender_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tender_qalib AFTER INSERT OR UPDATE OF qalib ON satinalma.tender_istirakci
    FOR EACH ROW EXECUTE FUNCTION satinalma.tender_qalib_trigger_func();

-- 4) Xərc büdcə həddini aşanda xəbərdarlıq (sistem loguna yaz)
CREATE OR REPLACE FUNCTION maliyye.xerc_budce_nezaret_func()
RETURNS TRIGGER AS $$
DECLARE
    v_plan NUMERIC(14,2);
    v_toplam NUMERIC(14,2);
    v_layihe_kod VARCHAR(30);
BEGIN
    SELECT plan_budce, kod INTO v_plan, v_layihe_kod
    FROM layihe.layihe WHERE layihe_id = NEW.layihe_id;

    SELECT COALESCE(SUM(mebleg), 0) INTO v_toplam
    FROM maliyye.xerc WHERE layihe_id = NEW.layihe_id;

    v_toplam := v_toplam + NEW.mebleg;

    IF v_plan IS NOT NULL AND v_plan > 0 AND v_toplam > v_plan THEN
        INSERT INTO audit.sistem_log (seviyye, menbe, mesaj, kontekst)
        VALUES ('warn', 'budce_nezaret',
                format('Layihə %s (%s) büdcə həddini aşır: plan=%s, toplam xərc=%s',
                       v_layihe_kod, NEW.layihe_id, v_plan, v_toplam),
                jsonb_build_object('layihe_id', NEW.layihe_id, 'yeni_xerc', NEW.mebleg));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_xerc_budce_nezaret AFTER INSERT ON maliyye.xerc
    FOR EACH ROW EXECUTE FUNCTION maliyye.xerc_budce_nezaret_func();

-- 5) Mərhələ progressi dəyişdikdə layihənin ümumi progressini yenilə
CREATE OR REPLACE FUNCTION layihe.merhele_progres_func()
RETURNS TRIGGER AS $$
DECLARE
    v_layihe_id INTEGER;
    v_progres NUMERIC(5,2);
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_layihe_id := OLD.layihe_id;
    ELSE
        v_layihe_id := NEW.layihe_id;
    END IF;
    v_progres := layihe.layihe_progres(v_layihe_id);
    UPDATE layihe.layihe SET progres = v_progres WHERE layihe_id = v_layihe_id;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_merhele_progres AFTER INSERT OR UPDATE OR DELETE ON layihe.layihe_merhele
    FOR EACH ROW EXECUTE FUNCTION layihe.merhele_progres_func();

-- 6) İşçi işdən ayrıldıqda status passiv olur
CREATE OR REPLACE FUNCTION kadr.isci_status_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.isden_ayrilma IS NOT NULL THEN
        NEW.status := 'passiv';
    ELSE
        NEW.status := 'aktiv';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_isci_status BEFORE UPDATE OF isden_ayrilma ON kadr.isci
    FOR EACH ROW EXECUTE FUNCTION kadr.isci_status_func();

-- 7) Sənəd yeniləndikdə versiya avtomatik artır
CREATE OR REPLACE FUNCTION sened.sened_versiya_func()
RETURNS TRIGGER AS $$
BEGIN
    NEW.versiya := OLD.versiya + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sened_versiya BEFORE UPDATE ON sened.sened
    FOR EACH ROW EXECUTE FUNCTION sened.sened_versiya_func();

-- 8) Təsdiq əməliyyatı: sənəd təsdiqlənəndə statusu yenilə
CREATE OR REPLACE FUNCTION sened.tesdiq_emeliyyat_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'tesdiqlendi' THEN
        UPDATE sened.sened SET status = 'tesdiqlendi' WHERE sened_id = NEW.sened_id;
    ELSIF NEW.status = 'redd_edildi' THEN
        UPDATE sened.sened SET status = 'qaralama' WHERE sened_id = NEW.sened_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tesdiq_emeliyyat AFTER INSERT OR UPDATE OF status ON sened.tesdiq
    FOR EACH ROW EXECUTE FUNCTION sened.tesdiq_emeliyyat_func();

COMMIT;
