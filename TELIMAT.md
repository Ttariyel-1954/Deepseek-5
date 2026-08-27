# 🏗️ DeepSeek-5 ERP — Tam Təkrarlama və İnkişaf Təlimatı

**Məqsəd:** Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi üçün qurulmuş
DeepSeek-5 ERP layihəsini istənilən AI agenti (Claude, DeepSeek) ilə **tam təkrarlamaq** və
istənilən aspekti **genişləndirmək** üçün addım-addım təlimat.

**Versiya:** 1.0 · **Tarix:** 2026-08-27 · **Müəllif:** DeepSeek-5 Komandası

---

## 📑 Mündəricat

1. [Layihənin xülasəsi](#1-layihənin-xülasəsi)
2. [Hazırkı vəziyyət (baseline)](#2-hazırkı-vəziyyət-baseline)
3. [Texnologiya yığını](#3-texnologiya-yığını)
4. [Sıfırdan təkrarlama — addım-addım](#4-sıfırdan-təkrarlama--addım-addım)
5. [AI agenti ilə işləmə qaydaları](#5-ai-agenti-ilə-işləmə-qaydaları)
6. [Genişləndirmə yol xəritəsi](#6-genişləndirmə-yol-xəritəsi)
7. [Doğrulama və keyfiyyət təminatı](#7-doğrulama-və-keyfiyyət-təminatı)
8. [Təhlükəsizlik və məxfilik](#8-təhlükəsizlik-və-məxfilik)
9. [GitHub-a yükləmə](#9-github-a-yükləmə)
10. [Fayl strukturu](#10-fayl-strukturu)

---

## 1. Layihənin xülasəsi

**DeepSeek-5 ERP** — Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı
Tikinti və Təchizat İdarəsinin fəaliyyətini rəqəmsallaşdıran tam inteqrasiya olunmuş idarəetmə
sistemidir. İdarə təhsil müəssisələrində tikinti-quraşdırma, əsaslı/cari təmir, dövlət satınalmaları
(tender), layihə-smeta sənədləri, material təchizatı və maliyyə əməliyyatlarını idarə edir.

**Əsas xüsusiyyət:** Sistem **AI ilə tam idarə olunur** — süni intellekt (DeepSeek + Anthropic Claude)
proqnozlar verir, tövsiyələr edir, qərarlar qəbul edir və öz nəticəsini ölçür.

### Nə edir:
- **Mərkəzləşdirilmiş idarəetmə** — bütün proseslər vahid platformada
- **Şəffaflıq** — tender, müqavilə, xərc və ödənişlərin tam izlənməsi
- **Analitika** — real vaxt hesabatları və interaktiv qrafiklər
- **AI idarəetmə** — agentlər, tapşırıqlar, proqnozlar, qərarlar, mesajlar
- **Avtomatlaşdırma** — sənəd axını, risk nəzarəti, keyfiyyət yoxlaması

---

## 2. Hazırkı vəziyyət (baseline)

### Verilənlər bazası — `deepseek_erp_v6`
| Metrik | Dəyər |
|--------|-------|
| Sxemlər | **13** (ref, layihe, satinalma, maliyye, kadr, hesabat + ai, sened, risk, keyfiyyet, logistika, tehlike, audit) |
| Cədvəllər | **48** |
| Funksiyalar | **18** (PL/pgSQL) |
| Triggerlər | **32** |
| View-lər | **13** (hesabat sxemi) |
| Seed məlumatlar | 5 layihə, 8 işçi, 2 müqavilə, 3 tender, 9 AI tapşırığı, 6 qərar, 6 proqnoz, 6 mesaj, 6 log |

### Backend — Express.js
- **7 əsas modul:** layihe, tender, muqavile, xerc, odenis, isci, user
- **AI modulu:** 12 endpoint (`/api/ai/...` — modeller, agentler, teyinatlar, qerarlar, proqnozlar, mesajlar, loglar)
- **2 AI provider:** DeepSeek + Anthropic Claude (`aiService.js`), `AI_MODE=mock|live`
- **5 middleware:** auth (JWT), errorHandler, logger (Winston), validator, rateLimiter
- **Testlər:** Jest 12/12 passed (5 suite)

### Frontend — React 19
- Login, Dashboard, Layihələr, Tenderlər, **AI Paneli**
- React Query + Axios + Tailwind 4
- Vite build uğurlu

### Sənədlər və təqdimat
- **8 geniş dərs** (`docs/lessons/`) — yaradılma prosesinin tam təkrarlanması
- **Shiny AI app** (`docs/presentation/app.R`) — AI fəaliyyəti + 10 sorğu + sərbəst sual-cavab (real DeepSeek API)
- **36 AI nümayiş sorğusu** (`database/05_ai_nuyis_sorgular.sql`)

---

## 3. Texnologiya yığını

| Qat | Texnologiya | Versiya | Vəzifəsi |
|-----|-------------|---------|----------|
| Verilənlər bazası | PostgreSQL | 18 | Məlumatların saxlanması, ACID, JSONB |
| Backend | Node.js | 24 LTS | JavaScript runtime |
| Backend Framework | Express.js | 4.21 | RESTful API, routing, middleware |
| Autentifikasiya | JWT + bcryptjs | 9.0 / 2.4 | Token əsaslı giriş, şifrə heşlənməsi |
| DB Driver | node-postgres (pg) | 8.13 | PostgreSQL Pool |
| AI (DeepSeek) | DeepSeek API | — | `deepseek-chat`, `deepseek-reasoner` |
| AI (Claude) | Anthropic API | — | `claude-opus-5`, `claude-sonnet-5`, `claude-haiku-4.5` |
| HTTP AI | axios | 1.7 | LLM API çağırışları |
| Təhlükəsizlik | helmet, cors | 8.0 / 2.8 | HTTP başlıqları, CORS |
| Loglama | Winston + morgan | 3.17 / 1.10 | Fayl + konsol logları |
| Validation | express-validator | 7.2 | Giriş doğrulaması |
| Frontend | React | 19 | İstifadəçi interfeysi |
| Build | Vite | 6 | Dev server + build |
| UI | Tailwind CSS | 4 | Utility-first CSS |
| State | React Query | 5.60 | Server state idarəsi |
| Test | Jest + Supertest | 29 / 7 | Unit + inteqrasiya |

---

## 4. Sıfırdan təkrarlama — addım-addım

> **Bu bölmə istənilən AI agentinə (Claude/DeepSeek) "kontrakt" kimi verilə bilər.**
> Agentə aşağıdakıları verin və o, layihəni tam quracaq.

### Mərhələ 0 — Mühitin hazırlanması
```bash
# 1. PostgreSQL 18
brew install postgresql@18
brew services start postgresql@18

# 2. Node.js 24 LTS
brew install node@24
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"

# 3. Qovluq strukturu
mkdir -p ~/Desktop/DeepSeek-5/{backend/{src/{config,models,controllers,routes,middlewares,services,utils,validators},tests/{unit,integration},logs},frontend/{public,src/{components,pages,services,utils}},database/{schemas,seeds,migrations,backups},docs/{lessons,api,architecture},scripts/{deployment,backup}}

# 4. PostgreSQL baza yarat
psql -h localhost -p 5432 -U deepseek_admin -d postgres -c "CREATE DATABASE deepseek_erp_v6 OWNER deepseek_admin;"
```

### Mərhələ 1 — Verilənlər bazası (SQL)
1. **`database/00_drop_all.sql`** — 13 sxemi sil
2. **`database/schemas/01_create_tables.sql`** — 6 əsas sxem, 22 cədvəl (ref, layihe, satinalma, maliyye, kadr, hesabat)
3. **`database/schemas/02_create_tables_ek.sql`** — 7 yeni sxem, 26 cədvəl (ai, sened, risk, keyfiyyet, logistika, tehlike, audit)
4. **`database/schemas/03_functions_triggers.sql`** — 18 funksiya, 32 trigger
5. **`database/migrations/002_create_users.sql`** — `auth.users` cədvəli
6. **`database/migrations/005_add_progres.sql`** — `layihe.progres` kolonu
7. **`database/schemas/04_views.sql`** — 13 view (hesabat sxemi)
8. **`database/seeds/02_seed_data.sql`** — əsas seed
9. **`database/seeds/03_seed_new_tables.sql`** — AI/sənəd/risk seed

**İcra qaydası:** `00 → 01 → 02 → 03 → migrations → 04 → seeds`
**Vacib:** 04 (views) migration-dan **sonra** icra edin (`progres` kolonu tələb olunur).

### Mərhələ 2 — Admin və AI konfiqurasiyası
```sql
-- Admin istifadəçi (şifrə: admin123, bcrypt hash ilə)
INSERT INTO auth.users (username, email, password_hash, full_name, role)
VALUES ('admin', 'admin@deepseek5.az', '<bcrypt_hash>', 'Sistem Administratoru', 'admin');

-- AI modelləri (5)
INSERT INTO ai.ai_model (ad, provider, model_ref, rolu) VALUES
('DeepSeek Chat', 'deepseek', 'deepseek-chat', 'assistent'),
('DeepSeek Reasoner', 'deepseek', 'deepseek-reasoner', 'analitik'),
('Claude Opus 5', 'anthropic', 'claude-opus-5', 'nezaretci'),
('Claude Sonnet 5', 'anthropic', 'claude-sonnet-5', 'analitik'),
('Claude Haiku 4.5', 'anthropic', 'claude-haiku-4-5-20251001', 'assistent');
```

### Mərhələ 3 — Backend (Express + AI)
1. `backend/package.json` — asılılıqlar + scripts
2. `backend/.env` — PORT=5001, DB, JWT, DEEPSEEK_*, ANTHROPIC_*, AI_MODE=mock
3. `src/config/db.js` — pg Pool
4. `src/config/auth.js` — JWT + bcrypt
5. `src/services/aiService.js` — callDeepSeek + callAnthropic + mock mode
6. `src/services/promptBuilder.js` — AZ prompt şablonları
7. 8 model (layihe, tender, muqavile, xerc, odenis, isci, user, ai)
8. 8 controller (6 CRUD + auth + ai)
9. 8 route (bütün əsas + /api/ai)
10. 5 middleware (auth, errorHandler, logger, validator, rateLimiter)
11. `src/app.js` + `src/server.js`

### Mərhələ 4 — Frontend (React)
1. `frontend/package.json` — react 19, vite 6, tailwind 4
2. `frontend/vite.config.js` — port 5174, proxy `/api` → `:5001`
3. `src/services/api.js` — axios + JWT interceptor
4. `src/utils/auth.js`, `format.js`
5. Login, Dashboard, Layihələr, Tenderlər, **AiPaneli**
6. `src/components/Layout.jsx`, `Header.jsx`, `App.jsx`

### Mərhələ 5 — Sənədlər və təqdimat
1. 8 dərs HTML (`docs/lessons/`)
2. Shiny AI app (`docs/presentation/app.R`)
3. 36 AI nümayiş sorğusu (`database/05_ai_nuyis_sorgular.sql`)

### Mərhələ 6 — Doğrulama
```bash
# Backend testlər
cd ~/Desktop/DeepSeek-5/backend && npm install && npm test  # → 12/12 passed

# Frontend build
cd ~/Desktop/DeepSeek-5/frontend && npm install && npm run build

# API test
cd ~/Desktop/DeepSeek-5/backend && npm start
curl http://localhost:5001/api/health
curl -X POST http://localhost:5001/api/auth/login -H "Content-Type: application/json" -d '{"usernameOrEmail":"admin","password":"admin123"}'
curl http://localhost:5001/api/ai/status -H "Authorization: Bearer <token>"

# AI sorğular
psql -h localhost -p 5432 -U deepseek_admin -d deepseek_erp_v6 -f database/05_ai_nuyis_sorgular.sql
```

---

## 5. AI agenti ilə işləmə qaydaları

> Bu bölmə **Claude** və **DeepSeek** agentləri ilə effektiv işləmək üçün.

### 5.1. Tapşırıq "kontrakt"ı necə yazılmalı
Hər agent tapşırığı aşağıdakıları **mütləq** ehtiva etməlidir:
- **Kontekst:** layihənin adı, məqsədi, istifadəçi (Təhsil Nazirliyi İdarəsi)
- **Fayl yolları:** dəqiq qovluqlar (`/Users/.../DeepSeek-5/backend`)
- **Mövcud qaydalar:** "DB sxemini oxu", "real API-yə uyğun yaz"
- **Texnologiya/versiyalar:** express ^4.21.2, pg ^8.13.1 və s.
- **Qadağalar:** ".env-i dəyişmə!", "backend qovluğuna toxunma!"
- **Doğrulama tələbi:** "npm test qaçır, curl ilə yoxla, nəticəni bildir"

### 5.2. Nümunə agent tapşırığı (copy-paste üçün)

> **Tapşırıq:** DeepSeek-5 ERP backend-i yaz.
> **Qovluq:** /Users/royatalibova/Desktop/DeepSeek-5/backend (boş strukturu hazırdır)
> **DB:** deepseek_erp_v6, localhost:5432, deepseek_admin/Deepseek2026
> **Kontekst:** Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi üçün ERP.
> **Mütləq oxu:** database/schemas/01_create_tables.sql və 02_create_tables_ek.sql (48 cədvəl, 13 sxem)
> **Yaradacağın:** package.json, src/config/{db,auth}.js, src/services/{aiService,promptBuilder}.js,
> 8 model, 8 controller, 8 route, 5 middleware, src/app.js, src/server.js, testlər (12/12 passed).
> **AI service:** həm DeepSeek həm Anthropic Claude provider, AI_MODE=mock rejimi.
> **Qadağa:** .env-i dəyişmə! Yalnız faylları yaz, npm install + test qaçır, doğrula.
> **Son hesabat:** fayl siyahısı, test nəticəsi, AI endpoint testi.

### 5.3. Paralel agentlərlə işləmə
- **Fərqli qovluqlarda** işləyən agentlər paralel işlədilə bilər:
  - Agent A → backend
  - Agent B → frontend
  - Agent C → docs
- **Eyni faylda** işləyən agentlər əsla paralel işləməməlidir (konflikt olur).

### 5.4. Nəticələrin doğrulanması
- Agentin iddialarına **kor-korana inanma!**
- Testləri özün qaçır, curl ilə yoxla, DB sorğuları ilə təsdiqlə
- Agent "10/10 passed" dedi → özün də `npm test` qaçır
- Agent "API işləyir" dedi → özün `curl` et

---

## 6. Genişləndirmə yol xəritəsi

> Layihənin inkişaf etdirilməsi üçün prioritetlər.

### 🟢 Faza 1 — AI idarəetmə qatının tam işləməsi (M1-M4)
- [ ] AI tapşırıqların **real LLM ilə icrası** (AI_MODE=live)
- [ ] **Prompt optimallaşdırma** — hər tapşırıq növü üçün dəqiq prompt
- [ ] **AI Paneli** tam interaktiv — təsdiq/redd axını
- [ ] **Proqnoz dəqiqliyi** ölçülməsi (`doqruluk` kolonu)

### 🟡 Faza 2 — Avtomatlaşdırmanın artırılması (M5)
- [ ] **Eminlik ≥90%** olduqda qərarın avtomatik təsdiqi
- [ ] **Məbləğ limitləri** və kritik istisnalar
- [ ] **Geri qaytarma (rollback)** mexanizmi
- [ ] Avtomatik icra **audit izi**

### 🟠 Faza 3 — Məlumat keyfiyyəti və özünü-öyrənmə (M6)
- [ ] Proqnoz vs real müqayisə dashboard
- [ ] **Prompt versiyalama** və A/B testi
- [ ] İstifadəçi feedback-i (faydalı oldu?)
- [ ] Aylıq AI hesabatı (doğruluq + xərc + avtomatlaşdırma %)

### 🔴 Faza 4 — Tam avtomatlaşdırma (M7)
- [ ] Rutin qərarların **tam AI icrası**
- [ ] **Kill-switch** (emergency stop) mexanizmi
- [ ] Kritik məbləğ limitləri (ödəniş/müqavilə → heç vaxt avtomatik)

### 🟣 Faza 5 — Deployment və nəzarət (M8)
- [ ] PM2 + Nginx + SSL
- [ ] Docker + docker-compose
- [ ] CI/CD (GitHub Actions)
- [ ] Cron backup + restore testi
- [ ] Monitoring dashboard

### Yeni funksiya əlavə etmək istəyirsinizsə:
1. **SQL:** yeni cədvəl → migration faylı → seed
2. **Backend:** yeni model → controller → route → app.js
3. **Frontend:** yeni səhifə → App.jsx route → Header link
4. **AI:** yeni tapşırıq növü → promptBuilder → aiModel → aiController
5. **Test:** yeni suite → `npm test`
6. **Doğrula:** curl + DB + build

---

## 7. Doğrulama və keyfiyyət təminatı

### Səviyyə 1 — Baza doğrulaması
```sql
-- Cədvəl/funksiya/trigger/view sayları
SELECT schemaname, count(*) FROM pg_tables
WHERE schemaname IN ('ref','layihe','satinalma','maliyye','kadr','hesabat','ai','sened','risk','keyfiyyet','logistika','tehlike','audit')
GROUP BY schemaname;
-- Gözlənilən: 48 cədvəl, 18 funksiya, 32 trigger, 13 view
```

### Səviyyə 2 — API doğrulaması
```bash
# Health
curl http://localhost:5001/api/health
# → {"status":"ok","db":"ok",...}

# Auth
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"admin","password":"admin123"}'
# → token

# AI status
curl http://localhost:5001/api/ai/status -H "Authorization: Bearer <token>"
```

### Səviyyə 3 — AI axın doğrulaması
```bash
# Tapşırıq yarat
curl -X POST http://localhost:5001/api/ai/teyinatlar \
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"agent_id":1,"teyinat_novu":"budce_prognozu","giris_json":{"plan_budce":850000}}'

# İcra et
curl -X POST http://localhost:5001/api/ai/teyinatlar/<id>/icra -H "Authorization: Bearer <token>"
# → cixis_json dolu, status='hazir', ai_log yarandı
```

### Səviyyə 4 — Testlər
```bash
cd ~/Desktop/DeepSeek-5/backend && npm test  # → 12/12 passed
cd ~/Desktop/DeepSeek-5/frontend && npm run build  # → uğurlu
```

---

## 8. Təhlükəsizlik və məxfilik

### ⚠️ KRİTİK QAYDALAR
1. **`.env` faylını heç vaxt GitHub-a yükləmə!** (`.gitignore`-da var)
2. **API açarları** (DEEPSEEK, ANTHROPIC) yalnız `.env`-də saxlanılır
3. **Real məlumatları xarici LLM API-yə göndərmə!** (FIN, VOEN, maaş) — anonimləşdirmə tələb olunur
4. **Parollar** yalnız bcrypt hash ilə saxlanır
5. **JWT secret** güclü və təsadüfi olmalıdır

### Məxfilik
- `DEEPSEEK_API_KEY`, `ANTHROPIC_API_KEY` — həssas məlumat, sızmamalıdır
- Söhbət tarixçəsində key yazmayın — .env-yə birbaşa yazın
- Məlumat bazasına giriş yalnız səlahiyyətli istifadəçilərə

### AI anonimləşdirmə nümunəsi
```
Layihə adı: L-2026-001 (kod kifayətdir, ad göndərməyin)
İşçi: FIN0001 əvəzinə "işçi_1"
Maaş: 4800 əvəzinə "yüksək"
```

---

## 9. GitHub-a yükləmə

### 9.1. İlk yükləmə (repo yoxdursa)
```bash
cd ~/Desktop/DeepSeek-5

# Git init
git init
git add .
git commit -m "DeepSeek-5 ERP — AI ilə Tam İdarəolunan Sistem v1.0"

# GitHub repo yarat (gh CLI ilə, əvvəlcə login olun: gh auth login)
gh auth login
gh repo create DeepSeek-5 --public --source=. --push

# Yaxud əl ilə:
# 1. github.com-da boş repo yaradın
# 2. git remote add origin https://github.com/<istifadəci>/DeepSeek-5.git
# 3. git push -u origin main
```

### 9.2. Sonrakı yeniləmələr
```bash
cd ~/Desktop/DeepSeek-5
git add .
git commit -m "Yeniləmə: <nə dəyişdi>"
git push
```

### 9.3. Vacib
- **`git status`** ilə hər dəfə `.env`-in yüklənmədiyini yoxlayın:
  ```bash
  git status | grep .env
  # → backend/.env görünməməlidir
  ```
- `.gitignore`-a əlavə edin: `backend/.env`, `frontend/.env`, `*.log`
- Təlimatı da repoya yükləyin:
  ```bash
  git add TELIMAT.md
  git commit -m "Əlavə: Təkrarlama və inkişaf təlimatı"
  git push
  ```

---

## 10. Fayl strukturu

```
DeepSeek-5/
├── backend/                  # Express + AI backend
│   ├── src/
│   │   ├── config/           # db.js (Pool), auth.js (JWT+bcrypt)
│   │   ├── models/           # 8 model (layihe...ai)
│   │   ├── controllers/      # 8 controller (CRUD + auth + ai)
│   │   ├── routes/           # 8 route (əsas + /api/ai)
│   │   ├── middlewares/      # auth, errorHandler, logger, validator, rateLimiter
│   │   ├── services/         # aiService (DeepSeek+Claude), promptBuilder
│   │   └── app.js, server.js
│   ├── tests/                # unit + integration (12 test)
│   ├── .env                  # ⚠️ GİTHUB-A YÜKLƏMƏ!
│   └── package.json
├── frontend/                 # React 19 + Vite 6
│   ├── src/
│   │   ├── pages/            # Login, Dashboard, Layiheler, Tenderler, AiPaneli
│   │   ├── components/       # Layout, Header
│   │   ├── services/         # api.js
│   │   └── utils/            # auth.js, format.js
│   └── package.json
├── database/                 # SQL
│   ├── schemas/              # 01, 02 (cədvəllər), 03 (funksiya/trigger), 04 (views)
│   ├── migrations/           # 002 (users), 005 (progres)
│   ├── seeds/                # 02 (əsas), 03 (AI/sənəd)
│   ├── 00_drop_all.sql       # təmiz silmə
│   ├── 03_test_queries.sql   # əsas analitik sorğular
│   ├── 04_analitik_sorgular.sql
│   └── 05_ai_nuyis_sorgular.sql  # 36 AI nümayiş sorğusu
├── docs/
│   ├── lessons/              # 8 geniş dərs HTML
│   ├── presentation/         # app.R (Shiny AI app)
│   ├── api/                  # (boş — doldurulmalı)
│   └── architecture/         # (boş — doldurulmalı)
├── scripts/
│   ├── deployment/           # init_db.sh
│   └── backup/
├── TELIMAT.md                # bu fayl
├── README.md
└── .gitignore
```

---

## 📌 Yekun qeydlər

1. **Bu təlimat "canlı" sənəddir** — layihə genişləndikcə yeniləyin.
2. **Dərslər əsas mənbədir** — `docs/lessons/` yaradılma prosesinin tam izahıdır.
3. **AI agentə verməzdən əvvəl:** lazımi konteksti, fayl yollarını və doğrulama tələbini qeyd edin.
4. **Hər yeni funksiyadan sonra:** doğrulayın (test + curl + DB), sənədləşdirin, GitHub-a itələyin.
5. **Təhlükəsizlik hər şeydən önəmlidir:** `.env`, API açarları, real məlumatlar.

**Son yenilənmə:** 27 Avqust 2026 · **Versiya:** 1.0
