/**
 * AI Service — DeepSeek-5 ERP-nin süni intellekt qatı
 *
 * İki provider dəstəkləyir:
 *   - deepseek  → callDeepSeek()
 *   - anthropic → callAnthropic()
 *
 * AI_MODE=mock olduqda REAL API ÇAĞIRILMIR — hər teyinat_novu üçün
 * ağlabatan mock JSON cavabı qaytarılır.
 */
const axios = require('axios');

/**
 * DeepSeek Chat Completions API
 * @param {string} prompt
 * @param {{model?: string, temperature?: number, max_tokens?: number}} [options]
 * @returns {Promise<{text: string, usage: {prompt_tokens: number, completion_tokens: number}}>}
 */
async function callDeepSeek(prompt, options = {}) {
  const baseUrl = (process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com').replace(/\/+$/, '');
  const apiKey = process.env.DEEPSEEK_API_KEY;
  const model = options.model || process.env.DEEPSEEK_MODEL || 'deepseek-chat';

  if (!apiKey) {
    throw new Error('DEEPSEEK_API_KEY təyin olunmayıb. AI_MODE=live üçün açar tələb olunur.');
  }

  const url = `${baseUrl}/chat/completions`;
  const payload = {
    model,
    messages: [{ role: 'user', content: prompt }],
    temperature: options.temperature ?? 0.3,
    max_tokens: options.max_tokens ?? 4096,
  };

  const resp = await axios.post(url, payload, {
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    timeout: 120000,
  });

  const data = resp.data;
  return {
    text: data?.choices?.[0]?.message?.content || '',
    usage: {
      prompt_tokens: data?.usage?.prompt_tokens || 0,
      completion_tokens: data?.usage?.completion_tokens || 0,
    },
  };
}

/**
 * Anthropic Claude Messages API
 * @param {string} prompt
 * @param {{model?: string, max_tokens?: number}} [options]
 * @returns {Promise<{text: string, usage: {input_tokens: number, output_tokens: number}}>}
 */
async function callAnthropic(prompt, options = {}) {
  const baseUrl = (process.env.ANTHROPIC_BASE_URL || 'https://api.anthropic.com').replace(/\/+$/, '');
  const apiKey = process.env.ANTHROPIC_API_KEY;
  const model = options.model || process.env.ANTHROPIC_MODEL || 'claude-sonnet-5';

  if (!apiKey) {
    throw new Error('ANTHROPIC_API_KEY təyin olunmayıb. AI_MODE=live üçün açar tələb olunur.');
  }

  const url = `${baseUrl}/v1/messages`;
  const payload = {
    model,
    max_tokens: options.max_tokens ?? 4096,
    messages: [{ role: 'user', content: prompt }],
  };

  const resp = await axios.post(url, payload, {
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    timeout: 120000,
  });

  const data = resp.data;
  return {
    text: data?.content?.[0]?.text || '',
    usage: {
      input_tokens: data?.usage?.input_tokens || 0,
      output_tokens: data?.usage?.output_tokens || 0,
    },
  };
}

/**
 * Hər teyinat_novu üçün ağlabatan mock JSON nümunəsi
 * @param {string} teyinat_novu
 * @returns {object}
 */
function mockResponse(teyinat_novu = '') {
  const samples = {
    budce_prognozu: {
      prognoz_budce: 823000,
      sapma_faizi: -3.2,
      etibarliliq: 78,
      tovsiye: 'Material alışını rübün sonuna saxlayın və ehtiyat büdcə ayırın.',
    },
    tender_qiymetlendirme: {
      en_yaxsi_teklif: 2210000,
      tovsiye_edilen: 'AZKURTİK MMC',
      eminlik: 87,
      qiymetler: [
        { sirket: 'AZKURTİK MMC', teklif: 2210000 },
        { sirket: 'RAHAT TİKİNTİ MMC', teklif: 2340000 },
      ],
    },
    risk_analizi: {
      kritik_risk: 'material_qiymet',
      derece: 42,
      eminlik: 78.5,
      mudaxile_plani: 'Alternativ təchizatçı ilə opsion müqavilə imzalanmalıdır.',
      riskler: ['material_qiymet', 'hava'],
    },
    xerc_tesnifat: {
      xerc_bolmeleri: [
        { ad: 'Material', mebleg: 320000, pay: 46 },
        { ad: 'İşçi qüvvəsi', mebleg: 260000, pay: 37 },
        { ad: 'Avadanlıq', mebleg: 120000, pay: 17 },
      ],
      en_boyuk_xerc: 'Material',
      tovsiye: 'Material tədarükündə toplu endirim danışıqları aparın.',
    },
    material_prognozu: {
      telabat_proqnozu: [
        { material: 'Sement', telabat: 420, vahid: 't' },
        { material: 'Kərpic', telabat: 145000, vahid: 'ədəd' },
      ],
      optimal_sifaris: '2 partiya',
      qenaet_faizi: 8.5,
    },
    hesabat_serhi: {
      xulase: 'Layihə ümumilikdə plana uyğun gedir, lakin material qiymətlərində artım müşahidə olunur.',
      metrikler: { budce_istifadesi: 62, progres: 58 },
      meslehetler: ['Material alışını qabaqcadan planlaşdırın', 'Risk fondunu artırın'],
    },
  };

  return samples[teyinat_novu] || {
    netice: 'Tapşırıq icra olundu.',
    mesaj: 'AI analizi tamamlandı.',
    tovsiyeler: ['Əlavə məlumat üçün müraciət edin'],
  };
}

/**
 * LLM cavabından etibarlı JSON çıxarır.
 * Markdown ```json ... ``` bloklarını və mətn arasında gələn JSON-u handle edir.
 * @param {string} text
 * @returns {object|null}
 */
function parseJSON(text) {
  if (!text || typeof text !== 'string') return null;

  const trimmed = text.trim();
  if (!trimmed) return null;

  // Markdown code fence (```json ... ```) blokunu çıxar
  const fenceMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenceMatch ? fenceMatch[1].trim() : trimmed;

  // Birbaşa JSON.parse cəhdi
  try {
    return JSON.parse(candidate);
  } catch (e) {
    /* aşağıda daha çevik cəhdlər */
  }

  // Mətn içindəki ilk tam JSON obyektini tap
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start !== -1 && end !== -1 && end > start) {
    try {
      return JSON.parse(candidate.slice(start, end + 1));
    } catch (e2) {
      return null;
    }
  }

  return null;
}

/**
 * Provider seçərək AI çağırışı edir.
 *
 * AI_MODE=mock olduqda real API çağırılmır — mock JSON qaytarılır.
 *
 * @param {string} prompt
 * @param {{provider?: 'deepseek'|'anthropic', model?: string, teyinat_novu?: string, mode?: string}} [options]
 * @returns {Promise<{data: object, text: string, usage: object, provider: string, mode: string}>}
 */
async function callAI(prompt, options = {}) {
  const mode = (options.mode || process.env.AI_MODE || 'mock').toLowerCase();
  const provider = (options.provider || '').toLowerCase();
  const teyinat_novu = options.teyinat_novu || '';

  if (mode === 'mock') {
    // Real API çağırılmır — hər teyinat_novu üçün ağlabatan mock JSON
    const mock = mockResponse(teyinat_novu);
    return {
      data: mock,
      text: JSON.stringify(mock, null, 2),
      usage: { prompt_tokens: 0, completion_tokens: 0, input_tokens: 0, output_tokens: 0, total_tokens: 0 },
      provider,
      mode: 'mock',
    };
  }

  // Live mode — real provider çağırışı
  let resp;
  if (provider === 'deepseek') {
    resp = await callDeepSeek(prompt, options);
  } else if (provider === 'anthropic') {
    resp = await callAnthropic(prompt, options);
  } else {
    throw new Error(`Dəstəklənməyən AI provider: "${provider}". Dəstəklənənlər: deepseek, anthropic`);
  }

  const data = parseJSON(resp.text);
  if (!data) {
    throw new Error('AI cavabından JSON çıxarıla bilmədi.');
  }

  return {
    data,
    text: resp.text,
    usage: resp.usage,
    provider,
    mode: 'live',
  };
}

module.exports = { callDeepSeek, callAnthropic, callAI, parseJSON, mockResponse };
