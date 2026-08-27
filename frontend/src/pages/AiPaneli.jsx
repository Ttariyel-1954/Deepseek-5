import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api, { extractList } from '../services/api'
import { formatAZN, formatDateTime } from '../utils/format'

const TEAYINAT_NOVLARI = [
  { value: 'budce_prognozu', label: 'Büdcə proqnozu' },
  { value: 'tender_qiymetlendirme', label: 'Tender qiymətləndirmə' },
  { value: 'risk_analizi', label: 'Risk analizi' },
  { value: 'xerc_asirliq_xeberdarligi', label: 'Xərc aşırlığı xəbərdarlığı' },
  { value: 'material_planlamasi', label: 'Material planlaması' },
  { value: 'keyfiyyet_hesabati', label: 'Keyfiyyət hesabatı' },
]

const STATUS_STYLES = {
  golecek: 'bg-slate-100 text-slate-700 ring-slate-200',
  islemede: 'bg-amber-100 text-amber-800 ring-amber-200',
  hazir: 'bg-emerald-100 text-emerald-800 ring-emerald-200',
  xesver: 'bg-red-100 text-red-800 ring-red-200',
}

const STATUS_LABELS = {
  golecek: 'Gözləyir',
  islemede: 'İşləyir',
  hazir: 'Hazır',
  xesver: 'Xəta',
}

const QERAR_STATUS_LABELS = {
  teklif: 'Təklif',
  tesdiqlendi: 'Təsdiqləndi',
  redd_edildi: 'Rədd edildi',
  icra_olunur: 'İcra olunur',
  icra_olundu: 'İcra olundu',
}

function teyinatNovuLabel(value) {
  const found = TEAYINAT_NOVLARI.find((n) => n.value === value)
  return found ? found.label : value || '—'
}

function vezifeLabel(value) {
  const map = {
    planlayici: 'Planlayıcı',
    tender_analitiki: 'Tender analitiki',
    risk_nezaretcisi: 'Risk nəzarətçisi',
    xerc_analitiki: 'Xərc analitiki',
    keyfiyyet_mufettisi: 'Keyfiyyət müfəttişi',
    techizat_optimallashdiricisi: 'Təchizat optimallaşdırıcısı',
  }
  return map[value] || value || '—'
}

function tesdiqStatusLabel(value) {
  const map = {
    golecek: 'Təsdiq gözləyir',
    tesdiqlendi: 'Təsdiqləndi',
    redd_edildi: 'Rədd edildi',
  }
  return map[value] || value || '—'
}

function proqnozLabel(value) {
  const map = {
    xerc_asirliq: 'Xərc aşırlığı',
    muddet_gecikmesi: 'Müddət gecikməsi',
    material_qitligi: 'Material qıtlığı',
    budce_sapmasi: 'Büdcə sapması',
  }
  return map[value] || value || '—'
}

function onemLabel(value) {
  const map = {
    yuksek: 'Yüksək',
    kritik: 'Kritik',
    normal: 'Normal',
    asagi: 'Aşağı',
  }
  return map[String(value).toLowerCase()] || value || '—'
}

function logHadiseLabel(value) {
  const map = {
    basladi: 'Başladı',
    bitdi: 'Bitdi',
    xesver: 'Xəta',
    tekrar: 'Təkrar',
  }
  return map[value] || value || '—'
}

function logColor(value) {
  const map = {
    basladi: 'bg-blue-500',
    bitdi: 'bg-emerald-500',
    xesver: 'bg-red-500',
    tekrar: 'bg-amber-500',
  }
  return map[value] || 'bg-gray-400'
}

function providerInfo(provider) {
  const map = {
    deepseek: { label: 'DeepSeek', className: 'bg-blue-50 text-blue-700 ring-blue-200' },
    anthropic: { label: 'Claude', className: 'bg-orange-50 text-orange-700 ring-orange-200' },
    openai: { label: 'OpenAI', className: 'bg-emerald-50 text-emerald-700 ring-emerald-200' },
    lokal: { label: 'Lokal', className: 'bg-purple-50 text-purple-700 ring-purple-200' },
  }
  const key = String(provider || '').toLowerCase()
  return map[key] || { label: provider || 'Naməlum', className: 'bg-gray-100 text-gray-700 ring-gray-200' }
}

function aiModeLabel(value) {
  const map = {
    avtonom: 'Avtonom',
    yarim_avtonom: 'Yarım avtonom',
    yarı_avtonom: 'Yarım avtonom',
    yari_avtonom: 'Yarım avtonom',
    nezaretli: 'Nəzarətli',
    nezaret: 'Nəzarətli',
  }
  const key = String(value || '').toLowerCase()
  return map[key] || value || 'Naməlum'
}

function Badge({ children, className = 'bg-slate-100 text-slate-700' }) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset ${className}`}
    >
      {children}
    </span>
  )
}

function SectionCard({ title, subtitle, children, action }) {
  return (
    <section className="overflow-hidden rounded-xl bg-white shadow-sm ring-1 ring-gray-200">
      <div className="flex items-center justify-between border-b border-gray-100 px-5 py-4">
        <div>
          <h2 className="text-sm font-semibold text-gray-900">{title}</h2>
          {subtitle && <p className="mt-0.5 text-xs text-gray-500">{subtitle}</p>}
        </div>
        {action}
      </div>
      <div className="p-5">{children}</div>
    </section>
  )
}

function QueryNotice({ isLoading, isError, error, children }) {
  if (isLoading) {
    return <p className="py-4 text-center text-sm text-gray-500">Yüklənir...</p>
  }
  if (isError) {
    return (
      <p className="py-4 text-center text-sm text-red-600">
        Xəta: {error?.response?.data?.mesaj || error?.response?.data?.message || error?.message}
      </p>
    )
  }
  return children
}

export default function AiPaneli() {
  const queryClient = useQueryClient()

  // ---------- Sorğular ----------
  const statusQuery = useQuery({
    queryKey: ['ai-status'],
    queryFn: async () => (await api.get('/ai/status')).data,
  })
  const agentlerQuery = useQuery({
    queryKey: ['ai-agentler'],
    queryFn: async () => extractList(await api.get('/ai/agentler')),
  })
  const teyinatlarQuery = useQuery({
    queryKey: ['ai-teyinatlar'],
    queryFn: async () => extractList(await api.get('/ai/teyinatlar')),
  })
  const qerarlarQuery = useQuery({
    queryKey: ['ai-qerarlar'],
    queryFn: async () => extractList(await api.get('/ai/qerarlar')),
  })
  const proqnozlarQuery = useQuery({
    queryKey: ['ai-proqnozlar'],
    queryFn: async () => extractList(await api.get('/ai/proqnozlar')),
  })
  const mesajlarQuery = useQuery({
    queryKey: ['ai-mesajlar'],
    queryFn: async () => extractList(await api.get('/ai/mesajlar')),
  })
  const loglarQuery = useQuery({
    queryKey: ['ai-loglar'],
    queryFn: async () => extractList(await api.get('/ai/loglar')),
  })

  // ---------- Mutasiyalar ----------
  const createTeyinat = useMutation({
    mutationFn: (payload) => api.post('/ai/teyinatlar', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['ai-teyinatlar'] })
    },
  })

  const icraTeyinat = useMutation({
    mutationFn: (id) => api.post(`/ai/teyinatlar/${id}/icra`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['ai-teyinatlar'] })
      queryClient.invalidateQueries({ queryKey: ['ai-loglar'] })
      queryClient.invalidateQueries({ queryKey: ['ai-qerarlar'] })
    },
  })

  const qerarMutation = useMutation({
    mutationFn: ({ id, aksiya }) => api.post(`/ai/qerarlar/${id}/${aksiya}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['ai-qerarlar'] })
      queryClient.invalidateQueries({ queryKey: ['ai-teyinatlar'] })
    },
  })

  // ---------- Form state ----------
  const [agentId, setAgentId] = useState('')
  const [teyinatNovu, setTeyinatNovu] = useState('')
  const [girisJson, setGirisJson] = useState('')
  const [formError, setFormError] = useState('')
  const [formSuccess, setFormSuccess] = useState('')

  const status = statusQuery.data || {}
  const agents = agentlerQuery.data || []
  const teyinatlar = teyinatlarQuery.data || []
  const qerarlar = qerarlarQuery.data || []
  const proqnozlar = proqnozlarQuery.data || []
  const mesajlar = mesajlarQuery.data || []
  const loglar = loglarQuery.data || []

  const providerSet = new Set(agents.map((a) => a.provider).filter(Boolean))
  const providerSayi = status.provider_sayi ?? providerSet.size
  const aktivAgentSayi =
    status.aktiv_agent_sayi ??
    agents.filter((a) => a.aktif !== false && a.status !== 'passiv').length
  const aiMode = status.AI_MODE ?? status.ai_mode ?? status.rejim

  const executingId = icraTeyinat.isPending ? icraTeyinat.variables : null

  function handleCreate(e) {
    e.preventDefault()
    setFormError('')
    setFormSuccess('')
    if (!agentId || !teyinatNovu) {
      setFormError('Agent və tapşırıq növü seçin')
      return
    }
    let parsed
    if (girisJson.trim()) {
      try {
        parsed = JSON.parse(girisJson)
      } catch {
        setFormError('Giriş məlumatları düzgün JSON formatında deyil')
        return
      }
    } else {
      parsed = {}
    }
    createTeyinat.mutate(
      { agent_id: Number(agentId), teyinat_novu: teyinatNovu, giris_json: parsed },
      {
        onSuccess: () => {
          setFormSuccess('Tapşırıq yaradıldı')
          setGirisJson('')
          setTeyinatNovu('')
          setAgentId('')
        },
        onError: (err) =>
          setFormError(
            err.response?.data?.mesaj ||
              err.response?.data?.message ||
              'Tapşırıq yaradılmadı'
          ),
      }
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900">AI İdarəetmə Paneli</h1>
      </div>

      {/* ---------- Status banner ---------- */}
      <div className="rounded-xl bg-gradient-to-r from-slate-900 to-slate-700 p-5 text-white shadow">
        <div className="flex flex-wrap items-center gap-8">
          <div>
            <p className="text-xs uppercase tracking-wide text-slate-300">
              AI rejimi
            </p>
            <p className="mt-1 text-xl font-bold">{aiModeLabel(aiMode)}</p>
          </div>
          <div>
            <p className="text-xs uppercase tracking-wide text-slate-300">
              Providerlər
            </p>
            <p className="mt-1 text-xl font-bold">{providerSayi}</p>
          </div>
          <div>
            <p className="text-xs uppercase tracking-wide text-slate-300">
              Aktiv agentlər
            </p>
            <p className="mt-1 text-xl font-bold">{aktivAgentSayi}</p>
          </div>
          <div className="ml-auto">
            <span
              className={`inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-medium ${
                statusQuery.isLoading
                  ? 'bg-slate-600'
                  : statusQuery.isError
                    ? 'bg-red-500'
                    : 'bg-emerald-500'
              }`}
            >
              <span className="h-2 w-2 rounded-full bg-white/80"></span>
              {statusQuery.isLoading
                ? 'Yoxlanılır...'
                : statusQuery.isError
                  ? 'API əlçatmazdır'
                  : 'Aktiv'}
            </span>
          </div>
        </div>
      </div>

      {/* ---------- Agentlər + Yeni tapşırıq ---------- */}
      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <SectionCard
            title="AI Agentləri"
            subtitle={`${agents.length} agent qeydə alınıb`}
          >
            <QueryNotice {...agentlerQuery}>
              {agents.length === 0 ? (
                <p className="py-4 text-center text-sm text-gray-500">
                  Məlumat yoxdur
                </p>
              ) : (
                <div className="grid gap-4 sm:grid-cols-2">
                  {agents.map((agent) => {
                    const p = providerInfo(agent.provider)
                    return (
                      <div
                        key={agent.agent_id ?? agent.id}
                        className="rounded-lg border border-gray-200 p-4"
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <h3 className="font-semibold text-gray-900">
                              {agent.ad}
                            </h3>
                            <p className="text-xs text-gray-500">
                              {vezifeLabel(agent.vezife)}
                            </p>
                          </div>
                          <Badge className={p.className}>{p.label}</Badge>
                        </div>
                        <div className="mt-3 flex items-center gap-2 text-xs text-gray-500">
                          <span>
                            Model:{' '}
                            <span className="font-medium text-gray-700">
                              {agent.model ?? agent.model_ref ?? '—'}
                            </span>
                          </span>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </QueryNotice>
          </SectionCard>
        </div>

        <div>
          <SectionCard
            title="Yeni tapşırıq"
            subtitle="Agentə AI tapşırığı verin"
          >
            <form onSubmit={handleCreate} className="space-y-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">
                  Agent
                </label>
                <select
                  value={agentId}
                  onChange={(e) => setAgentId(e.target.value)}
                  className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none"
                >
                  <option value="">— Seçin —</option>
                  {agents.map((a) => (
                    <option key={a.agent_id ?? a.id} value={a.agent_id ?? a.id}>
                      {a.ad}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">
                  Tapşırıq növü
                </label>
                <select
                  value={teyinatNovu}
                  onChange={(e) => setTeyinatNovu(e.target.value)}
                  className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none"
                >
                  <option value="">— Seçin —</option>
                  {TEAYINAT_NOVLARI.map((n) => (
                    <option key={n.value} value={n.value}>
                      {n.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">
                  Giriş məlumatları (JSON, isteğe bağlı)
                </label>
                <textarea
                  value={girisJson}
                  onChange={(e) => setGirisJson(e.target.value)}
                  rows={3}
                  placeholder='{"plan_budce": 100000}'
                  className="w-full rounded-md border border-gray-300 px-3 py-2 font-mono text-xs focus:border-slate-500 focus:outline-none"
                />
              </div>
              {formError && <p className="text-sm text-red-600">{formError}</p>}
              {formSuccess && (
                <p className="text-sm text-emerald-600">{formSuccess}</p>
              )}
              <button
                type="submit"
                disabled={createTeyinat.isPending}
                className="w-full rounded-md bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {createTeyinat.isPending ? 'Yaradılır...' : 'Yeni tapşırıq'}
              </button>
            </form>
          </SectionCard>
        </div>
      </div>

      {/* ---------- Tapşırıqlar ---------- */}
      <SectionCard
        title="AI Tapşırıqları"
        subtitle={`${teyinatlar.length} tapşırıq`}
      >
        <QueryNotice {...teyinatlarQuery}>
          {teyinatlar.length === 0 ? (
            <p className="py-4 text-center text-sm text-gray-500">
              Məlumat yoxdur
            </p>
          ) : (
            <div className="grid gap-3 lg:grid-cols-2">
              {teyinatlar.map((t) => {
                const statusKey = STATUS_LABELS[t.status] ? t.status : 'golecek'
                const id = t.teyinat_id ?? t.id
                return (
                  <div
                    key={id}
                    className="rounded-lg border border-gray-200 p-4"
                  >
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-medium text-gray-900">
                        {teyinatNovuLabel(t.teyinat_novu)}
                      </span>
                      <Badge className={STATUS_STYLES[statusKey]}>
                        {STATUS_LABELS[statusKey]}
                      </Badge>
                      {t.tesdiq_status && (
                        <Badge className="bg-indigo-50 text-indigo-700 ring-indigo-200">
                          {tesdiqStatusLabel(t.tesdiq_status)}
                        </Badge>
                      )}
                    </div>
                    <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-gray-500">
                      <span>
                        Agent:{' '}
                        <span className="text-gray-700">
                          {t.agent_ad ?? t.agent?.ad ?? '—'}
                        </span>
                      </span>
                      {(t.layihe_kod ?? t.layihe?.kod) && (
                        <span>
                          Layihə:{' '}
                          <span className="text-gray-700">
                            {t.layihe_kod ?? t.layihe?.kod}
                          </span>
                        </span>
                      )}
                      {t.netice_qiymeti != null && (
                        <span>
                          Nəticə:{' '}
                          <span className="text-gray-700">
                            {t.netice_qiymeti}%
                          </span>
                        </span>
                      )}
                      {t.tamamlanma_tarixi && (
                        <span>{formatDateTime(t.tamamlanma_tarixi)}</span>
                      )}
                    </div>
                    <div className="mt-3">
                      <button
                        onClick={() => icraTeyinat.mutate(id)}
                        disabled={executingId === id}
                        className="rounded-md bg-slate-100 px-3 py-1.5 text-xs font-medium text-slate-700 ring-1 ring-inset ring-slate-200 transition hover:bg-slate-200 disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        {executingId === id ? 'İcra olunur...' : 'İcra et'}
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </QueryNotice>
      </SectionCard>

      {/* ---------- Qərarlar ---------- */}
      <SectionCard title="AI Qərarları" subtitle={`${qerarlar.length} qərar`}>
        <QueryNotice {...qerarlarQuery}>
          {qerarlar.length === 0 ? (
            <p className="py-4 text-center text-sm text-gray-500">
              Məlumat yoxdur
            </p>
          ) : (
            <div className="grid gap-3 lg:grid-cols-2">
              {qerarlar.map((q) => {
                const eminlik = Number(q.eminlik ?? 0)
                const id = q.qerar_id ?? q.id
                return (
                  <div
                    key={id}
                    className="rounded-lg border border-gray-200 p-4"
                  >
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-medium text-gray-900">
                        {q.qerar_novu}
                      </span>
                      <Badge className="bg-cyan-50 text-cyan-700 ring-cyan-200">
                        Eminlik: %{eminlik}
                      </Badge>
                      <Badge className="bg-slate-100 text-slate-700 ring-slate-200">
                        {q.status
                          ? QERAR_STATUS_LABELS[q.status] || q.status
                          : '—'}
                      </Badge>
                    </div>
                    <p className="mt-2 text-sm text-gray-600">
                      {q.esaslandirma || 'Əsaslandırma yoxdur'}
                    </p>
                    {q.status === 'teklif' && (
                      <div className="mt-3 flex gap-2">
                        <button
                          onClick={() =>
                            qerarMutation.mutate({ id, aksiya: 'tesdiq' })
                          }
                          disabled={qerarMutation.isPending}
                          className="rounded-md bg-emerald-600 px-3 py-1.5 text-xs font-medium text-white transition hover:bg-emerald-700 disabled:opacity-50"
                        >
                          Təsdiqlə
                        </button>
                        <button
                          onClick={() =>
                            qerarMutation.mutate({ id, aksiya: 'redd' })
                          }
                          disabled={qerarMutation.isPending}
                          className="rounded-md bg-red-600 px-3 py-1.5 text-xs font-medium text-white transition hover:bg-red-700 disabled:opacity-50"
                        >
                          Rədd et
                        </button>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </QueryNotice>
      </SectionCard>

      {/* ---------- Proqnozlar / Mesajlar / Loqlar ---------- */}
      <div className="grid gap-6 lg:grid-cols-3">
        <div>
          <SectionCard
            title="Proqnozlar"
            subtitle={`${proqnozlar.length} proqnoz`}
          >
            <QueryNotice {...proqnozlarQuery}>
              {proqnozlar.length === 0 ? (
                <p className="py-4 text-center text-sm text-gray-500">
                  Məlumat yoxdur
                </p>
              ) : (
                <div className="space-y-3">
                  {proqnozlar.map((p) => (
                    <div
                      key={p.prognoz_id ?? p.id}
                      className="rounded-lg border border-gray-200 p-3"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            {proqnozLabel(p.prognoz_novu)}
                          </p>
                          <p className="text-xs text-gray-500">
                            {p.layihe_kod ?? p.layihe?.kod ?? '—'}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-sm font-semibold text-gray-900">
                            {formatAZN(p.prognoz_deyer)}
                          </p>
                          <p className="text-xs text-gray-500">
                            Ehtimal: %{p.ehtimal ?? 0}
                          </p>
                        </div>
                      </div>
                      {p.qeyd && (
                        <p className="mt-1 text-xs text-gray-500">{p.qeyd}</p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </QueryNotice>
          </SectionCard>
        </div>

        <div>
          <SectionCard
            title="Mesajlar"
            subtitle={`${mesajlar.length} mesaj`}
          >
            <QueryNotice {...mesajlarQuery}>
              {mesajlar.length === 0 ? (
                <p className="py-4 text-center text-sm text-gray-500">
                  Məlumat yoxdur
                </p>
              ) : (
                <div className="space-y-3">
                  {mesajlar.map((m) => {
                    const onem = String(m.onem || 'normal').toLowerCase()
                    const onemStyles = {
                      yuksek: 'bg-red-50 text-red-700 ring-red-200',
                      kritik: 'bg-red-100 text-red-800 ring-red-300',
                      normal: 'bg-slate-100 text-slate-700 ring-slate-200',
                      asagi: 'bg-gray-100 text-gray-600 ring-gray-200',
                    }
                    return (
                      <div
                        key={m.mesaj_id ?? m.id}
                        className="rounded-lg border border-gray-200 p-3"
                      >
                        <div className="flex items-center justify-between gap-2">
                          <p className="text-sm font-medium text-gray-900">
                            {m.movzu}
                          </p>
                          <Badge
                            className={
                              onemStyles[onem] || onemStyles.normal
                            }
                          >
                            {onemLabel(m.onem)}
                          </Badge>
                        </div>
                        <p className="mt-1 text-xs text-gray-600">{m.mezmun}</p>
                        <p className="mt-1 text-xs text-gray-400">
                          {formatDateTime(m.created_at)}
                        </p>
                      </div>
                    )
                  })}
                </div>
              )}
            </QueryNotice>
          </SectionCard>
        </div>

        <div>
          <SectionCard
            title="İcra loqları"
            subtitle={`${loglar.length} qeyd`}
          >
            <QueryNotice {...loglarQuery}>
              {loglar.length === 0 ? (
                <p className="py-4 text-center text-sm text-gray-500">
                  Məlumat yoxdur
                </p>
              ) : (
                <div className="space-y-3">
                  {loglar.map((l) => (
                    <div
                      key={l.log_id ?? l.id}
                      className="rounded-lg border border-gray-200 p-3"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <span
                            className={`inline-block h-2 w-2 rounded-full ${logColor(l.hadise)}`}
                          ></span>
                          <span className="text-sm font-medium text-gray-900">
                            {logHadiseLabel(l.hadise)}
                          </span>
                        </div>
                        <span className="text-xs text-gray-400">
                          {formatDateTime(l.created_at)}
                        </span>
                      </div>
                      <p className="mt-1 text-xs text-gray-600">{l.mesaj}</p>
                      {(l.serf_olunan_tokens != null ||
                        l.serf_olunan_xerc != null) && (
                        <p className="mt-1 text-xs text-gray-400">
                          {l.serf_olunan_tokens != null &&
                            `${l.serf_olunan_tokens} token`}
                          {l.serf_olunan_xerc != null &&
                            (l.serf_olunan_tokens != null ? ' · ' : '') +
                              formatAZN(l.serf_olunan_xerc)}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </QueryNotice>
          </SectionCard>
        </div>
      </div>
    </div>
  )
}
