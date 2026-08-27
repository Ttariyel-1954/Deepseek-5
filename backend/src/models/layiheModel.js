/**
 * layiheModel — layihe sxemindəki cədvəllər üçün model qatı
 * Soft-delete: silinib = TRUE
 */
const db = require('../config/db');

async function getLayiheler({ status_id } = {}) {
  const conditions = ['l.silinib = FALSE'];
  const params = [];

  if (status_id) {
    params.push(status_id);
    conditions.push(`l.status_id = $${params.length}`);
  }

  const where = `WHERE ${conditions.join(' AND ')}`;

  const { rows } = await db.query(
    `SELECT l.layihe_id, l.muessise_id, l.is_novu_id, l.status_id, l.seher_id, l.kod, l.ad, l.tesvir,
            l.plan_budce, l.bashlama_tarixi, l.son_tarix, l.olcu, l.vahid, l.progres,
            l.created_at, l.updated_at,
            s.ad AS status_ad, s.kod AS status_kod, s.reng AS status_reng,
            m.ad AS muessise_ad, m.voen AS muessise_voen,
            i.ad AS is_novu_ad,
            COALESCE((SELECT SUM(x.mebleg) FROM maliyye.xerc x WHERE x.layihe_id = l.layihe_id), 0) AS fakt_xerc
     FROM layihe.layihe l
     LEFT JOIN layihe.layihe_status s ON s.status_id = l.status_id
     LEFT JOIN ref.muessise m ON m.muessise_id = l.muessise_id
     LEFT JOIN ref.is_novu i ON i.is_novu_id = l.is_novu_id
     ${where}
     ORDER BY l.layihe_id DESC`,
    params
  );
  return rows;
}

async function getLayihe(id) {
  const { rows } = await db.query(
    `SELECT l.*, s.ad AS status_ad, s.kod AS status_kod, s.reng AS status_reng,
            m.ad AS muessise_ad, m.voen AS muessise_voen,
            i.ad AS is_novu_ad,
            COALESCE((SELECT SUM(x.mebleg) FROM maliyye.xerc x WHERE x.layihe_id = l.layihe_id), 0) AS fakt_xerc
     FROM layihe.layihe l
     LEFT JOIN layihe.layihe_status s ON s.status_id = l.status_id
     LEFT JOIN ref.muessise m ON m.muessise_id = l.muessise_id
     LEFT JOIN ref.is_novu i ON i.is_novu_id = l.is_novu_id
     WHERE l.layihe_id = $1 AND l.silinib = FALSE`,
    [id]
  );
  return rows[0] || null;
}

async function createLayihe(data) {
  const {
    muessise_id, is_novu_id, status_id, seher_id, kod, ad, tesvir,
    plan_budce, bashlama_tarixi, son_tarix, olcu, vahid, created_by,
  } = data;

  const { rows } = await db.query(
    `INSERT INTO layihe.layihe
       (muessise_id, is_novu_id, status_id, seher_id, kod, ad, tesvir,
        plan_budce, bashlama_tarixi, son_tarix, olcu, vahid, created_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
     RETURNING *`,
    [
      muessise_id, is_novu_id, status_id || 1, seher_id || null, kod || null, ad, tesvir || null,
      plan_budce || 0, bashlama_tarixi || null, son_tarix || null, olcu || null, vahid || 'm²', created_by || null,
    ]
  );
  return rows[0];
}

async function updateLayihe(id, data) {
  const allowed = [
    'muessise_id', 'is_novu_id', 'status_id', 'seher_id', 'kod', 'ad', 'tesvir',
    'plan_budce', 'bashlama_tarixi', 'son_tarix', 'olcu', 'vahid',
  ];
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
    `UPDATE layihe.layihe SET ${setCols.join(', ')}
     WHERE layihe_id = $${params.length} AND silinib = FALSE
     RETURNING *`,
    params
  );
  return rows[0] || null;
}

async function deleteLayihe(id) {
  const { rows } = await db.query(
    `UPDATE layihe.layihe SET silinib = TRUE, updated_at = NOW()
     WHERE layihe_id = $1
     RETURNING *`,
    [id]
  );
  return rows[0] || null;
}

async function getMerheleler(layihe_id) {
  const { rows } = await db.query(
    `SELECT * FROM layihe.layihe_merhele WHERE layihe_id = $1 ORDER BY merhele_id`,
    [layihe_id]
  );
  return rows;
}

module.exports = { getLayiheler, getLayihe, createLayihe, updateLayihe, deleteLayihe, getMerheleler };
