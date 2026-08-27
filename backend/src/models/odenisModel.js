/**
 * odenisModel — maliyye.odenis cədvəli üçün model qatı
 */
const db = require('../config/db');

async function getOdenisler({ muqavile_id } = {}) {
  const conditions = [];
  const params = [];

  if (muqavile_id) {
    params.push(muqavile_id);
    conditions.push(`o.muqavile_id = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await db.query(
    `SELECT o.odenis_id, o.muqavile_id, o.mebleg, o.tarix, o.odenis_novu, o.qeyd,
            o.sened_nomresi, o.created_by, o.created_at,
            mv.nomre AS muqavile_nomre, mv.podratci AS muqavile_podratci,
            l.ad AS layihe_ad, l.kod AS layihe_kod
     FROM maliyye.odenis o
     LEFT JOIN satinalma.muqavile mv ON mv.muqavile_id = o.muqavile_id
     LEFT JOIN layihe.layihe l ON l.layihe_id = mv.layihe_id
     ${where}
     ORDER BY o.tarix DESC, o.odenis_id DESC`,
    params
  );
  return rows;
}

async function getOdenis(id) {
  const { rows } = await db.query(
    `SELECT o.*, mv.nomre AS muqavile_nomre, mv.podratci AS muqavile_podratci
     FROM maliyye.odenis o
     LEFT JOIN satinalma.muqavile mv ON mv.muqavile_id = o.muqavile_id
     WHERE o.odenis_id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function createOdenis(data) {
  const { muqavile_id, mebleg, tarix, odenis_novu, qeyd, sened_nomresi, created_by } = data;
  const { rows } = await db.query(
    `INSERT INTO maliyye.odenis (muqavile_id, mebleg, tarix, odenis_novu, qeyd, sened_nomresi, created_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [muqavile_id, mebleg, tarix || null, odenis_novu || 'bank', qeyd || null, sened_nomresi || null, created_by || null]
  );
  return rows[0];
}

async function updateOdenis(id, data) {
  const allowed = ['muqavile_id', 'mebleg', 'tarix', 'odenis_novu', 'qeyd', 'sened_nomresi'];
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
    `UPDATE maliyye.odenis SET ${setCols.join(', ')}
     WHERE odenis_id = $${params.length}
     RETURNING *`,
    params
  );
  return rows[0] || null;
}

async function deleteOdenis(id) {
  const { rows } = await db.query(
    `DELETE FROM maliyye.odenis WHERE odenis_id = $1 RETURNING *`,
    [id]
  );
  return rows[0] || null;
}

module.exports = { getOdenisler, getOdenis, createOdenis, updateOdenis, deleteOdenis };
