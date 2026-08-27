/**
 * tenderModel — satinalma sxemindəki tender cədvəlləri üçün model qatı
 * Cədvəllər: satinalma.tender, satinalma.tender_istirakci
 */
const db = require('../config/db');

async function getTenderler({ status_id } = {}) {
  const conditions = [];
  const params = [];

  if (status_id) {
    params.push(status_id);
    conditions.push(`t.status_id = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await db.query(
    `SELECT t.tender_id, t.layihe_id, t.status_id, t.kod, t.ad, t.elan_tarixi, t.son_tarix,
            t.qiymet_serhedi, t.qalib_istirakci_id, t.qeyd, t.created_at, t.updated_at,
            s.ad AS status_ad, s.kod AS status_kod,
            l.ad AS layihe_ad, l.kod AS layihe_kod,
            (SELECT COUNT(*) FROM satinalma.tender_istirakci ti WHERE ti.tender_id = t.tender_id) AS istirakci_sayi,
            (SELECT MIN(ti.teklif_mebleg) FROM satinalma.tender_istirakci ti WHERE ti.tender_id = t.tender_id) AS en_asagi_teklif
     FROM satinalma.tender t
     LEFT JOIN satinalma.tender_status s ON s.status_id = t.status_id
     LEFT JOIN layihe.layihe l ON l.layihe_id = t.layihe_id
     ${where}
     ORDER BY t.created_at DESC`,
    params
  );
  return rows;
}

async function getTender(id) {
  const { rows } = await db.query(
    `SELECT t.*, s.ad AS status_ad, s.kod AS status_kod, l.ad AS layihe_ad, l.kod AS layihe_kod
     FROM satinalma.tender t
     LEFT JOIN satinalma.tender_status s ON s.status_id = t.status_id
     LEFT JOIN layihe.layihe l ON l.layihe_id = t.layihe_id
     WHERE t.tender_id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function createTender(data) {
  const {
    layihe_id, status_id, kod, ad, elan_tarixi, son_tarix, qiymet_serhedi, qalib_istirakci_id, qeyd,
  } = data;

  const { rows } = await db.query(
    `INSERT INTO satinalma.tender
       (layihe_id, status_id, kod, ad, elan_tarixi, son_tarix, qiymet_serhedi, qalib_istirakci_id, qeyd)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING *`,
    [layihe_id, status_id || 1, kod || null, ad, elan_tarixi || null, son_tarix || null, qiymet_serhedi || 0, qalib_istirakci_id || null, qeyd || null]
  );
  return rows[0];
}

async function updateTender(id, data) {
  const allowed = ['layihe_id', 'status_id', 'kod', 'ad', 'elan_tarixi', 'son_tarix', 'qiymet_serhedi', 'qalib_istirakci_id', 'qeyd'];
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
    `UPDATE satinalma.tender SET ${setCols.join(', ')}
     WHERE tender_id = $${params.length}
     RETURNING *`,
    params
  );
  return rows[0] || null;
}

async function deleteTender(id) {
  const { rows } = await db.query(
    `DELETE FROM satinalma.tender WHERE tender_id = $1 RETURNING *`,
    [id]
  );
  return rows[0] || null;
}

// ============================================================
// İŞTİRAKÇILAR
// ============================================================
async function getIstirakciler(tender_id) {
  const { rows } = await db.query(
    `SELECT * FROM satinalma.tender_istirakci
     WHERE tender_id = $1
     ORDER BY teklif_mebleg ASC`,
    [tender_id]
  );
  return rows;
}

async function createIstirakci(tender_id, data) {
  const { sirket_ad, voen, teklif_mebleg, teklif_tarixi, qalib, qeyd } = data;
  const { rows } = await db.query(
    `INSERT INTO satinalma.tender_istirakci (tender_id, sirket_ad, voen, teklif_mebleg, teklif_tarixi, qalib, qeyd)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [tender_id, sirket_ad, voen || null, teklif_mebleg || 0, teklif_tarixi || null, qalib || false, qeyd || null]
  );
  return rows[0];
}

async function updateIstirakci(istirakci_id, data) {
  const allowed = ['sirket_ad', 'voen', 'teklif_mebleg', 'teklif_tarixi', 'qalib', 'qeyd'];
  const setCols = [];
  const params = [];

  allowed.forEach((col) => {
    if (data[col] !== undefined) {
      params.push(data[col]);
      setCols.push(`${col} = $${params.length}`);
    }
  });

  if (!setCols.length) return null;

  params.push(istirakci_id);

  const { rows } = await db.query(
    `UPDATE satinalma.tender_istirakci SET ${setCols.join(', ')}
     WHERE istirakci_id = $${params.length}
     RETURNING *`,
    params
  );
  return rows[0] || null;
}

async function deleteIstirakci(istirakci_id) {
  const { rows } = await db.query(
    `DELETE FROM satinalma.tender_istirakci WHERE istirakci_id = $1 RETURNING *`,
    [istirakci_id]
  );
  return rows[0] || null;
}

module.exports = {
  getTenderler, getTender, createTender, updateTender, deleteTender,
  getIstirakciler, createIstirakci, updateIstirakci, deleteIstirakci,
};
