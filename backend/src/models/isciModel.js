/**
 * isciModel — kadr sxemindəki işçi cədvəlləri üçün model qatı
 * Cədvəllər: kadr.isci, kadr.vezife
 */
const db = require('../config/db');

async function getIsciler({ status } = {}) {
  const conditions = [];
  const params = [];

  if (status) {
    params.push(status);
    conditions.push(`i.status = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await db.query(
    `SELECT i.isci_id, i.vezife_id, i.ad_soyad, i.fin, i.seriya_no, i.dogum_tarixi,
            i.telefon, i.email, i.maas, i.ise_bashlama, i.isden_ayrilma, i.status,
            i.created_at, i.updated_at,
            v.ad AS vezife_ad
     FROM kadr.isci i
     LEFT JOIN kadr.vezife v ON v.vezife_id = i.vezife_id
     ${where}
     ORDER BY i.isci_id DESC`,
    params
  );
  return rows;
}

async function getIsci(id) {
  const { rows } = await db.query(
    `SELECT i.*, v.ad AS vezife_ad
     FROM kadr.isci i
     LEFT JOIN kadr.vezife v ON v.vezife_id = i.vezife_id
     WHERE i.isci_id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function createIsci(data) {
  const {
    vezife_id, ad_soyad, fin, seriya_no, dogum_tarixi, telefon, email,
    maas, ise_bashlama, isden_ayrilma, status,
  } = data;

  const { rows } = await db.query(
    `INSERT INTO kadr.isci
       (vezife_id, ad_soyad, fin, seriya_no, dogum_tarixi, telefon, email, maas, ise_bashlama, isden_ayrilma, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING *`,
    [vezife_id, ad_soyad, fin || null, seriya_no || null, dogum_tarixi || null, telefon || null, email || null, maas || 0, ise_bashlama || null, isden_ayrilma || null, status || 'aktiv']
  );
  return rows[0];
}

async function updateIsci(id, data) {
  const allowed = ['vezife_id', 'ad_soyad', 'fin', 'seriya_no', 'dogum_tarixi', 'telefon', 'email', 'maas', 'ise_bashlama', 'isden_ayrilma', 'status'];
  const setCols = [];
  const params = [];

  allowed.forEach((col) => {
    if (data[col] !== undefined) {
      params.push(data[col]);
      setCols.push(`${col} = $${params.length}`);
    }
  });

  if (!setCols.length) return null;

  params.push(id);
  setCols.push('updated_at = NOW()');

  const { rows } = await db.query(
    `UPDATE kadr.isci SET ${setCols.join(', ')}
     WHERE isci_id = $${params.length}
     RETURNING *`,
    params
  );
  return rows[0] || null;
}

async function deleteIsci(id) {
  const { rows } = await db.query(
    `UPDATE kadr.isci SET status = 'passiv', isden_ayrilma = CURRENT_DATE, updated_at = NOW()
     WHERE isci_id = $1
     RETURNING *`,
    [id]
  );
  return rows[0] || null;
}

// ============================================================
// VƏZİFƏLƏR
// ============================================================
async function getVezifeler() {
  const { rows } = await db.query(
    `SELECT vezife_id, ad, maas_alt, maas_ust, qeyd, aktif FROM kadr.vezife ORDER BY vezife_id`
  );
  return rows;
}

module.exports = { getIsciler, getIsci, createIsci, updateIsci, deleteIsci, getVezifeler };
