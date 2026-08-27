#!/bin/bash
# =====================================================================
#  DeepSeek-5 ERP — Verilənlər Bazasını Sıfırdan Qurma Skripti
#  DİQQƏT: Mövcud bütün sxemləri silir və yenidən qurur!
#  13 sxem · 48 cədvəl · 18 funksiya · 32 trigger · 13 view
#  İstifadə: FORCE=1 ./scripts/deployment/init_db.sh [baza_adi]
# =====================================================================
set -euo pipefail

DB_NAME="${1:-deepseek_erp_v6}"
DB_USER="${DB_USER:-deepseek_admin}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_DIR="$(cd "$(dirname "$0")/../../database" && pwd)"

if [ "${FORCE:-0}" != "1" ]; then
  echo "⚠️  Bu skript mövcud bütün məlumatları SİLƏCƏK!"
  echo "   Davam etmək üçün: FORCE=1 ./scripts/deployment/init_db.sh"
  exit 1
fi

echo "⏳ Baza sıfırlanır: ${DB_NAME}"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/00_drop_all.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/schemas/01_create_tables.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/schemas/02_create_tables_ek.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/schemas/03_functions_triggers.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/migrations/002_create_users.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/migrations/005_add_progres.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/schemas/04_views.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/seeds/02_seed_data.sql"
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DB_DIR}/seeds/03_seed_new_tables.sql"
echo "✅ Baza hazırdır: ${DB_NAME} (13 sxem · 48 cədvəl)"
echo "   Sonra: admin istifadəçi + AI model/agent əlavə edin (docs/ders_01-də izah)"
