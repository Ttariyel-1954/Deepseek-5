/**
 * muqavileModel — satinalma.muqavile cədvəli üçün model qatı
 */
const db = require('../config/db');

async function getMuqavileler({ aktif } = {}) {
  const conditions = [];
  const params = [];

  if (aktif !== undefined) {
    params.push(aktif === 'false' ? false : true);
    conditions.push(`m.aktif = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await db.query(
    `SELECT m.muqavile_id, m.tender_id, m.layihe_id, m.nomre, m.podratci, m.imzalanma_tarixi,
            m.bashlama_tarixi, m.son_tarix, m.mebleg, m.qeyd, m.aktif, m.created_at, m.updated_at,
            l.ad AS layihe_ad, l.kod AS layihe_kod,
            t.ad AS tender_ad, t.kod AS tender_kod,
            COALESCE((SELECT SUM(o.mebleg) FROM maliyye.odenis o WHERE o.muqavile_id = m.muqavile_id), 0) AS odenen,
            m.mebleg - COALESCE((SELECT SUM(o.mebleg) FROM maliyye.odenis o WHERE o.muqavile_id = m.muqavile_id), 0) AS qaliq_borc
     FROM satinalma.muqavile m
     LEFT JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
     LEFT JOIN satinalma.tender t ON t.tender_id = m.tender_id
     ${where}
     ORDER BY m.created_at DESC`,
    params
  );
  return rows;
}

async function getMuqavile(id) {
  const { rows } = await db.query(
    `SELECT m.*, l.ad AS layihe_ad, l.kod AS layihe_kod, t.ad AS tender_ad, t.kod AS tender_kod,
            COALESCE((SELECT SUM(o.mebleg) FROM maliyye.odenis o WHERE o.muqavile_id = m.muqavile_id), 0) AS odenen
     FROM satinalma.muqavile m
     LEFT JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
     LEFT JOIN satinalma.tender t ON t.tender_id = m.tender_id
     WHERE m.muqavile_id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function createMuqavile(data) {
  const {
    tender_id, layihe_id, nomre, podratci, imzalanma_tarixi, bashlama_tarixi, son_tarix, mebleg, qeyd, aktif,
  } = data;

  const { rows } = await db.query(
    `INSERT INTO satinalma.muqavile
       (tender_id, layihe_id, nomre, podratci, imzalanma_tarixi, bashlama_tarixi, son_tarix, mebleg, qeyd, aktif)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     RETURNING *`,
    [tender_id || null, layihe_id, nomre || null, podratci, imzalanma_tarixi || null, bashlama_tarixi || null, son_tarix || null, mebleg || 0, qeyd || null, aktif ?? true]
  );
  return rows[0];
}

async function updateMuqavile(id, data) {
  const allowed = ['tender_id', 'layihe_id', 'nomre', 'podratci', 'imzalanma_tarixi', 'bashlama_tarixi', 'son_tarix', 'mebleg', 'qeyd', 'aktif'];
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
    `UPDATE satinalma.muqavile SET ${setCols.join(', ')}
     WHERE muqavile_id = $${params.length}
     RETURNING *`,
    params
  );
  return rows[0] || null;
}

async function deleteMuqavile(id) {
  const { rows } = await db.query(
    `UPDATE satinalma.muqavile SET aktif = FALSE, updated_at = NOW() WHERE muqavile_id = $1 RETURNING *`,
    [id]
  );
  return rows[0] || null;
}

module.exports = { getMuqavileler, getMuqavile, createMuqavile, updateMuqavile, deleteMuqavile };
