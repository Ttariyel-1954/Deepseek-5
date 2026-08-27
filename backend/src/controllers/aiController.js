const aiModel = require('../models/aiModel');
const promptBuilder = require('../services/promptBuilder');
const { callAI } = require('../services/aiService');

// ============================================================
// ƏSAS GÖRÜNÜŞLƏR
// ============================================================
async function getModels(req, res, next) {
  try {
    const items = await aiModel.getModels();
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getAgents(req, res, next) {
  try {
    const items = await aiModel.getAgents();
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function getTeyinatlar(req, res, next) {
  try {
    const items = await aiModel.getTeyinatlar(req.query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function createTeyinat(req, res, next) {
  try {
    const { agent_id, layihe_id, teyinat_novu, giris_json, ustunluk } = req.body;
    const prompt = promptBuilder.buildPrompt(teyinat_novu, giris_json);

    const teyinat = await aiModel.createTeyinat({
      agent_id,
      layihe_id,
      teyinat_novu,
      giris_json,
      prompt,
      ustunluk,
      yaradan: req.user ? req.user.user_id : null,
    });

    return res.status(201).json(teyinat);
  } catch (err) {
    return next(err);
  }
}

/**
 * Netice qiyməti — LLM nəticəsinin keyfiyyət balı (0-100)
 */
function neticeQiymeti(teyinat_novu, cixisJson) {
  if (cixisJson && cixisJson.eminlik) return Number(cixisJson.eminlik);
  const defaults = {
    budce_prognozu: 85,
    tender_qiymetlendirme: 87,
    risk_analizi: 82,
    xerc_tesnifat: 80,
    material_prognozu: 78,
    hesabat_serhi: 84,
  };
  return defaults[teyinat_novu] || 80;
}

/**
 * Ümumi token sayı
 */
function totalTokens(usage = {}) {
  return (
    (usage.prompt_tokens || 0) +
    (usage.completion_tokens || 0) +
    (usage.input_tokens || 0) +
    (usage.output_tokens || 0) +
    (usage.total_tokens || 0)
  );
}

/**
 * Xərc hesablanması — modelin $ / 1k token qiymətinə görə (AZN-lə yox, $ ilə)
 */
function computeXerc(provider, usage = {}, agent = {}) {
  const inTokens = (usage.input_tokens || usage.prompt_tokens || 0);
  const outTokens = (usage.output_tokens || usage.completion_tokens || 0);
  const qiymetIn = agent.qiymet_1000_input || 0;
  const qiymetOut = agent.qiymet_1000_output || 0;
  return (inTokens / 1000) * qiymetIn + (outTokens / 1000) * qiymetOut;
}

/**
 * AI icra nəticəsinə əsasən qərar/proqnoz/mesaj yaradır
 */
async function postProcess(teyinat, agent, cixisJson) {
  if (!cixisJson || typeof cixisJson !== 'object') return;

  const novu = teyinat.teyinat_novu;
  const agent_id = agent.agent_id;
  const layihe_id = teyinat.layihe_id;
  const alici_id = teyinat.yaradan || 1;

  try {
    if (novu === 'budce_prognozu') {
      if (cixisJson.prognoz_budce !== undefined) {
        await aiModel.createPrognoz({
          layihe_id,
          prognoz_novu: 'budce_sapmasi',
          prognoz_deyer: cixisJson.prognoz_budce,
          ehtimal: cixisJson.etibarliliq || null,
          qeyd: cixisJson.tovsiye || null,
        });
      }
      await aiModel.createQerar({
        teyinat_id: teyinat.teyinat_id,
        qerar_novu: 'budce_tovsiyesi',
        mezmun: { tovsiye: cixisJson.tovsiye, prognoz_budce: cixisJson.prognoz_budce },
        esaslandirma: 'AI büdcə proqnozu analizinin nəticəsi',
        eminlik: cixisJson.etibarliliq || null,
      });
      await aiModel.createMesaj({
        agent_id,
        layihe_id,
        alici_id,
        movzu: 'Büdcə proqnozu yeniləndi',
        mezmun: `Proqnoz büdcə: ${cixisJson.prognoz_budce} AZN. ${cixisJson.tovsiye || ''}`,
        onem: (cixisJson.sapma_faizi || 0) > 0 ? 'yuksek' : 'normal',
      });
    } else if (novu === 'tender_qiymetlendirme') {
      await aiModel.createQerar({
        teyinat_id: teyinat.teyinat_id,
        qerar_novu: 'tender_qiymet_tovsiyesi',
        mezmun: { qalib: cixisJson.tovsiye_edilen, teklif: cixisJson.en_yaxsi_teklif, doviz: 'AZN' },
        esaslandirma: 'Qiymət və texniki meyarların AI təhlili',
        eminlik: cixisJson.eminlik || null,
      });
      await aiModel.createMesaj({
        agent_id,
        layihe_id,
        alici_id,
        movzu: 'Tender təklifləri hazırdır',
        mezmun: `Ən optimal təklif: ${cixisJson.tovsiye_edilen} (${cixisJson.en_yaxsi_teklif} AZN)`,
        onem: 'normal',
      });
    } else if (novu === 'risk_analizi') {
      await aiModel.createQerar({
        teyinat_id: teyinat.teyinat_id,
        qerar_novu: 'risk_qebulu',
        mezmun: { qerar: cixisJson.mudaxile_plani },
        esaslandirma: `Kritik risk: ${cixisJson.kritik_risk}, dərəcə: ${cixisJson.derece}`,
        eminlik: cixisJson.eminlik || null,
      });
      await aiModel.createMesaj({
        agent_id,
        layihe_id,
        alici_id,
        movzu: 'Risk artımı xəbərdarlığı',
        mezmun: `Kritik risk aşkarlandı: ${cixisJson.kritik_risk}. ${cixisJson.mudaxile_plani || ''}`,
        onem: 'yuksek',
      });
    } else if (novu === 'xerc_tesnifat') {
      await aiModel.createQerar({
        teyinat_id: teyinat.teyinat_id,
        qerar_novu: 'xerc_optimallashdirma',
        mezmun: { en_boyuk_xerc: cixisJson.en_boyuk_xerc, tovsiye: cixisJson.tovsiye },
        esaslandirma: 'Xərc təsnifat analizinin nəticəsi',
        eminlik: null,
      });
    } else if (novu === 'material_prognozu') {
      await aiModel.createPrognoz({
        layihe_id,
        prognoz_novu: 'material_qitligi',
        prognoz_deyer: null,
        ehtimal: 50,
        qeyd: `Optimal sifariş: ${cixisJson.optimal_sifaris}. Qənaət: ${cixisJson.qenaet_faizi}%`,
      });
    } else if (novu === 'hesabat_serhi') {
      await aiModel.createMesaj({
        agent_id,
        layihe_id,
        alici_id,
        movzu: 'Hesabat şərhi hazırdır',
        mezmun: cixisJson.xulase || '',
        onem: 'normal',
      });
    }
  } catch (err) {
    // Post-processing xətaları əsas icranı pozmasın
    console.error('AI postProcess xətası:', err.message);
  }
}

/**
 * Təyinatı icra edir: prompt → callAI → cixis_json → status hazir → log → qərar/proqnoz/mesaj
 */
async function icraTeyinat(req, res, next) {
  const { id } = req.params;

  try {
    const teyinat = await aiModel.getTeyinat(id);
    if (!teyinat) return res.status(404).json({ error: 'Tapşırıq tapılmadı' });

    const agent = await aiModel.getAgentById(teyinat.agent_id);
    if (!agent) return res.status(400).json({ error: 'Agent tapılmadı' });

    const provider = (agent.provider || '').toLowerCase();
    const model = agent.model_ref || undefined;

    // Başlanğıc loqu + status
    await aiModel.logTeyinat(
      teyinat.teyinat_id,
      agent.agent_id,
      'basladi',
      `Tapşırıq icrası başladı: ${teyinat.teyinat_novu} (${provider})`
    );
    await aiModel.updateTeyinatStatus(teyinat.teyinat_id, 'islemede');

    // Prompt qur + saxla
    const prompt = promptBuilder.buildPrompt(teyinat.teyinat_novu, teyinat.giris_json);
    await aiModel.updateTeyinatPrompt(teyinat.teyinat_id, prompt);

    // AI çağırışı (mock/live)
    const result = await callAI(prompt, { provider, model, teyinat_novu: teyinat.teyinat_novu });

    const cixisJson = result.data;
    await aiModel.setTeyinatNetice(teyinat.teyinat_id, cixisJson, neticeQiymeti(teyinat.teyinat_novu, cixisJson));
    await aiModel.updateTeyinatStatus(teyinat.teyinat_id, 'hazir');

    const tokens = totalTokens(result.usage);
    const xerc = computeXerc(provider, result.usage, agent);

    await aiModel.logTeyinat(
      teyinat.teyinat_id,
      agent.agent_id,
      'bitdi',
      `Tapşırıq uğurla tamamlandı (${provider}/${model})`,
      tokens,
      xerc
    );

    // Qərar / proqnoz / mesaj yarat
    await postProcess(teyinat, agent, cixisJson);

    // Yenilənmiş təyinatı qaytar
    const updated = await aiModel.getTeyinat(teyinat.teyinat_id);

    return res.json({
      teyinat: updated,
      provider,
      model,
      mode: result.mode,
      cixis_json: cixisJson,
      tokens,
      xerc,
    });
  } catch (err) {
    // Xəta halında status xesver + xəta loqu
    try {
      await aiModel.updateTeyinatStatus(req.params.id, 'xesver');
      await aiModel.logTeyinat(req.params.id, null, 'xesver', `Xəta: ${err.message}`);
    } catch (logErr) {
      console.error('AI xəta loqu yazıla bilmədi:', logErr.message);
    }
    return next(err);
  }
}

// ============================================================
// QƏRARLAR
// ============================================================
async function getQerarlar(req, res, next) {
  try {
    const items = await aiModel.getQerarlar();
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function tesdiqleQerar(req, res, next) {
  try {
    const qerar = await aiModel.tesdiqleQerar(req.params.id, req.user.user_id);
    if (!qerar) return res.status(404).json({ error: 'Qərar tapılmadı' });
    return res.json(qerar);
  } catch (err) {
    return next(err);
  }
}

async function reddEtQerar(req, res, next) {
  try {
    const qerar = await aiModel.reddEtQerar(req.params.id, req.user.user_id);
    if (!qerar) return res.status(404).json({ error: 'Qərar tapılmadı' });
    return res.json(qerar);
  } catch (err) {
    return next(err);
  }
}

// ============================================================
// PROQNOZLAR
// ============================================================
async function getProqnozlar(req, res, next) {
  try {
    const items = await aiModel.getProqnozlar();
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

// ============================================================
// MESAJLAR
// ============================================================
async function getMesajlar(req, res, next) {
  try {
    const items = await aiModel.getMesajlar();
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

async function oxunubMesaj(req, res, next) {
  try {
    const item = await aiModel.oxunubMesaj(req.params.id);
    if (!item) return res.status(404).json({ error: 'Mesaj tapılmadı' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
}

// ============================================================
// LOQLAR
// ============================================================
async function getLoglar(req, res, next) {
  try {
    const items = await aiModel.getLoglar();
    return res.json(items);
  } catch (err) {
    return next(err);
  }
}

// ============================================================
// STATUS
// ============================================================
async function getStatus(req, res, next) {
  try {
    const [models, agents] = await Promise.all([aiModel.getModels(), aiModel.getAgents()]);
    const providers = [...new Set(models.map((m) => m.provider))];
    const aktivAgents = agents.filter((a) => a.aktif && a.status === 'aktiv');

    return res.json({
      ai_mode: process.env.AI_MODE || 'mock',
      provider_sayi: providers.length,
      providers,
      model_sayi: models.length,
      agent_sayi: agents.length,
      aktiv_agent_sayi: aktivAgents.length,
      deepseek_konfig: {
        base_url: process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com',
        model: process.env.DEEPSEEK_MODEL || 'deepseek-chat',
        açar_var: Boolean(process.env.DEEPSEEK_API_KEY),
      },
      anthropic_konfig: {
        base_url: process.env.ANTHROPIC_BASE_URL || 'https://api.anthropic.com',
        model: process.env.ANTHROPIC_MODEL || 'claude-sonnet-5',
        açar_var: Boolean(process.env.ANTHROPIC_API_KEY),
      },
      time: new Date().toISOString(),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getModels,
  getAgents,
  getTeyinatlar,
  createTeyinat,
  icraTeyinat,
  getQerarlar,
  tesdiqleQerar,
  reddEtQerar,
  getProqnozlar,
  getMesajlar,
  oxunubMesaj,
  getLoglar,
  getStatus,
};
