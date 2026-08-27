#!/bin/bash
# =====================================================================
#  DeepSeek-5 ERP — Tam Mühit Başlatma Skripti
#  Terminal/kokmpüter yenidən başladıqdan sonra hər şeyi qaldırır.
#  İstifadə: bash scripts/start_environment.sh
# =====================================================================
set -e

echo "======================================"
echo "  DeepSeek-5 ERP — Mühit Başladılır"
echo "======================================"

# ---------- 1. PostgreSQL PATH ----------
echo ""
echo "[1/6] PostgreSQL PATH-ə əlavə edilir..."
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
if command -v psql > /dev/null 2>&1; then
  echo "  ✅ psql: $(psql --version)"
else
  echo "  ❌ psql tapılmadı — postgresql@18 düzgün quraşdırılmayıb?"
fi

# ---------- 2. PostgreSQL xidməti ----------
echo ""
echo "[2/6] PostgreSQL xidməti yoxlanılır..."
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
  echo "  ✅ PostgreSQL artıq işləyir"
else
  echo "  ⏳ PostgreSQL başladılır..."
  brew services start postgresql@18
  sleep 3
  pg_isready -h localhost -p 5432 && echo "  ✅ PostgreSQL hazır" || echo "  ❌ PostgreSQL başlamadı!"
fi

# ---------- 3. Node.js ----------
echo ""
echo "[3/6] Node.js yoxlanılır..."
if command -v node > /dev/null 2>&1; then
  echo "  ✅ Node.js: $(node -v)"
else
  echo "  ⏳ Node.js PATH-ə əlavə edilir..."
  export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
  echo "  ✅ Node.js: $(node -v)"
fi

# ---------- 4. Məlumat bazası yoxlanılır ----------
echo ""
echo "[4/6] Məlumat bazası yoxlanılır..."
export PGPASSWORD='Deepseek2026'
if psql -h localhost -p 5432 -U deepseek_admin -d deepseek_erp_v6 -c "SELECT 1" > /dev/null 2>&1; then
  echo "  ✅ deepseek_erp_v6 bazası mövcuddur"
else
  echo "  ⚠️  Baza tapılmadı — sıfırdan qurulur..."
  psql -h localhost -p 5432 -U deepseek_admin -d postgres -c "CREATE DATABASE deepseek_erp_v6 OWNER deepseek_admin;"
  echo "  ✅ Baza yaradıldı"
fi

# ---------- 5. Backend ----------
echo ""
echo "[5/6] Backend başladılır..."
cd ~/Desktop/DeepSeek-5/backend
if [ ! -d node_modules ]; then
  echo "  ⏳ npm install..."
  npm install --silent
fi
# Əgər artıq işləyirsə, dayandır və yenidən başlat
if lsof -i :5001 > /dev/null 2>&1; then
  echo "  ⚠️  Port 5001 işğal olunub — yenidən başladılır"
  lsof -ti :5001 | xargs kill 2>/dev/null || true
  sleep 1
fi
nohup npm start > logs/server.log 2>&1 &
sleep 2
echo "  ✅ Backend başladı (port 5001) — log: logs/server.log"

# ---------- 6. Shiny AI App ----------
echo ""
echo "[6/6] Shiny AI app başladılır..."
if curl -s http://127.0.0.1:3839 > /dev/null 2>&1; then
  echo "  ✅ Shiny artıq işləyir (port 3839)"
else
  nohup Rscript -e "shiny::runApp('/Users/royatalibova/Desktop/DeepSeek-5/docs/presentation', port=3839, host='127.0.0.1', launch.browser=FALSE)" > /tmp/deepseek5_shiny.log 2>&1 &
  sleep 3
  echo "  ✅ Shiny başladı (port 3839) — http://localhost:3839"
fi

echo ""
echo "======================================"
echo "  ✅ Mühit HAZIR!"
echo "  Backend:  http://localhost:5001/api/health"
echo "  Shiny:    http://localhost:3839"
echo "  Giriş:    admin / admin123"
echo "======================================"
echo ""
echo "  Qeyd: Frontend üçün (ayrıca):"
echo "  cd ~/Desktop/DeepSeek-5/frontend && npm run dev"
echo ""
