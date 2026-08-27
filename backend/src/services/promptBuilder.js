/**
 * Prompt Builder — hər teyinat_novu üçün Azərbaycan dilində prompt şablonları
 * Hamısı JSON çıxış tələb edir.
 */

function interpolate(template, giris) {
  return template.replace(/\{(\w+)\}/g, (match, key) => {
    const val = giris ? giris[key] : undefined;
    if (val === undefined || val === null) return '-';
    if (typeof val === 'object') return JSON.stringify(val);
    return String(val);
  });
}

const PROMPT_TEMPLATES = {
  budce_prognozu: `Sən Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsinin baş maliyyə analitikisən.
Layihənin büdcə proqnozunu verilmiş giriş məlumatlarına əsasən hesabla:
- Plan büdcə: {plan_budce} AZN
- Ümumi xərc: {xerc_umumi} AZN
- İcra faizi (progres): {progres}%

Tapşırıq: Layihənin tamamlanma büdcəsini proqnozlaşdır, plana nisbətən sapmanı faizlə göstər və qənaət/müdaxilə tövsiyələri ver.

Cavabı YALNIZ aşağıdakı JSON formatında ver (başqa mətn yazma):
{"prognoz_budce": 0, "sapma_faizi": 0, "etibarliliq": 0, "tovsiye": "..."}`,

  tender_qiymetlendirme: `Sən Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Tikinti İdarəsinin tender analitikisən.
Tender təkliflərini qiymət və texniki meyarlara görə qiymətləndir.
- Qiymət sərhədi: {qiymet_serhedi} AZN
- Təklif sayı: {teklifler}
Giriş məlumatları: {giris}

Tapşırıq: Ən optimal təklifi seç, eminlik faizi ilə birlikdə tövsiyə et.

Cavabı YALNIZ aşağıdakı JSON formatında ver:
{"en_yaxsi_teklif": 0, "tovsiye_edilen": "ŞİRKƏT ADI", "eminlik": 0, "qiymetler": [{"sirket": "...", "teklif": 0}]}`,

  risk_analizi: `Sən Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Tikinti İdarəsinin risk nəzarətçisisən.
Layihənin risklərini təhlil et və prioritetləşdir.
- Risk siyahısı: {riskler}
- Orta ehtimal: {ehtimal_ort}
Giriş məlumatları: {giris}

Tapşırıq: Kritik riski müəyyən et, dərəcəsini (1-100) hesabla və müdaxilə planı təklif et.

Cavabı YALNIZ aşağıdakı JSON formatında ver:
{"kritik_risk": "...", "derece": 0, "eminlik": 0, "mudaxile_plani": "...", "riskler": ["..."]}`,

  xerc_tesnifat: `Sən Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Tikinti İdarəsinin maliyyə analitikisən.
Layihənin xərclərini təsnifatlaşdır və təhlil et.
Giriş məlumatları: {giris}

Tapşırıq: Xərcləri kateqoriyalara böl, ən böyük xərc maddəsini müəyyən et və optimallaşdırma tövsiyəsi ver.

Cavabı YALNIZ aşağıdakı JSON formatında ver:
{"xerc_bolmeleri": [{"ad": "...", "mebleg": 0, "pay": 0}], "en_boyuk_xerc": "...", "tovsiye": "..."}`,

  material_prognozu: `Sən Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Tikinti İdarəsinin təchizat planlayıcısisən.
Layihənin material tələbatını proqnozlaşdır və tədarükü optimallaşdır.
Giriş məlumatları: {giris}

Tapşırıq: Material tələbatını, optimal sifariş partiyasını və gözlənilən qənaəti hesabla.

Cavabı YALNIZ aşağıdakı JSON formatında ver:
{"telabat_proqnozu": [{"material": "...", "telabat": 0, "vahid": "..."}], "optimal_sifaris": "...", "qenaet_faizi": 0}`,

  hesabat_serhi: `Sən Azərbaycan Respublikası Elm və Təhsil Nazirliyinin Tikinti İdarəsinin hesabat analitikisən.
Verilmiş layihə məlumatlarına əsasən icmal hesabat şərhi hazırla.
Giriş məlumatları: {giris}

Tapşırıq: Layihənin ümumi vəziyyətini qiymətləndir, əsas metrikaları qeyd et və tövsiyələr ver.

Cavabı YALNIZ aşağıdakı JSON formatında ver:
{"xulase": "...", "metrikler": {}, "meslehetler": ["..."]}`,
};

const DEFAULT_TEMPLATE = `Sən DeepSeek-5 ERP süni intellekt köməkçisisən.
Tapşırıq növü: {teyinat_novu}
Giriş məlumatları: {giris}

Verilmiş tapşırığı təhlil et və nəticəni JSON formatında qaytar.
Cavabı YALNIZ JSON formatında ver.`;

/**
 * Teyinat növünə uyğun prompt qurur
 * @param {string} teyinat_novu
 * @param {object} [giris_json]
 * @returns {string}
 */
function buildPrompt(teyinat_novu, giris_json) {
  const giris = giris_json || {};
  const template = PROMPT_TEMPLATES[teyinat_novu] || DEFAULT_TEMPLATE;
  if (teyinat_novu && !PROMPT_TEMPLATES[teyinat_novu]) {
    return interpolate(template, { teyinat_novu, giris: JSON.stringify(giris) });
  }
  return interpolate(template, giris);
}

module.exports = { buildPrompt, PROMPT_TEMPLATES };
