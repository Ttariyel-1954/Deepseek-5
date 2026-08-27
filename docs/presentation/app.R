# =====================================================================
#  DeepSeek-5 ERP — AI Təqdimat App (Shiny)
#  Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi
#  Funksiyalar:
#   1) AI Fəaliyyəti — agentlər, tapşırıqlar, qərarlar, proqnozlar, mesajlar, loglar
#   2) 10 Standart Sorğu — analitik sorğu + interaktiv qrafik/cədvəl
#   3) Süni İntellekt Xidməti — sərbəst suallara canlı DB əsasında cavab
#   4) AI Pipeline Demo — tapşırıq yarat → icra → qərar/proqnoz/mesaj
#  İşə salmaq: Rscript -e "shiny::runApp('~/Desktop/DeepSeek-5/docs/presentation', port=3839)"
#  Tarix: 2026-08-25
# =====================================================================

library(shiny)
library(bslib)
library(DBI)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(jsonlite)

# =====================================================================
#  KÖMƏKÇİLƏR
# =====================================================================
`%||%` <- function(a, b) if (is.null(a) || is.na(a) || a == "") b else a

read_env <- function(path) {
  if (!file.exists(path)) { warning("ENV faylı tapılmadı: ", path); return(list()) }
  lines <- readLines(path, warn = FALSE)
  lines <- lines[grepl("^[A-Z_]+=", lines)]
  out <- list()
  for (ln in lines) {
    kv <- strsplit(ln, "=", fixed = TRUE)[[1]]
    if (length(kv) == 2) out[[kv[1]]] <- gsub('^"|"$', "", trimws(kv[2]))
  }
  out
}

cfg <- read_env("../../backend/.env")
db_params <- list(
  host = cfg$DB_HOST %||% "localhost",
  port = as.integer(cfg$DB_PORT %||% 5432),
  dbname = cfg$DB_NAME %||% "deepseek_erp_v6",
  user = cfg$DB_USER %||% "deepseek_admin",
  password = cfg$DB_PASSWORD %||% "Deepseek2026"
)

# DeepSeek API konfiqurasiyası (chat üçün)
cfg$DEEPSEEK_API_KEY <- cfg$DEEPSEEK_API_KEY %||% ""
cfg$DEEPSEEK_BASE_URL <- cfg$DEEPSEEK_BASE_URL %||% "https://api.deepseek.com"
cfg$DEEPSEEK_MODEL <- cfg$DEEPSEEK_MODEL %||% "deepseek-chat"

# =====================================================================
#  VERİLƏNLƏR BAZASI BAĞLANTISI + MƏLUMATLAR
# =====================================================================
con <- dbConnect(
  RPostgres::Postgres(),
  host = db_params$host, port = db_params$port,
  dbname = db_params$dbname, user = db_params$user, password = db_params$password
)
onStop(function() { if (DBI::dbIsValid(con)) DBI::dbDisconnect(con) })

q <- function(sql) dbGetQuery(con, sql)

layiheler <- q("SELECT l.layihe_id, l.kod, l.ad, l.plan_budce, l.bashlama_tarixi, l.son_tarix,
                       mue.ad AS muessise, st.ad AS status, l.progres,
                       COALESCE(x.fakt, 0) AS fakt_xerc
                FROM layihe.layihe l
                JOIN ref.muessise mue ON mue.muessise_id = l.muessise_id
                JOIN layihe.layihe_status st ON st.status_id = l.status_id
                LEFT JOIN (SELECT layihe_id, SUM(mebleg) AS fakt FROM maliyye.xerc GROUP BY layihe_id) x
                       ON x.layihe_id = l.layihe_id
                WHERE l.silinib = FALSE ORDER BY l.layihe_id")

ai_agentler <- q("SELECT a.agent_id, a.ad AS agent, a.vezife, m.ad AS model, m.provider,
                         m.model_ref, a.status, a.aktif
                  FROM ai.ai_agent a JOIN ai.ai_model m ON m.model_id = a.model_id
                  WHERE a.aktif = TRUE ORDER BY a.agent_id")

ai_teyinatlar <- q("SELECT t.teyinat_id, t.teyinat_novu, t.status, t.tesdiq_status,
                           t.netice_qiymeti, t.ustunluk, t.created_at, t.tamamlanma_tarixi,
                           a.ad AS agent, a.vezife AS agent_vezife, l.kod AS layihe_kod
                    FROM ai.ai_teyinat t
                    JOIN ai.ai_agent a ON a.agent_id = t.agent_id
                    LEFT JOIN layihe.layihe l ON l.layihe_id = t.layihe_id
                    ORDER BY t.teyinat_id DESC")

ai_qerarlar <- q("SELECT q.qerar_id, q.qerar_novu, q.eminlik, q.status, q.esaslandirma,
                         q.tesdiq_eden, q.created_at, a.ad AS agent
                  FROM ai.ai_qerar q
                  JOIN ai.ai_teyinat t ON t.teyinat_id = q.teyinat_id
                  JOIN ai.ai_agent a ON a.agent_id = t.agent_id
                  ORDER BY q.qerar_id DESC")

ai_prognozlar <- q("SELECT p.prognoz_id, p.prognoz_novu, p.prognoz_deyer, p.real_deyer,
                          p.ehtimal, p.doqruluk, p.tarix, l.kod AS layihe_kod
                   FROM ai.ai_prognoz p
                   LEFT JOIN layihe.layihe l ON l.layihe_id = p.layihe_id
                   ORDER BY p.prognoz_id DESC")

ai_mesajlar <- q("SELECT m.mesaj_id, m.movzu, m.mezmun, m.onem, m.oxunub, m.created_at,
                        a.ad AS agent, l.kod AS layihe_kod
                 FROM ai.ai_mesaj m
                 JOIN ai.ai_agent a ON a.agent_id = m.agent_id
                 LEFT JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
                 ORDER BY m.mesaj_id DESC")

ai_loglar <- q("SELECT l.log_id, l.hadise, l.mesaj, l.serf_olunan_tokens, l.serf_olunan_xerc,
                       l.created_at, a.ad AS agent
                FROM ai.ai_log l
                JOIN ai.ai_agent a ON a.agent_id = l.agent_id
                ORDER BY l.log_id DESC")

riskler <- q("SELECT r.risk_id, r.risk_novu, r.tesvir, r.ehtimal, r.tesir, r.derece, r.status,
                     l.kod AS layihe_kod
              FROM risk.risk r LEFT JOIN layihe.layihe l ON l.layihe_id = r.layihe_id
              ORDER BY r.derece DESC")

materiallar <- q("SELECT mn.ad AS material, mn.vahid, COUNT(lm.layihe_material_id) AS istifade_sayi,
                         SUM(lm.miqdar * lm.qiymet) AS deyer
                  FROM layihe.layihe_material lm
                  JOIN ref.material_novu mn ON mn.material_novu_id = lm.material_novu_id
                  GROUP BY mn.material_novu_id, mn.ad, mn.vahid ORDER BY deyer DESC")

isciler <- q("SELECT i.ad_soyad, i.fin, i.maas, i.status, v.ad AS vezife
              FROM kadr.isci i JOIN kadr.vezife v ON v.vezife_id = i.vezife_id
              ORDER BY i.maas DESC")

xerc_ay <- q("SELECT TO_CHAR(tarix, 'YYYY-MM') AS ay, SUM(mebleg) AS mebleg
              FROM maliyye.xerc GROUP BY 1 ORDER BY 1")

tenderler <- q("SELECT t.kod, t.ad, st.ad AS status, t.qiymet_serhedi,
                       ti.sirket_ad AS qalib, ti.teklif_mebleg,
                       t.qiymet_serhedi - ti.teklif_mebleg AS qenayet
                FROM satinalma.tender t
                JOIN satinalma.tender_status st ON st.status_id = t.status_id
                LEFT JOIN satinalma.tender_istirakci ti ON ti.tender_id = t.tender_id AND ti.qalib = TRUE
                WHERE t.status_id = (SELECT status_id FROM satinalma.tender_status WHERE kod='qalib')
                ORDER BY qenayet DESC NULLS LAST")

muqavileler <- q("SELECT m.nomre, m.podratci, l.kod AS layihe_kod, m.mebleg,
                         COALESCE(o.odenen, 0) AS odenen, m.mebleg - COALESCE(o.odenen, 0) AS borc
                  FROM satinalma.muqavile m
                  JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
                  LEFT JOIN (SELECT muqavile_id, SUM(mebleg) AS odenen FROM maliyye.odenis GROUP BY muqavile_id) o
                         ON o.muqavile_id = m.muqavile_id
                  WHERE m.aktif = TRUE ORDER BY borc DESC")

anbar <- q("SELECT a.ad AS anbar, mn.ad AS material,
                   SUM(CASE WHEN mh.hereket_novu='daxil' THEN mh.miqdar
                            WHEN mh.hereket_novu='cixar' THEN -mh.miqdar ELSE 0 END) AS qaliq, mn.vahid
            FROM logistika.anbar a
            JOIN logistika.material_hereket mh ON mh.anbar_id = a.anbar_id
            JOIN ref.material_novu mn ON mn.material_novu_id = mh.material_novu_id
            GROUP BY a.anbar_id, a.ad, mn.material_novu_id, mn.ad, mn.vahid
            ORDER BY a.ad, mn.ad")

senedler <- q("SELECT sn.ad AS novu, s.ad, s.nomre, s.status, s.versiya
               FROM sened.sened s JOIN sened.sened_novu sn ON sn.sened_novu_id = s.sened_novu_id
               ORDER BY sn.ad, s.sened_id")

# =====================================================================
#  10 STANDART SORĞU (SQL + başlıq + izah + qrafik tipi)
# =====================================================================
standart_sorgular <- list(
  list(id = 1, ad = "Layihələrin ümumi icmalı (plan vs fakt)",
       izah = "Hər layihənin plan büdcəsi, faktik xərci, qalığı və progressi.",
       sql = "SELECT kod, layihe_adi AS ad, plan_budce, fakt_xerc, plan_budce-fakt_xerc AS qaliq, progres FROM hesabat.layihe_tam_icmal",
       qrafik = "bar"),
  list(id = 2, ad = "Tender qalibləri və qənaət",
       izah = "Hər tenderin elan məbləği, qalib təklifi və qənaət məbləği.",
       sql = "SELECT kod, ad, qiymet_serhedi, teklif_mebleg, qenayet FROM (SELECT t.kod, t.ad, t.qiymet_serhedi, ti.teklif_mebleg, t.qiymet_serhedi-ti.teklif_mebleg AS qenayet FROM satinalma.tender t JOIN satinalma.tender_istirakci ti ON ti.tender_id=t.tender_id AND ti.qalib=TRUE) s",
       qrafik = "bar"),
  list(id = 3, ad = "Müqavilə ödəniş vəziyyəti (borc)",
       izah = "Hər müqavilənin məbləği, ödənilən hissəsi və qalıq borcu.",
       sql = "SELECT nomre, podratci, muqavile_mebleg, odenen, qaliq_borc FROM hesabat.muqavile_odenis_veziyyeti",
       qrafik = "bar"),
  list(id = 4, ad = "Layihə statuslarının paylanması",
       izah = "Layihələrin statuslara görə sayı və payı.",
       sql = "SELECT status, COUNT(*) AS say FROM (SELECT st.ad AS status FROM layihe.layihe l JOIN layihe.layihe_status st ON st.status_id=l.status_id WHERE l.silinib=FALSE) s GROUP BY status",
       qrafik = "pie"),
  list(id = 5, ad = "AI agentlərin fəaliyyəti",
       izah = "Hər AI agentin tapşırıq sayı, hazır/xəta nisbəti və orta nəticə.",
       sql = "SELECT * FROM hesabat.ai_faaliyyet",
       qrafik = "bar"),
  list(id = 6, ad = "AI proqnozlarının vəziyyəti",
       izah = "Proqnoz növü, proqnoz/real dəyər və dəqiqlik.",
       sql = "SELECT p.prognoz_novu, p.prognoz_deyer, p.real_deyer, p.ehtimal, p.doqruluk, COALESCE(l.kod,'-') AS layihe FROM ai.ai_prognoz p LEFT JOIN layihe.layihe l ON l.layihe_id=p.layihe_id",
       qrafik = "bar"),
  list(id = 7, ad = "Risk profili (ehtimal × təsir)",
       izah = "Hər riskin ehtimalı, təsiri və hesablanmış dərəcəsi.",
       sql = "SELECT risk_novu, tesvir, ehtimal, tesir, derece FROM risk.risk ORDER BY derece DESC",
       qrafik = "bar"),
  list(id = 8, ad = "Anbar qalıqları",
       izah = "Anbarlar üzrə material qalıqları.",
       sql = "SELECT anbar, material, qaliq, vahid FROM hesabat.anbar_qaliqlari",
       qrafik = "bar"),
  list(id = 9, ad = "Kadr maaş təhlili",
       izah = "İşçilərin vəzifəyə görə maaşları.",
       sql = "SELECT ad_soyad, vezife, maas FROM (SELECT i.ad_soyad, v.ad AS vezife, i.maas FROM kadr.isci i JOIN kadr.vezife v ON v.vezife_id=i.vezife_id ORDER BY i.maas DESC) s",
       qrafik = "bar"),
  list(id = 10, ad = "Ay üzrə xərc dinamikası",
       izah = "Aylar üzrə xərclərin dəyişməsi (maliyyə trendi).",
       sql = "SELECT ay, xerc_mebleg FROM hesabat.ayliq_odenis_xerc WHERE xerc_mebleg>0 ORDER BY ay",
       qrafik = "line")
)

# =====================================================================
#  SÜNİ İNTELLEKT XİDMƏTİ — SƏRBƏST SUAL-CAVAB MEXANİZMİ
#  Keyword + canlı SQL əsasında azərbaycanca cavablar
# =====================================================================
norm <- function(s) {
  s <- tolower(s)
  s <- gsub("ə", "e", s); s <- gsub("ö", "o", s); s <- gsub("ü", "u", s)
  s <- gsub("ç", "c", s); s <- gsub("ş", "s", s); s <- gsub("ı", "i", s)
  s <- gsub("ğ", "g", s)
  # Qısa xüsusi əvəzləmələr (regex-ləri sabitləşdirir)
  s <- gsub("layihe", "layihe", s)
  trimws(s)
}

fmt_azn <- function(x) {
  paste0(formatC(round(x), big.mark = " ", format = "d"), " AZN")
}

ai_cavab <- function(sual, force_deepseek = FALSE) {
  s <- norm(sual)
  h <- tags$div

  # --- DeepSeek qoşulubsa: hər sualı DeepSeek-ə göndər ---
  if (force_deepseek) {
    ds_key <- cfg$DEEPSEEK_API_KEY %||% ""
    if (nchar(ds_key) > 0) {
      cavab <- ai_deepseek_cavab(sual, ds_key)
      if (!is.null(cavab)) {
        return(h(class = "ai-msg", tags$b("🤖 DeepSeek AI:"), tags$br(), HTML(cavab)))
      }
    }
  }

  # --- Salam / kömək ---
  if (grepl("salam|merhaba|hey|hello|hi\\b", s) && nchar(s) < 20) {
    return(h(class = "ai-msg",
      tags$b("Salam! 👋 "),
      "Mən DeepSeek-5 ERP-nin süni intellekt köməkçisiyəm. Mənə baza haqqında sual verə bilərsiniz, məsələn:\n",
      tags$ul(
        tags$li("Neçə layihə var?"),
        tags$li("Ümumi büdcə nə qədərdir?"),
        tags$li("Tender qənaəti nə qədər olub?"),
        tags$li("AI agentləri neçə tapşırıq yerinə yetirib?"),
        tags$li("Hansı risklər yüksəkdir?")
      )))
  }

  # --- Kömək ---
  if (grepl("komek|yardim|help|neler|ne ede|nə edə", s)) {
    return(h(class = "ai-msg",
      tags$b("Suala verə biləcəyim mövzular: "),
      "layihələr, büdcə, xərclər, tender, müqavilə, ödəniş, borc, işçilər, maaş, material, anbar, risk, keyfiyyət, AI agentlər, proqnoz, mesaj, region, status."))
  }

  # --- Neçə layihə / ümumi say ---
  if (grepl("nece layihe|neçə layihe|neçə layihə|kaç layihe|layihe say|laihe", s) && grepl("neçə|nece|kaç|say|count", s)) {
    n <- nrow(layiheler)
    st <- layiheler %>% count(status)
    st_txt <- paste0(st$status, " (", st$n, ")", collapse = ", ")
    return(h(class = "ai-msg",
      tags$b("📋 Layihə sayı: ", n),
      tags$br(), "Statuslara görə: ", st_txt))
  }

  # --- Bütün layihələr siyahısı ---
  if (grepl("layihe", s) && grepl("hans[ıi]|siyah|list|goster|nə var", s)) {
    kodlar <- paste0(layiheler$kod, " — ", layiheler$ad, " (", layiheler$status, ")", collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("🏗️ Layihələr (", nrow(layiheler), "):"), tags$br(), HTML(kodlar)))
  }

  # --- Büdcə / xərc məbləği ---
  if (grepl("budc|bu[dt]c", s) && grepl("ne qeder|nə qədər|kaç|neçə|mebleg|məbləğ|cəmi|toplam|umumi", s)) {
    toplam_budce <- sum(layiheler$plan_budce)
    toplam_xerc <- sum(layiheler$fakt_xerc)
    return(h(class = "ai-msg",
      tags$b("💰 Maliyyə xülasəsi:"),
      tags$br(), "Toplam plan büdcə: ", fmt_azn(toplam_budce),
      tags$br(), "Toplam faktik xərc: ", fmt_azn(toplam_xerc),
      tags$br(), "İstifadə faizi: ", round(100 * toplam_xerc / max(toplam_budce, 1), 1), "%"))
  }

  # --- Ən böyük / ən çox layihə ---
  if (grepl("en (boyuk|böyük|cox|çox|bahali|bahal)", s) && grepl("layihe", s)) {
    mx <- layiheler %>% arrange(desc(plan_budce)) %>% slice(1)
    return(h(class = "ai-msg",
      tags$b("🏆 Ən böyük layihə: ", mx$kod, " — ", mx$ad),
      tags$br(), "Plan büdcə: ", fmt_azn(mx$plan_budce),
      tags$br(), "Faktik xərc: ", fmt_azn(mx$fakt_xerc),
      tags$br(), "Status: ", mx$status))
  }

  # --- Tender qənaəti ---
  if (grepl("tender|qenayet|qənaət|genaet", s)) {
    qalib <- tenderler %>% filter(!is.na(qalib))
    toplam_q <- sum(qalib$qenayet, na.rm = TRUE)
    satir <- if (nrow(qalib) > 0) {
      paste0(qalib$kod, ": ", qalib$qalib, " (qənaət ", fmt_azn(qalib$qenayet), ")", collapse = "<br>")
    } else "Hələ qalib müəyyən olunmuş tender yoxdur"
    return(h(class = "ai-msg",
      tags$b("🏆 Tender qənaəti: ", fmt_azn(toplam_q)),
      tags$br(), HTML(satir)))
  }

  # --- Müqavilə borcu ---
  if (grepl("muqavil|borc|odenis|ödəniş|payment", s)) {
    toplam_borc <- sum(muqavileler$borc)
    satir <- paste0(muqavileler$nomre, " — ", muqavileler$podratci, ": borc ", fmt_azn(muqavileler$borc), collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("📑 Ümumi müqavilə borcu: ", fmt_azn(toplam_borc)),
      tags$br(), HTML(satir)))
  }

  # --- İşçilər / kadr ---
  if (grepl("isci|işçi|kadr|neçə nəfər|nece nefer|calisan", s)) {
    n <- nrow(isciler)
    orta <- mean(isciler$maas)
    en_yuk <- isciler %>% slice(1)
    return(h(class = "ai-msg",
      tags$b("👥 İşçi sayı: ", n),
      tags$br(), "Orta maaş: ", fmt_azn(orta),
      tags$br(), "Ən yüksək maaş: ", en_yuk$ad_soyad, " (", en_yuk$vezife, ") — ", fmt_azn(en_yuk$maas)))
  }

  # --- Material / anbar ---
  if (grepl("material|anbar|techizat|təchizat|ehtiyat", s)) {
    top_deyer <- sum(materiallar$deyer)
    en_cox <- materiallar %>% slice(1)
    satir <- paste0(anbar$anbar, " — ", anbar$material, ": ", anbar$qaliq, " ", anbar$vahid, collapse = "<br>")
    hisseler <- list(
      tags$b("🧱 Material xülasəsi:"),
      tags$br(), "Toplam material dəyəri: ", fmt_azn(top_deyer),
      tags$br(), "Ən çox istifadə: ", en_cox$material, " (", fmt_azn(en_cox$deyer), ")"
    )
    if (nrow(anbar) > 0) {
      hisseler <- c(hisseler, list(tags$br(), tags$b("Anbar qalıqları:"), tags$br(), HTML(satir)))
    }
    return(do.call(h, c(list(class = "ai-msg"), hisseler)))
  }

  # --- Risk ---
  if (grepl("risk|tehluke|təhlükə|tehlike|tehluk", s)) {
    kritik <- riskler %>% filter(derece >= 60)
    orta <- round(mean(riskler$derece), 1)
    satir <- if (nrow(kritik) > 0) {
      paste0(kritik$risk_novu, " (", kritik$layihe_kod, ") — dərəcə ", kritik$derece, collapse = "<br>")
    } else "Kritik risk yoxdur"
    return(h(class = "ai-msg",
      tags$b("⚠️ Risk xülasəsi:"),
      tags$br(), "Orta risk dərəcəsi: ", orta,
      tags$br(), tags$b("Kritik risklər (≥60):"), tags$br(), HTML(satir)))
  }

  # --- AI agent fəaliyyəti ---
  if (grepl("ai agent|agent|tapsiriq|tapşırıq|teyinat", s)) {
    hazir <- sum(ai_teyinatlar$status == "hazir")
    xesver <- sum(ai_teyinatlar$status == "xesver")
    golecek <- sum(ai_teyinatlar$status == "golecek")
    agent_satir <- paste0(ai_agentler$agent, " (", ai_agentler$vezife, ")", collapse = ", ")
    return(h(class = "ai-msg",
      tags$b("🤖 AI fəaliyyəti:"),
      tags$br(), "Agentlər: ", ai_agentler$agent |> length(), " — ", agent_satir,
      tags$br(), "Tapşırıqlar: cəmi ", nrow(ai_teyinatlar), " (hazir: ", hazir, ", gözləyir: ", golecek, ", xəta: ", xesver, ")"))
  }

  # --- Proqnoz ---
  if (grepl("proqnoz|texmin|təxmin|prediction", s)) {
    p_satir <- paste0(ai_prognozlar$prognoz_novu, " → ", fmt_azn(ai_prognozlar$prognoz_deyer),
                      " (ehtimal ", ai_prognozlar$ehtimal, "%)", collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("🔮 AI proqnozları (", nrow(ai_prognozlar), "):"), tags$br(), HTML(p_satir)))
  }

  # --- Mesajlar ---
  if (grepl("mesaj|xeberdarlıq|xəbərdarlıq|bildiris|bildiriş", s)) {
    oxunmamis <- sum(ai_mesajlar$oxunub == FALSE)
    kritik <- sum(ai_mesajlar$onem %in% c("yuksek", "kritik"))
    m_satir <- paste0("[", ai_mesajlar$onem, "] ", ai_mesajlar$movzu, collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("📨 AI mesajları: cəmi ", nrow(ai_mesajlar), " (oxunmamış: ", oxunmamis, ", yüksək önəm: ", kritik, ")"),
      tags$br(), HTML(m_satir)))
  }

  # --- Region / şəhər ---
  if (grepl("region|seher|şəhər|hansı seher|hansı şəhər", s)) {
    reg <- q("SELECT r.ad AS region, s.ad AS seher FROM ref.region r LEFT JOIN ref.seher s ON s.region_id=r.region_id WHERE s.seher_id IS NOT NULL")
    satir <- paste0(reg$seher, " (", reg$region, ")", collapse = ", ")
    return(h(class = "ai-msg",
      tags$b("📍 Şəhərlər üzrə region xəritəsi:"), tags$br(), satir))
  }

  # --- Xərc dinamikası / ay ---
  if (grepl("xerc|xərc|dinamik|trend|ay uzre|ay üzrə|ayliq|aylıq", s)) {
    satir <- paste0(xerc_ay$ay, ": ", fmt_azn(xerc_ay$mebleg), collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("📈 Aylıq xərc dinamikası:"), tags$br(), HTML(satir)))
  }

  # --- Keyfiyyət ---
  if (grepl("keyfiyyet|keyfiyyət|yoxlama|qusur|qüsur", s)) {
    yoxlama <- q("SELECT netice, COUNT(*) AS say FROM keyfiyyet.yoxlama GROUP BY netice")
    qusur <- q("SELECT status, COUNT(*) AS say FROM keyfiyyet.qusur GROUP BY status")
    satir <- paste0(yoxlama$netice, ": ", yoxlama$say, collapse = ", ")
    q_satir <- paste0(qusur$status, ": ", qusur$say, collapse = ", ")
    return(h(class = "ai-msg",
      tags$b("🔎 Keyfiyyət xülasəsi:"),
      tags$br(), "Yoxlamalar: ", satir,
      tags$br(), "Qüsurlar: ", q_satir))
  }

  # --- Sənədlər ---
  if (grepl("sened|sənəd|senet", s)) {
    satir <- paste0(senedler$novu, ": ", senedler$status, collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("📄 Sənədlər (", nrow(senedler), "):"), tags$br(), HTML(satir)))
  }

  # --- AI model / provider ---
  if (grepl("model|provider|deepseek|claude|anthropic|ai necə|necə işl", s)) {
    models <- q("SELECT ad, provider, model_ref FROM ai.ai_model ORDER BY model_id")
    satir <- paste0(models$ad, " (", models$provider, " — ", models$model_ref, ")", collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("🧠 AI modelləri:"), tags$br(), HTML(satir),
      tags$br(), tags$br(),
      "AI sistemi iki provider-də işləyir: ", tags$b("DeepSeek"), " və ", tags$b("Anthropic Claude"),
      ". Hər agent öz modelinə bağlıdır və tapşırıqları AI_MODE rejiminə əsasən icra edir."))
  }

  # --- Tənzimləmə / təhlükəsizlik ---
  if (grepl("tehlukesizlik|təhlükəsizlik|security|audit|audıt|kim deyis|kim dəyiş", s)) {
    audit <- q("SELECT sxem||'.'||cedvel AS cedvel, emeliyyat, COUNT(*) AS say FROM audit.audit_log GROUP BY sxem, cedvel, emeliyyat ORDER BY say DESC LIMIT 5")
    satir <- paste0(audit$cedvel, " (", audit$emeliyyat, "): ", audit$say, collapse = "<br>")
    return(h(class = "ai-msg",
      tags$b("🔐 Təhlükəsizlik və audit:"),
      tags$br(), "Ən çox dəyişiklik edilən cədvəllər:", tags$br(), HTML(satir),
      tags$br(), tags$br(), "Sistem JWT autentifikasiya, rol əsaslı giriş və tam audit izi ilə qorunur."))
  }

  # --- Yekun: başa düşmədiksə — REAL DeepSeek API cavabı ---
  ds_key <- cfg$DEEPSEEK_API_KEY %||% ""
  if (nchar(ds_key) > 0) {
    cavab <- ai_deepseek_cavab(sual, ds_key)
    if (!is.null(cavab)) {
      return(h(class = "ai-msg", tags$b("🤖 DeepSeek AI:"), tags$br(), cavab))
    }
  }
  # API key yoxdursa və ya xəta oldu → lokal fallback
  return(h(class = "ai-msg",
    tags$b("Hmm, bu sualı tam başa düşmədim. 🤔"),
    tags$br(), "Aşağıdakı mövzulardan birini soruşa bilərsiniz: layihələr, büdcə, xərc, tender, müqavilə, işçilər, material, risk, AI agentlər, proqnoz, mesaj, keyfiyyət, region, sənədlər, təhlükəsizlik.",
    tags$br(), "Məsələn: ", tags$i("\"Neçə layihə var?\""), " və ya ", tags$i("\"Tender qənaəti nə qədərdir?\"")))
}

# =====================================================================
#  REAL DEEPSEEK API CAVABI (ixtiyari suallar üçün)
#  API key .env-dən oxunur: DEEPSEEK_API_KEY
#  Key yoxdursa NULL qaytarır → lokal fallback işləyir
# =====================================================================
ai_deepseek_cavab <- function(sual, api_key) {
  base_url <- cfg$DEEPSEEK_BASE_URL %||% "https://api.deepseek.com"
  model <- cfg$DEEPSEEK_MODEL %||% "deepseek-chat"

  # Baza konteksti — DeepSeek-ə baza haqqında ətraflı məlumat ver
  layihe_xulase <- paste0(layiheler$kod, "=", layiheler$ad, " (", layiheler$status,
                          ", plan ", fmt_azn(layiheler$plan_budce),
                          ", xərc ", fmt_azn(layiheler$fakt_xerc), ")", collapse = "; ")
  muqavile_xulase <- paste0(muqavileler$nomre, "=", muqavileler$podratci,
                            ", borc ", fmt_azn(muqavileler$borc), collapse = "; ")
  risk_xulase <- paste0(riskler$risk_novu, " (dərəcə ", riskler$derece, ")", collapse = "; ")
  material_xulase <- paste0(materiallar$material, " (", fmt_azn(materiallar$deyer), ")", collapse = "; ")

  kontekst <- paste0(
    "Sən Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi ",
    "üçün qurulan DeepSeek-5 ERP sisteminin süni intellekt köməkçisisən. Azərbaycan dilində cavab ver. ",
    "Baza haqqında canlı məlumatlar: ",
    "Layihələr (", nrow(layiheler), "): ", layihe_xulase, ". ",
    "Plan büdcə ", fmt_azn(sum(layiheler$plan_budce)),
    ", faktik xərc ", fmt_azn(sum(layiheler$fakt_xerc)), ". ",
    "AI idarəetmə: ", nrow(ai_agentler), " agent, ", nrow(ai_teyinatlar), " tapşırıq, ",
    nrow(ai_qerarlar), " qərar, ", nrow(ai_prognozlar), " proqnoz, ", nrow(ai_mesajlar), " mesaj. ",
    "Kadr: ", nrow(isciler), " işçi, orta maaş ", fmt_azn(mean(isciler$maas)), ". ",
    "Müqavilələr (", nrow(muqavileler), "): ", muqavile_xulase, ". ",
    "Risk (", nrow(riskler), "): ", risk_xulase, ". ",
    "Materiallar: ", material_xulase, "."
  )

  sorğu_bodysi <- list(
    model = model,
    messages = list(
      list(role = "system", content = kontekst),
      list(role = "user", content = sual)
    ),
    temperature = 0.3,
    max_tokens = 1024,
    stream = FALSE
  )

  tryCatch({
    resp <- httr::POST(
      url = paste0(base_url, "/chat/completions"),
      httr::add_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ),
      body = sorğu_bodysi,
      encode = "json",
      httr::timeout(30)
    )
    if (httr::status_code(resp) != 200) return(NULL)
    parsed <- httr::content(resp, as = "parsed")
    cavab <- parsed$choices[[1]]$message$content
    if (is.null(cavab) || nchar(cavab) == 0) return(NULL)
    # Literal HTML entity və newline-ləri təmiz <br>-yə çevir
    cavab <- gsub("&lt;br&gt;", "\n", cavab, fixed = TRUE)
    cavab <- gsub("\r", "", cavab)
    cavab <- gsub("\\n+", "<br>", cavab)
    cavab
  }, error = function(e) NULL)
}

# =====================================================================
#  AI PIPELINE SİMULYATORU (tapşırıq yarat → icra → nəticə)
#  Canlı DB-yə yazır — süni intellekt xidmətinin iş prinsipini göstərir
# =====================================================================
ai_pipeline_icra <- function(agent_id, teyinat_novu, giris_json) {
  # 1) Tapşırıq yarat (status='golecek')
  teyinat_id <- dbGetQuery(con, "INSERT INTO ai.ai_teyinat (agent_id, teyinat_novu, giris_json, status, ustunluk)
    VALUES ($1, $2, $3::jsonb, 'golecek', 5) RETURNING teyinat_id",
    params = list(agent_id, teyinat_novu, toJSON(giris_json, auto_unbox = TRUE)))$teyinat_id

  # Log: basladi
  dbExecute(con, "INSERT INTO ai.ai_log (teyinat_id, agent_id, hadise, mesaj, serf_olunan_tokens) VALUES ($1,$2,'basladi','Tapşırıq icraya başladı',120)",
            params = list(teyinat_id, agent_id))

  # 2) Status='islemede'
  dbExecute(con, "UPDATE ai.ai_teyinat SET status='islemede' WHERE teyinat_id=$1", params = list(teyinat_id))
  Sys.sleep(0.6)

  # 3) "AI düşüncəsi" — teyinat növünə görə mock nəticə
  mock_netice <- switch(teyinat_novu,
    "budce_prognozu" = list(prognoz_budce = 823000, sapma_faizi = -3.2, etibarliliq = 78,
                            tovsiye = "Material alışını rübün sonuna saxlayın və ehtiyat büdcə ayırın."),
    "tender_qiymetlendirme" = list(qalib_istirakci_id = 1, eminlik = 91,
                                   esaslandirma = "Ən aşağı qiymət və ən yaxşı şərtlər"),
    "risk_analizi" = list(kritik_risk_sayi = 2, orta_derece = 55,
                          tovsiye = "Yüksək riskli mərhələyə xüsusi nəzarət tələb olunur"),
    "xerc_asirliq_xeberdarligi" = list(asirma_faizi = 12.5, mebleg = 98000,
                                       tovsiye = "Xərc artımına nəzarəti gücləndirin"),
    "material_planlamasi" = list(azalan_material = 3, tovsiye = "Sement və boyaq ehtiyatını artırın"),
    "keyfiyyet_hesabati" = list(kecme_faizi = 85.7, qusur_sayi = 2,
                                tovsiye = "Qüsurları aradan qaldırın və yenidən yoxlayın"),
    list(netice = "Tamamlandı", etibarliliq = 90)
  )

  # 4) Nəticəni yaz (status='hazir', cixis_json, netice_qiymeti)
  netice_qiymeti <- ifelse(teyinat_novu %in% c("tender_qiymetlendirme"), 91,
                    ifelse(teyinat_novu == "risk_analizi", 85, 82))
  dbExecute(con, "UPDATE ai.ai_teyinat SET status='hazir', cixis_json=$2::jsonb,
                   netice_qiymeti=$3, tamamlanma_tarixi=NOW()
            WHERE teyinat_id=$1",
            params = list(teyinat_id, toJSON(mock_netice, auto_unbox = TRUE), netice_qiymeti))

  # Log: bitdi
  dbExecute(con, "INSERT INTO ai.ai_log (teyinat_id, agent_id, hadise, mesaj, serf_olunan_tokens, serf_olunan_xerc)
            VALUES ($1,$2,'bitdi','Tapşırıq tamamlandı',320,0.045)",
            params = list(teyinat_id, agent_id))

  # 5) Qərar yarat (ai_qerar)
  qerar_novu <- ifelse(teyinat_novu == "tender_qiymetlendirme", "tender_qalibi",
                ifelse(teyinat_novu == "risk_analizi", "risk_mitedaxile", "budce_tovsiyesi"))
  dbExecute(con, "INSERT INTO ai.ai_qerar (teyinat_id, qerar_novu, mezmun, esaslandirma, eminlik, status)
            VALUES ($1, $2, $3::jsonb, $4, $5, 'teklif')",
            params = list(teyinat_id, qerar_novu, toJSON(mock_netice, auto_unbox = TRUE),
                          mock_netice$tovsiye %||% "AI təhlili", mock_netice$eminlik %||% mock_netice$etibarliliq %||% 80))

  # 6) Proqnoz yarat (ai_prognoz) — budce proqnozu üçün
  if (teyinat_novu == "budce_prognozu") {
    layihe_id <- dbGetQuery(con, "SELECT layihe_id FROM layihe.layihe LIMIT 1")$layihe_id[1]
    dbExecute(con, "INSERT INTO ai.ai_prognoz (layihe_id, prognoz_novu, prognoz_deyer, ehtimal)
              VALUES ($1, 'budce_sapmasi', $2, $3)",
              params = list(layihe_id, mock_netice$prognoz_budce, mock_netice$etibarliliq))
  }

  # 7) Mesaj yarat (ai_mesaj)
  dbExecute(con, "INSERT INTO ai.ai_mesaj (agent_id, layihe_id, alici_id, movzu, mezmun, onem, oxunub)
            SELECT agent_id, (SELECT layihe_id FROM layihe.layihe LIMIT 1), 1,
                   $2, $3, 'normal', FALSE FROM ai.ai_agent WHERE agent_id=$1",
            params = list(agent_id, paste0("AI tapşırıq tamamlandı: ", teyinat_novu),
                          mock_netice$tovsiye %||% "Nəticə hazırdır"))

  list(teyinat_id = teyinat_id, netice = mock_netice, qiymet = netice_qiymeti)
}

# =====================================================================
#  RƏNGLƏR VƏ TEMA
# =====================================================================
c_navy <- "#0F3D5C"; c_navy_d <- "#0A2B42"; c_accent <- "#0E9F6E"
c_amber <- "#B45309"; c_red <- "#B91C1C"; c_teal <- "#0D9488"
c_gray <- "#64748B"; c_blue <- "#2563EB"

theme_bs <- bs_theme(
  version = 5, bg = "#F6F8FB", fg = "#1E293B",
  primary = c_navy, secondary = c_gray,
  success = c_accent, warning = c_amber, danger = c_red,
  base_font = font_google("Inter"), heading_font = font_google("Inter"),
  bootswatch = "flatly"
)

# =====================================================================
#  UI
# =====================================================================
ui <- tagList(
  tags$head(tags$style(HTML("
    .hero { background: linear-gradient(135deg, #0F3D5C 0%, #0A2B42 60%, #0B3A34 100%);
            color: white; border-radius: 16px; padding: 30px 28px; margin-bottom: 18px;
            border-bottom: 4px solid #0E9F6E; }
    .hero h1 { font-size: 1.8rem; font-weight: 800; margin: 0 0 6px 0; }
    .hero p { opacity: 0.92; margin: 0; }
    .chip { display:inline-block; background: rgba(14,159,110,.22); border:1px solid rgba(14,159,110,.5);
            color: #7CE8BF; border-radius: 20px; padding: 3px 12px; margin: 6px 4px 0 0;
            font-size: 0.78rem; font-weight: 600; }
    .kpi { background: white; border: 1px solid #E2E8F0; border-radius: 12px; padding: 16px;
           box-shadow: 0 1px 3px rgba(15,61,92,.06); }
    .kpi .lbl { font-size: 0.75rem; text-transform: uppercase; letter-spacing: .6px; color: #64748B; font-weight: 700; }
    .kpi .val { font-size: 1.6rem; font-weight: 800; color: #0F3D5C; margin-top: 2px; }
    .kpi .sub { font-size: 0.8rem; color: #64748B; }
    .section-title { font-size: 1.1rem; font-weight: 800; color: #0F3D5C; margin: 16px 0 8px;
                     border-left: 4px solid #0E9F6E; padding-left: 10px; }
    .chat-area { background: #F1F5F9; border-radius: 12px; padding: 16px; min-height: 320px;
                 max-height: 460px; overflow-y: auto; border: 1px solid #E2E8F0; }
    .chat-user { background: #0F3D5C; color: white; border-radius: 14px 14px 4px 14px;
                 padding: 10px 14px; margin: 6px 0 6px auto; max-width: 80%; font-size: 0.92rem;
                 white-space: pre-wrap; }
    .chat-ai { background: white; border: 1px solid #E2E8F0; border-radius: 14px 14px 14px 4px;
               padding: 10px 14px; margin: 6px auto 6px 0; max-width: 88%; font-size: 0.92rem;
               white-space: pre-wrap; box-shadow: 0 1px 2px rgba(15,61,92,.06); }
    .chat-user b, .chat-ai b { font-weight: 800; }
    .badge-st { display:inline-block; border-radius: 20px; padding: 2px 10px; font-size: 0.75rem; font-weight: 700; }
    .st-golecek { background:#E2E8F0; color:#475569; }
    .st-islemede { background:#DBEAFE; color:#1D4ED8; }
    .st-hazir { background:#D1FAE5; color:#0B7A55; }
    .st-xesver { background:#FEE2E2; color:#B91C1C; }
  "))),
  page_navbar(
  title = tags$span(
    tags$b(style = "font-weight:800; font-size:1.25rem; color:#0F3D5C;", "🏗️ DeepSeek-5 ERP"),
    tags$small(style = "font-weight:400; font-size:0.8rem; color:#64748B; margin-left:8px;",
               "AI ilə Tam İdarəolunan Sistem")
  ),
  theme = theme_bs, fillable = TRUE,

  # ================= GİRİŞ =================
  nav_panel("Giriş", value = "giris",
    div(class = "hero",
      h1("🤖 DeepSeek-5 ERP — AI ilə Tam İdarəolunan Sistem"),
      p("Elm və Təhsil Nazirliyi · Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi"),
      div(class = "chip", "13 sxem · 48 cədvəl"),
      div(class = "chip", "18 funksiya · 32 trigger"),
      div(class = "chip", "5 AI model · 6 AI agent"),
      div(class = "chip", "DeepSeek + Anthropic Claude")
    ),
    layout_columns(
      col_widths = c(3,3,3,3),
      div(class = "kpi", div(class="lbl", "Layihələr"), div(class="val", nrow(layiheler)),
          div(class="sub", "aktiv layihə")),
      div(class = "kpi", div(class="lbl", "Plan Büdcə"), div(class="val", paste0(round(sum(layiheler$plan_budce)/1000), " min ₼")),
          div(class="sub", "ümumi planlaşdırma")),
      div(class = "kpi", div(class="lbl", "AI Tapşırıqlar"), div(class="val", nrow(ai_teyinatlar)),
          div(class="sub", paste0("hazir: ", sum(ai_teyinatlar$status=="hazir")))),
      div(class = "kpi", div(class="lbl", "AI Mesajlar"), div(class="val", nrow(ai_mesajlar)),
          div(class="sub", paste0("oxunmamış: ", sum(ai_mesajlar$oxunub==FALSE))))
    ),
    div(class = "section-title", "Sistemin iş prinsipi"),
    layout_columns(
      col_widths = c(6,6),
      card(card_header("🔁 AI idarəetmə dövrü"),
        tags$ol(style = "font-size:0.92rem; line-height:1.7;",
          tags$li(tags$b("Tapşırıq yaranır"), " — ai_teyinat-da status='golecek', giris_json ilə"),
          tags$li(tags$b("Agent icra edir"), " — DeepSeek və ya Claude modeli promptu işləyir"),
          tags$li(tags$b("Nəticə yazılır"), " — cixis_json, status='hazir', ai_log token/xərc"),
          tags$li(tags$b("Qərar/proqnoz/mesaj yaranır"), " — avtomatik ai_qerar/ai_prognoz/ai_mesaj"),
          tags$li(tags$b("Təsdiq və icra"), " — insan təsdiqi (S1-2) və ya avtomatik (S3)")
        )),
      card(card_header("📊 Təqdimat modulları"),
        tags$ul(style = "font-size:0.92rem; line-height:1.7;",
          tags$li(tags$b("AI Fəaliyyəti"), " — agentlər, tapşırıqlar, qərarlar, proqnozlar, mesajlar, loglar"),
          tags$li(tags$b("10 Standart Sorğu"), " — əsas analitik hesabatlar"),
          tags$li(tags$b("Süni İntellekt Xidməti"), " — sərbəst suallara canlı cavab"),
          tags$li(tags$b("AI Pipeline Demo"), " — tapşırıq yarat → icra → nəticə")
        ))
    ),
    p(style = "color:#94A3B8; font-size:0.82rem; text-align:center; margin-top:14px;",
      "Canlı məlumatlar — deepseek_erp_v6 bazasından · 2026 © DeepSeek-5 Komandası")
  ),

  # ================= AI FƏALİYYƏTİ =================
  nav_panel("AI Fəaliyyəti", value = "ai",
    layout_columns(
      col_widths = c(6,6),
      card(card_header("🤖 Agentlər və tapşırıq yükü"),
        plotlyOutput("ai_agent_plot", height = "280px")),
      card(card_header("📊 Tapşırıq statusları"),
        plotlyOutput("ai_teyinat_status_plot", height = "280px"))
    ),
    layout_columns(
      col_widths = c(6,6),
      card(card_header("💡 Qərarlar — eminlik və status"),
        plotlyOutput("ai_qerar_plot", height = "260px")),
      card(card_header("💰 AI xərcləri (token)"),
        plotlyOutput("ai_log_plot", height = "260px"))
    ),
    layout_columns(
      col_widths = c(7,5),
      card(card_header("📋 AI tapşırıqlar"),
        DT::dataTableOutput("ai_teyinat_table")),
      card(card_header("🔮 Proqnozlar"),
        DT::dataTableOutput("ai_prognoz_table"))
    ),
    layout_columns(
      col_widths = c(6,6),
      card(card_header("📨 Mesajlar"),
        DT::dataTableOutput("ai_mesaj_table")),
      card(card_header("🧾 Loglar"),
        DT::dataTableOutput("ai_log_table"))
    )
  ),

  # ================= 10 STANDART SORĞU =================
  nav_panel("10 Standart Sorğu", value = "sorgular",
    card(
      card_header("📊 Analitik Hesabatlar"),
      selectInput("sorqu_sec", "Sorğu seçin:",
        choices = setNames(as.character(sapply(standart_sorgular, function(x) x$id)),
                           sapply(standart_sorgular, function(x) paste0(x$id, ". ", x$ad))),
        selected = "1", width = "100%"),
      textOutput("sorqu_izah")
    ),
    layout_columns(
      col_widths = c(6,6),
      card(card_header("📈 Qrafik"), plotlyOutput("sorqu_plot", height = "380px")),
      card(card_header("📋 Cədvəl"), DT::dataTableOutput("sorqu_table"))
    )
  ),

  # ================= SÜNİ İNTELLEKT XİDMƏTİ =================
  nav_panel("Süni İntellekt Xidməti", value = "chat",
    layout_columns(
      col_widths = c(7,5),
      card(
        card_header("💬 AI Köməkçi — DeepSeek ilə sərbəst sual-cavab"),
        tags$div(style = "font-size:0.85rem; color:#64748B; margin-bottom:10px;",
          "DeepSeek AI-ya ixtiyari sual verin. Məsələn: ", tags$i("\"Layihələrin maliyyə vəziyyətini şərh et\""),
          ", ", tags$i("\"Hansı layihəyə prioritet verməliyəm?\""), ", ", tags$i("\"Risk nəzarəti necədir?\""),
          " — ya da ənənəvi suallar: ", tags$i("\"Neçə layihə var?\"")),
        div(class = "chat-area", uiOutput("chat_box")),
        layout_columns(
          col_widths = c(9,3),
          textInput("chat_sual", NULL, placeholder = "Sualınızı bura yazın...", width = "100%"),
          actionButton("chat_gonder", "Göndər", class = "btn-success", style = "width:100%; height:38px;")
        ),
        actionButton("chat_temizle", "🧹 Söhbəti təmizlə", class = "btn-outline-secondary btn-sm")
      ),
      card(
        card_header("🔌 DeepSeek API Qoşulması"),
        uiOutput("ds_status"),
        tags$hr(),
        tags$div(style = "font-size:0.85rem; color:#64748B; margin-bottom:6px;",
          "DeepSeek API key-inizi daxil edin (platform.deepseek.com):"),
        passwordInput("ds_key_input", NULL, value = "", placeholder = "sk-...", width = "100%"),
        br(),
        layout_columns(
          col_widths = c(6,6),
          actionButton("ds_qosul", "🔗 Qoşul", class = "btn-primary", style = "width:100%;"),
          actionButton("ds_kes", "⛔ Ayır", class = "btn-outline-danger", style = "width:100%;")
        ),
        br(),
        uiOutput("ds_info")
      )
    )
  ),

  # ================= AI PIPELINE DEMO =================
  nav_panel("AI Pipeline Demo", value = "pipeline",
    layout_columns(
      col_widths = c(5,7),
      card(card_header("⚙️ AI Tapşırıq Simulyasiyası"),
        selectInput("demo_agent", "Agent seçin:",
          choices = setNames(ai_agentler$agent_id, paste0(ai_agentler$agent, " (", ai_agentler$vezife, ")")),
          width = "100%"),
        selectInput("demo_nov", "Tapşırıq növü:",
          choices = c("budce_prognozu", "tender_qiymetlendirme", "risk_analizi",
                      "xerc_asirliq_xeberdarligi", "material_planlamasi", "keyfiyyet_hesabati"),
          width = "100%"),
        actionButton("demo_icra", "🚀 Tapşırığı icra et", class = "btn-success", style = "width:100%;"),
        br(), br(),
        tags$div(style = "font-size:0.82rem; color:#64748B;",
          "Bu simulyator AI xidmətinin iş prinsipini göstərir: tapşırıq yaradılır → agent icra edir → ",
          "qərar/proqnoz/mesaj avtomatik yaranır. Nəticələr canlı DB-yə yazılır.")),
      card(card_header("📤 Nəticə"),
        uiOutput("demo_netice"))
    ),
    card(card_header("🔄 AI Dövrü (tapşırıq → icra → nəticə → qərar)"),
      plotlyOutput("demo_dongu", height = "240px"))
  ),

  footer = div(style = "text-align:center; color:#94A3B8; font-size:0.8rem; padding:14px;",
    "DeepSeek-5 ERP — AI Təqdimat App · Canlı PostgreSQL (deepseek_erp_v6)")
  )
)

# =====================================================================
#  SERVER
# =====================================================================
server <- function(input, output, session) {

  # ---- AI Fəaliyyəti: agentlər bar ----
  output$ai_agent_plot <- renderPlotly({
    df <- ai_teyinatlar %>% group_by(agent) %>%
      summarise(cemi = n(), hazir = sum(status == "hazir"), xesver = sum(status == "xesver"))
    p <- plot_ly(df, x = ~agent, y = ~cemi, type = "bar", name = "Cəmi",
                 marker = list(color = c_navy), hovertemplate = "%{x}: %{y}<extra>Cəmi</extra>") %>%
      add_trace(y = ~hazir, name = "Hazır", marker = list(color = c_accent),
                hovertemplate = "%{x}: %{y}<extra>Hazır</extra>") %>%
      add_trace(y = ~xesver, name = "Xəta", marker = list(color = c_red),
                hovertemplate = "%{x}: %{y}<extra>Xəta</extra>") %>%
      layout(barmode = "group", xaxis = list(title = ""), yaxis = list(title = "Tapşırıq sayı"),
             legend = list(orientation = "h", y = -0.2), margin = list(b = 70))
    p
  })

  # ---- AI tapşırıq statusları pie ----
  output$ai_teyinat_status_plot <- renderPlotly({
    st <- ai_teyinatlar %>% count(status)
    plot_ly(st, labels = ~status, values = ~n, type = "pie",
            marker = list(colors = c("#E2E8F0", "#2563EB", "#0E9F6E", "#B91C1C")),
            textinfo = "label+value", hovertemplate = "%{label}: %{value}<extra></extra>") %>%
      layout(legend = list(orientation = "h", y = -0.15))
  })

  # ---- AI qərarlar ----
  output$ai_qerar_plot <- renderPlotly({
    df <- ai_qerarlar %>% mutate(color = ifelse(status == "tesdiqlendi", c_accent,
                                ifelse(status == "redd_edildi", c_red, c_amber)))
    plot_ly(df, x = ~qerar_novu, y = ~eminlik, type = "bar",
            color = ~status, colors = c(c_accent, c_red, c_amber),
            hovertemplate = "%{x}: %{y}%<extra>%{status}</extra>") %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Eminlik %", range = c(0, 100)),
             legend = list(orientation = "h", y = -0.2), margin = list(b = 60))
  })

  # ---- AI log xərc ----
  output$ai_log_plot <- renderPlotly({
    df <- ai_loglar %>% group_by(agent) %>%
      summarise(tokens = sum(serf_olunan_tokens, na.rm = TRUE),
                xerc = sum(serf_olunan_xerc, na.rm = TRUE))
    plot_ly(df, x = ~agent, y = ~tokens, type = "bar",
            marker = list(color = c_teal), hovertemplate = "%{x}: %{y} token<extra></extra>") %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Token"),
             margin = list(b = 70))
  })

  # ---- AI tapşırıqlar cədvəl ----
  output$ai_teyinat_table <- DT::renderDataTable({
    dat <- ai_teyinatlar %>% select(teyinat_id, agent, teyinat_novu, status, tesdiq_status, netice_qiymeti)
    DT::datatable(dat, rownames = FALSE,
      options = list(pageLength = 6, dom = "t"),
      colnames = c("ID", "Agent", "Növ", "Status", "Təsdiq", "Qiymət"))
  })

  # ---- Proqnozlar cədvəl ----
  output$ai_prognoz_table <- DT::renderDataTable({
    dat <- ai_prognozlar %>% select(prognoz_novu, prognoz_deyer, ehtimal, doqruluk, layihe_kod)
    DT::datatable(dat, rownames = FALSE,
      options = list(pageLength = 6, dom = "t"),
      colnames = c("Növ", "Proqnoz", "Ehtimal %", "Dəqiqlik %", "Layihə")) %>%
      DT::formatRound(c("prognoz_deyer"), digits = 0)
  })

  # ---- Mesajlar cədvəl ----
  output$ai_mesaj_table <- DT::renderDataTable({
    dat <- ai_mesajlar %>% select(onem, movzu, oxunub, agent)
    DT::datatable(dat, rownames = FALSE,
      options = list(pageLength = 6, dom = "t"),
      colnames = c("Önəm", "Mövzu", "Oxunub", "Agent"))
  })

  # ---- Loglar cədvəl ----
  output$ai_log_table <- DT::renderDataTable({
    dat <- ai_loglar %>% select(hadise, agent, serf_olunan_tokens, serf_olunan_xerc)
    DT::datatable(dat, rownames = FALSE,
      options = list(pageLength = 6, dom = "t"),
      colnames = c("Hadisə", "Agent", "Token", "Xərc ₼")) %>%
      DT::formatRound("serf_olunan_xerc", digits = 3)
  })

  # ---- Standart sorğu ----
  sorgu_data <- reactive({
    id <- as.integer(input$sorqu_sec)
    info <- standart_sorgular[[which(sapply(standart_sorgular, function(x) x$id) == id)]]
    data <- q(info$sql)
    list(info = info, data = data)
  })

  output$sorqu_izah <- renderText({
    paste0("Məqsəd: ", sorgu_data()$info$izah)
  })

  output$sorqu_plot <- renderPlotly({
    d <- sorgu_data()$data
    tip <- sorgu_data()$info$qrafik
    if (is.null(d) || nrow(d) == 0 || ncol(d) == 0) return(plotly_empty())
    num_cols <- names(d)[sapply(d, is.numeric)]
    if (length(num_cols) == 0) return(plotly_empty())
    x_col <- num_cols[1]
    label_col <- setdiff(names(d), num_cols)[1]
    if (is.na(label_col)) label_col <- "label"

    if (tip == "pie") {
      plot_ly(d, labels = d[[label_col]], values = d[[x_col]], type = "pie",
              textinfo = "label+value",
              marker = list(colors = c(c_navy, c_accent, c_teal, c_amber, c_red, c_blue)))
    } else if (tip == "line") {
      plot_ly(d, x = d[[label_col]], y = d[[x_col]], type = "scatter", mode = "lines+markers",
              line = list(color = c_accent, width = 3), marker = list(color = c_accent, size = 8),
              fill = "tozeroy", fillcolor = "rgba(14,159,110,.12)")
    } else {
      plot_ly(d, x = d[[label_col]], y = d[[x_col]], type = "bar",
              marker = list(color = c_navy), hovertemplate = "%{x}: %{y:,.0f}<extra></extra>")
    }
  })

  output$sorqu_table <- DT::renderDataTable({
    DT::datatable(sorgu_data()$data, rownames = FALSE,
      options = list(pageLength = 8, dom = "t"))
  })

  # ---- Süni intellekt xidməti (chat) ----
  chat_history <- reactiveVal(list())
  chat_waiting <- reactiveVal(FALSE)
  chat_start_time <- reactiveVal(NULL)
  chat_elapsed <- reactiveVal(0)
  ds_key <- reactiveVal(cfg$DEEPSEEK_API_KEY %||% "")
  ds_connected <- reactiveVal(nchar(cfg$DEEPSEEK_API_KEY %||% "") > 0)

  # ---- Gözləmə sayğacı (elapsed timer) ----
  observe({
    if (chat_waiting()) {
      start <- chat_start_time()
      if (!is.null(start)) {
        invalidateLater(300, session)
        chat_elapsed(round(as.numeric(Sys.time() - start, units = "secs"), 1))
      }
    }
  })

  # ---- DeepSeek status UI ----
  output$ds_status <- renderUI({
    if (ds_connected()) {
      div(
        div(class = "badge-st st-hazir", "● DeepSeek: QOŞULU"),
        tags$div(style = "font-size:0.85rem; color:#0B7A55; margin-top:8px;",
          "AI ixtiyari suallarınıza canlı DeepSeek modeli ilə cavab verir.")
      )
    } else {
      div(
        div(class = "badge-st st-golecek", "○ DeepSeek: QOŞULMAYIB"),
        tags$div(style = "font-size:0.85rem; color:#64748B; margin-top:8px;",
          "API key daxil edib 'Qoşul' düyməsini basın. Qoşulmayanda baza üzrə lokal cavablar işləyir.")
      )
    }
  })

  output$ds_info <- renderUI({
    tags$div(style = "font-size:0.8rem; color:#94A3B8;",
      tags$div(tags$b("Model: "), cfg$DEEPSEEK_MODEL %||% "deepseek-chat"),
      tags$div(tags$b("URL: "), cfg$DEEPSEEK_BASE_URL %||% "https://api.deepseek.com"),
      tags$div(tags$b("Rejim: "), cfg$AI_MODE %||% "mock"),
      tags$div(tags$b("Key: "), if (ds_connected()) paste0(substr(ds_key(), 1, 6), "...") else "—")
    )
  })

  # ---- Qoşul / Ayır ----
  observeEvent(input$ds_qosul, {
    key <- trimws(input$ds_key_input)
    if (nchar(key) < 10) {
      showNotification("Zəhmət olmasa etibarlı DeepSeek API key daxil edin (sk-...)", type = "error")
      return()
    }
    # Test əlaqə
    showNotification("DeepSeek-ə qoşulur...", type = "message")
    test <- tryCatch({
      resp <- httr::GET(
        url = paste0(cfg$DEEPSEEK_BASE_URL %||% "https://api.deepseek.com", "/models"),
        httr::add_headers("Authorization" = paste("Bearer", key)),
        httr::timeout(15)
      )
      httr::status_code(resp) == 200
    }, error = function(e) FALSE)
    if (test) {
      ds_key(key); ds_connected(TRUE)
      # .env-yə yaz
      env_path <- "../../backend/.env"
      if (file.exists(env_path)) {
        env_lines <- readLines(env_path, warn = FALSE)
        env_lines <- sub("^DEEPSEEK_API_KEY=.*", paste0("DEEPSEEK_API_KEY=", key), env_lines)
        writeLines(env_lines, env_path)
      }
      showNotification("✅ DeepSeek qoşuldu! İndi ixtiyari sual verə bilərsiniz.", type = "message")
    } else {
      showNotification("❌ DeepSeek-ə qoşulmaq mümkün olmadı — key-i yoxlayın.", type = "error")
    }
  })

  observeEvent(input$ds_kes, {
    ds_key(""); ds_connected(FALSE)
    showNotification("DeepSeek ayırıldı. Lokal rejimə qayıdıldı.", type = "message")
  })

  # ---- Chat render ----
  output$chat_box <- renderUI({
    msgs <- chat_history()
    items <- lapply(msgs, function(m) {
      div(class = if (m$from == "user") "chat-user" else "chat-ai",
        HTML(m$text))
    })
    if (chat_waiting()) {
      items <- c(items, list(
        div(class = "chat-ai",
          tags$span(class = "spinner"), " ",
          tags$b("DeepSeek-ə qoşulur... "),
          tags$span(style = "color:#0E9F6E; font-weight:700;", chat_elapsed(), " san")
        )
      ))
    }
    if (length(items) == 0) {
      items <- list(div(class = "chat-ai",
        tags$b("Salam! 👋 "), "Mən DeepSeek-5 ERP-nin süni intellekt köməkçisiyəm. İxtiyari sual verə bilərsiniz — DeepSeek AI cavablayacaq."))
    }
    items
  })

  # ---- Sual göndər ----
  observeEvent(input$chat_gonder, {
    sual <- trimws(input$chat_sual)
    if (nchar(sual) == 0) return()
    updateTextInput(session, "chat_sual", value = "")

    user_msg <- list(from = "user", text = htmltools::htmlEscape(sual))
    chat_history(c(chat_history(), list(user_msg)))

    # Gözləmə başlat
    chat_waiting(TRUE)
    chat_start_time(Sys.time())
    chat_elapsed(0)

    # Cavabı hesabla (DeepSeek qoşulubsa ona göndər, yoxsa lokal)
    start <- Sys.time()
    cavab <- tryCatch(
      ai_cavab(sual, force_deepseek = ds_connected()),
      error = function(e) paste0("Xəta: ", conditionMessage(e))
    )
    muddet <- round(as.numeric(Sys.time() - start, units = "secs"), 1)

    # AI mesajı: cavab + müddət (yalnız real DeepSeek cavabında göstər)
    cavab_html <- as.character(cavab)
    deepseek_istifade <- ds_connected() && grepl("DeepSeek AI", cavab_html)
    nisane <- if (deepseek_istifade) {
      paste0('<span style="font-size:0.72rem; color:#94A3B8;">⏱ ', muddet, ' s · DeepSeek API</span>')
    } else {
      paste0('<span style="font-size:0.72rem; color:#94A3B8;">⏱ ', muddet, ' s</span>')
    }
    ai_msg <- list(from = "ai", text = paste0(cavab_html, "<br>", nisane))

    chat_waiting(FALSE)
    chat_start_time(NULL)
    chat_history(c(chat_history(), list(ai_msg)))
  })

  observeEvent(input$chat_temizle, {
    chat_history(list())
  })

  # ---- AI Pipeline Demo ----
  output$demo_netice <- renderUI({
    val <- demo_result()
    if (is.null(val)) {
      return(div(class = "chat-ai", "Tapşırıq icrasının nəticəsi burada görünəcək. Agent və tapşırıq növünü seçin, sonra 'İcra et' düyməsini basın."))
    }
    div(
      div(class = "chat-ai",
        tags$b("✅ Tapşırıq #", val$teyinat_id, " icra olundu"),
        tags$br(), tags$b("Nəticə JSON:"),
        tags$br(), tags$pre(style = "background:#F1F5F9; padding:10px; border-radius:8px; font-size:0.82rem;",
          toJSON(val$netice, auto_unbox = TRUE, pretty = TRUE)),
        tags$br(), tags$b("Nəticə qiyməti: ", val$qiymet, "/100")),
      tags$br(),
      div(class = "chat-ai",
        tags$b("🔄 Avtomatik yarandı:"),
        tags$ul(
          tags$li("ai_qerar — qərar təklifi (status='teklif')"),
          tags$li("ai_prognoz — proqnoz (budce_sapmasi üçün)"),
          tags$li("ai_mesaj — məlumat/əmr mesajı"),
          tags$li("ai_log — icra izi (token: 320, xərc: 0.045 ₼)")
        ))
    )
  })

  demo_result <- reactiveVal(NULL)

  observeEvent(input$demo_icra, {
    res <- ai_pipeline_icra(input$demo_agent, input$demo_nov,
                            list(plan_budce = 850000, xerc_umumi = 68700, progres = 60))
    demo_result(res)
    # Yenidən yüklə
    ai_teyinatlar <<- q("SELECT t.teyinat_id, t.teyinat_novu, t.status, t.tesdiq_status, t.netice_qiymeti, t.ustunluk, t.created_at, t.tamamlanma_tarixi, a.ad AS agent, a.vezife AS agent_vezife, l.kod AS layihe_kod FROM ai.ai_teyinat t JOIN ai.ai_agent a ON a.agent_id = t.agent_id LEFT JOIN layihe.layihe l ON l.layihe_id = t.layihe_id ORDER BY t.teyinat_id DESC")
    ai_qerarlar <<- q("SELECT q.qerar_id, q.qerar_novu, q.eminlik, q.status, q.esaslandirma, q.tesdiq_eden, q.created_at, a.ad AS agent FROM ai.ai_qerar q JOIN ai.ai_teyinat t ON t.teyinat_id = q.teyinat_id JOIN ai.ai_agent a ON a.agent_id = t.agent_id ORDER BY q.qerar_id DESC")
    ai_mesajlar <<- q("SELECT m.mesaj_id, m.movzu, m.mezmun, m.onem, m.oxunub, m.created_at, a.ad AS agent, l.kod AS layihe_kod FROM ai.ai_mesaj m JOIN ai.ai_agent a ON a.agent_id = m.agent_id LEFT JOIN layihe.layihe l ON l.layihe_id = m.layihe_id ORDER BY m.mesaj_id DESC")
    ai_loglar <<- q("SELECT l.log_id, l.hadise, l.mesaj, l.serf_olunan_tokens, l.serf_olunan_xerc, l.created_at, a.ad AS agent FROM ai.ai_log l JOIN ai.ai_agent a ON a.agent_id = l.agent_id ORDER BY l.log_id DESC")
  })

  output$demo_dongu <- renderPlotly({
    df <- data.frame(
      merhele = c("Yaranma", "İcra", "Nəticə", "Qərar", "Proqnoz", "Mesaj"),
      deyer = c(1, 2, 3, 2, 1, 2)
    )
    plot_ly(df, x = ~merhele, y = ~deyer, type = "bar",
            marker = list(color = c(c_navy, c_blue, c_accent, c_amber, c_teal, c_gray)),
            hovertemplate = "%{x}<extra></extra>") %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Hadisə sayı", showticklabels = FALSE),
             margin = list(b = 60))
  })
}

shinyApp(ui, server)
