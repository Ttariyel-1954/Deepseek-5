/**
 * aiModel — ai sxemindəki cədvəllər üçün model qatı
 * Cədvəllər: ai.ai_model, ai.ai_agent, ai.ai_teyinat, ai.ai_qerar,
 *            ai.ai_prognoz, ai.ai_mesaj, ai.ai_log
 */
const db = require('../config/db');

// ============================================================
// MODELLƏR (ai.ai_model)
// ============================================================
async function getModels() {
  const { rows } = await db.query(
    `SELECT model_id, ad, provider, model_ref, rolu, max_tokens, temperature,
            qiymet_1000_input, qiymet_1000_output, aktif, qeyd, created_at, updated_at
     FROM ai.ai_model
     WHERE aktif = TRUE
     ORDER BY model_id`
  );
  return rows;
}

// ============================================================
// AGENTLƏR (ai.ai_agent JOIN ai.ai_model)
// ============================================================
async function getAgents() {
  const { rows } = await db.query(
    `SELECT a.agent_id, a.model_id, a.ad, a.vezife, a.tesvir, a.status, a.aktif,
            a.created_at, a.updated_at,
            m.provider, m.model_ref, m.qiymet_1000_input, m.qiymet_1000_output
     FROM ai.ai_agent a
     LEFT JOIN ai.ai_model m ON m.model_id = a.model_id
     ORDER BY a.agent_id`
  );
  return rows;
}

async function getAgentById(agent_id) {
  const { rows } = await db.query(
    `SELECT a.agent_id, a.model_id, a.ad, a.vezife, a.tesvir, a.status, a.aktif,
            m.provider, m.model_ref, m.qiymet_1000_input, m.qiymet_1000_output
     FROM ai.ai_agent a
     LEFT JOIN ai.ai_model m ON m.model_id = a.model_id
     WHERE a.agent_id = $1`,
    [agent_id]
  );
  return rows[0] || null;
}

// ============================================================
// TƏYİNATLAR (ai.ai_teyinat)
// ============================================================
async function getTeyinatlar({ status, agent_id, layihe_id } = {}) {
  const conditions = [];
  const params = [];
  let idx = 1;

  if (status) { params.push(status); conditions.push(`t.status = $${idx++}`); }
  if (agent_id) { params.push(agent_id); conditions.push(`t.agent_id = $${idx++}`); }
  if (layihe_id) { params.push(layihe_id); conditions.push(`t.layihe_id = $${idx++}`); }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const { rows } = await db.query(
    `SELECT t.teyinat_id, t.agent_id, t.layihe_id, t.teyinat_novu, t.giris_json, t.cixis_json,
            t.prompt, t.status, t.ustunluk, t.netice_qiymeti, t.tesdiq_status, t.yaradan,
            t.created_at, t.tamamlanma_tarixi, t.updated_at,
            a.ad AS agent_ad, a.vezife AS agent_vezife,
            m.provider, m.model_ref,
            l.ad AS layihe_ad, l.kod AS layihe_kod
     FROM ai.ai_teyinat t
     LEFT JOIN ai.ai_agent a ON a.agent_id = t.agent_id
     LEFT JOIN ai.ai_model m ON m.model_id = a.model_id
     LEFT JOIN layihe.layihe l ON l.layihe_id = t.layihe_id
     ${where}
     ORDER BY t.ustunluk DESC, t.created_at DESC`,
    params
  );
  return rows;
}

async function getTeyinat(id) {
  const { rows } = await db.query(
    `SELECT t.teyinat_id, t.agent_id, t.layihe_id, t.teyinat_novu, t.giris_json, t.cixis_json,
            t.prompt, t.status, t.ustunluk, t.netice_qiymeti, t.tesdiq_status, t.yaradan,
            t.created_at, t.tamamlanma_tarixi, t.updated_at,
            a.ad AS agent_ad, a.vezife AS agent_vezife,
            m.provider, m.model_ref
     FROM ai.ai_teyinat t
     LEFT JOIN ai.ai_agent a ON a.agent_id = t.agent_id
     LEFT JOIN ai.ai_model m ON m.model_id = a.model_id
     WHERE t.teyinat_id = $1`,
    [id]
  );
  return rows[0] || null;
}

async function createTeyinat({ agent_id, layihe_id, teyinat_novu, giris_json, prompt, ustunluk, yaradan }) {
  const { rows } = await db.query(
    `INSERT INTO ai.ai_teyinat (agent_id, layihe_id, teyinat_novu, giris_json, prompt, status, ustunluk, yaradan)
     VALUES ($1, $2, $3, $4, $5, 'golecek', $6, $7)
     RETURNING *`,
    [agent_id, layihe_id || null, teyinat_novu, giris_json || null, prompt || null, ustunluk || 5, yaradan || null]
  );
  return rows[0];
}

async function updateTeyinatStatus(id, status) {
  const { rows } = await db.query(
    `UPDATE ai.ai_teyinat
     SET status = $1::varchar,
         tamamlanma_tarixi = CASE WHEN $1::varchar IN ('hazir','xesver') THEN NOW() ELSE tamamlanma_tarixi END,
         updated_at = NOW()
     WHERE teyinat_id = $2
     RETURNING *`,
    [status, id]
  );
  return rows[0] || null;
}

async function setTeyinatNetice(id, cixis_json, netice_qiymeti) {
  const { rows } = await db.query(
    `UPDATE ai.ai_teyinat
     SET cixis_json = $1, netice_qiymeti = $2, updated_at = NOW()
     WHERE teyinat_id = $3
     RETURNING *`,
    [cixis_json ? JSON.stringify(cixis_json) : null, netice_qiymeti ?? null, id]
  );
  return rows[0] || null;
}

async function updateTeyinatPrompt(id, prompt) {
  const { rows } = await db.query(
    `UPDATE ai.ai_teyinat SET prompt = $1, updated_at = NOW() WHERE teyinat_id = $2 RETURNING *`,
    [prompt, id]
  );
  return rows[0] || null;
}

// ============================================================
// QƏRARLAR (ai.ai_qerar)
// ============================================================
async function getQerarlar() {
  const { rows } = await db.query(
    `SELECT q.qerar_id, q.teyinat_id, q.qerar_novu, q.mezmun, q.esaslandirma, q.eminlik,
            q.tesdiq_eden, q.tesdiq_tarixi, q.status, q.created_at,
            t.teyinat_novu, t.layihe_id,
            a.ad AS agent_ad,
            l.ad AS layihe_ad, l.kod AS layihe_kod
     FROM ai.ai_qerar q
     LEFT JOIN ai.ai_teyinat t ON t.teyinat_id = q.teyinat_id
     LEFT JOIN ai.ai_agent a ON a.agent_id = t.agent_id
     LEFT JOIN layihe.layihe l ON l.layihe_id = t.layihe_id
     ORDER BY q.created_at DESC`
  );
  return rows;
}

async function createQerar({ teyinat_id, qerar_novu, mezmun, esaslandirma, eminlik }) {
  const { rows } = await db.query(
    `INSERT INTO ai.ai_qerar (teyinat_id, qerar_novu, mezmun, esaslandirma, eminlik, status)
     VALUES ($1, $2, $3, $4, $5, 'teklif')
     RETURNING *`,
    [teyinat_id, qerar_novu, mezmun ? JSON.stringify(mezmun) : null, esaslandirma || null, eminlik ?? null]
  );
  return rows[0];
}

async function tesdiqleQerar(id, user_id) {
  const { rows } = await db.query(
    `UPDATE ai.ai_qerar
     SET status = 'tesdiqlendi', tesdiq_eden = $1, tesdiq_tarixi = NOW()
     WHERE qerar_id = $2
     RETURNING *`,
    [user_id, id]
  );
  return rows[0] || null;
}

async function reddEtQerar(id, user_id) {
  const { rows } = await db.query(
    `UPDATE ai.ai_qerar
     SET status = 'redd_edildi', tesdiq_eden = $1, tesdiq_tarixi = NOW()
     WHERE qerar_id = $2
     RETURNING *`,
    [user_id, id]
  );
  return rows[0] || null;
}

// ============================================================
// PROQNOZLAR (ai.ai_prognoz)
// ============================================================
async function getProqnozlar() {
  const { rows } = await db.query(
    `SELECT p.prognoz_id, p.layihe_id, p.prognoz_novu, p.prognoz_deyer, p.real_deyer,
            p.ehtimal, p.tarix, p.doqruluk, p.qeyd,
            l.ad AS layihe_ad, l.kod AS layihe_kod
     FROM ai.ai_prognoz p
     LEFT JOIN layihe.layihe l ON l.layihe_id = p.layihe_id
     ORDER BY p.tarix DESC`
  );
  return rows;
}

async function createPrognoz({ layihe_id, prognoz_novu, prognoz_deyer, ehtimal, qeyd }) {
  const { rows } = await db.query(
    `INSERT INTO ai.ai_prognoz (layihe_id, prognoz_novu, prognoz_deyer, ehtimal, qeyd)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [layihe_id || null, prognoz_novu, prognoz_deyer ?? null, ehtimal ?? null, qeyd || null]
  );
  return rows[0];
}

// ============================================================
// MESAJLAR (ai.ai_mesaj)
// ============================================================
async function getMesajlar() {
  const { rows } = await db.query(
    `SELECT m.mesaj_id, m.agent_id, m.layihe_id, m.alici_id, m.movzu, m.mezmun, m.onem, m.oxunub, m.created_at,
            a.ad AS agent_ad,
            l.ad AS layihe_ad, l.kod AS layihe_kod
     FROM ai.ai_mesaj m
     LEFT JOIN ai.ai_agent a ON a.agent_id = m.agent_id
     LEFT JOIN layihe.layihe l ON l.layihe_id = m.layihe_id
     ORDER BY m.created_at DESC`
  );
  return rows;
}

async function createMesaj({ agent_id, layihe_id, alici_id, movzu, mezmun, onem }) {
  const { rows } = await db.query(
    `INSERT INTO ai.ai_mesaj (agent_id, layihe_id, alici_id, movzu, mezmun, onem, oxunub)
     VALUES ($1, $2, $3, $4, $5, $6, FALSE)
     RETURNING *`,
    [agent_id || null, layihe_id || null, alici_id || null, movzu, mezmun, onem || 'normal']
  );
  return rows[0];
}

async function oxunubMesaj(id) {
  const { rows } = await db.query(
    `UPDATE ai.ai_mesaj SET oxunub = TRUE WHERE mesaj_id = $1 RETURNING *`,
    [id]
  );
  return rows[0] || null;
}

// ============================================================
// LOQLAR (ai.ai_log)
// ============================================================
async function getLoglar() {
  const { rows } = await db.query(
    `SELECT lg.log_id, lg.teyinat_id, lg.agent_id, lg.hadise, lg.mesaj,
            lg.serf_olunan_tokens, lg.serf_olunan_xerc, lg.created_at,
            a.ad AS agent_ad
     FROM ai.ai_log lg
     LEFT JOIN ai.ai_agent a ON a.agent_id = lg.agent_id
     ORDER BY lg.created_at DESC`
  );
  return rows;
}

async function logTeyinat(teyinat_id, agent_id, hadise, mesaj, tokens, xerc) {
  const { rows } = await db.query(
    `INSERT INTO ai.ai_log (teyinat_id, agent_id, hadise, mesaj, serf_olunan_tokens, serf_olunan_xerc)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [teyinat_id || null, agent_id || null, hadise, mesaj || null, tokens || 0, xerc || 0]
  );
  return rows[0];
}

module.exports = {
  getModels,
  getAgents,
  getAgentById,
  getTeyinatlar,
  getTeyinat,
  createTeyinat,
  updateTeyinatStatus,
  setTeyinatNetice,
  updateTeyinatPrompt,
  getQerarlar,
  createQerar,
  tesdiqleQerar,
  reddEtQerar,
  getProqnozlar,
  createPrognoz,
  getMesajlar,
  createMesaj,
  oxunubMesaj,
  getLoglar,
  logTeyinat,
};
