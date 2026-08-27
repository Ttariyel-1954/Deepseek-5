/**
 * xercModel — maliyye.xerc cədvəli üçün model qatı
 */
const db = require('../config/db');

async function getXercler({ layihe_id, madde_id } = {}) {
  const conditions = [];
  const params = [];

  if (layihe_id) {
    params.push(layihe_id);
    conditions.push(`x.layihe_id = $${params.length}`);
  }
  if (madde_id) {
    params.push(madde_id);
    conditions.push(`x.madde_id = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await db.query(
    `SELECT x.xerc_id, x.layihe_id, x.muqavile_id, x.madde_id, x.mebleg, x.tarix,
            x.tesvir, x.sened_nomresi, x.created_by, x.created_at,
            l.ad AS layihe_ad, l.kod AS layihe_kod,
            m.ad AS madde_ad, m.kod AS madde_kod,
            mv.nomre AS muqavile_nomre
     FROM maliyye.xerc x
     LEFT JOIN layihe.layihe l ON l.layihe_id = x.layihe_id
     LEFT JOIN maliyye.budce_madde m ON m.madde_id = x.madde_id
     LEFT JOIN satinalma.muqavile mv ON mv.muqavile_id = x.muqavile_id
     ${where}
     ORDER BY x.tarix DESC, x.xerc_id DESC`,
    params
  );
  return rows;
}

async function getXerc(id) {
  const { rows } = await db.query(
    `SELECT x.*, l.ad AS layihe_ad, l.kod AS layihe_kod, m.ad AS madde_ad, mv.nomre AS muqavile_nomre
     FROM maliyye.xerc x
     LEFT JOIN layihe.layihe l ON l.layihe_id = x.layihe_id
     LEFT JOIN maliyye.budce_madde m ON m.madde_id = x.madde_id
     LEFT JOIN satinalma.muqavile mv ON mv.muqavile_id = x.muqavile_id
     WHERE x.xerc_id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function createXerc(data) {
  const { layihe_id, muqavile_id, madde_id, mebleg, tarix, tesvir, sened_nomresi, created_by } = data;
  const { rows } = await db.query(
    `INSERT INTO maliyye.xerc (layihe_id, muqavile_id, madde_id, mebleg, tarix, tesvir, sened_nomresi, created_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [layihe_id, muqavile_id || null, madde_id, mebleg, tarix || null, tesvir || null, sened_nomresi || null, created_by || null]
  );
  return rows[0];
}

async function updateXerc(id, data) {
  const allowed = ['layihe_id', 'muqavile_id', 'madde_id', 'mebleg', 'tarix', 'tesvir', 'sened_nomresi'];
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

  const { rows } = await db.query(
    `UPDATE maliyye.xerc SET ${setCols.join(', ')}
     WHERE xerc_id = $${params.length}
     RETURNING *`,
    params
  );
  return rows[0] || null;
}

async function deleteXerc(id) {
  const { rows } = await db.query(
    `DELETE FROM maliyye.xerc WHERE xerc_id = $1 RETURNING *`,
    [id]
  );
  return rows[0] || null;
}

module.exports = { getXercler, getXerc, createXerc, updateXerc, deleteXerc };
