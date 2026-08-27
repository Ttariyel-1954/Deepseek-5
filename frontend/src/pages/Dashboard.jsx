import { useQuery } from '@tanstack/react-query'
import api, { extractList } from '../services/api'
import { formatAZN } from '../utils/format'

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
  return map[key] || value || 'Aktiv'
}

function StatCard({ label, value, sub }) {
  return (
    <div className="rounded-xl bg-white p-5 shadow-sm ring-1 ring-gray-200">
      <p className="text-xs font-medium uppercase tracking-wide text-gray-500">
        {label}
      </p>
      <p className="mt-2 text-2xl font-bold text-gray-900">{value}</p>
      {sub && <p className="mt-1 text-xs text-gray-500">{sub}</p>}
    </div>
  )
}

export default function Dashboard() {
  const layihelerQuery = useQuery({
    queryKey: ['layiheler'],
    queryFn: async () => extractList(await api.get('/layiheler')),
  })
  const healthQuery = useQuery({
    queryKey: ['health'],
    queryFn: async () => (await api.get('/health')).data,
    retry: 0,
    refetchInterval: 30000,
  })
  const aiStatusQuery = useQuery({
    queryKey: ['ai-status'],
    queryFn: async () => (await api.get('/ai/status')).data,
    retry: 0,
  })

  const layiheler = layihelerQuery.data || []
  const toplamBudce = layiheler.reduce(
    (sum, l) => sum + Number(l.plan_budce ?? 0),
    0
  )
  const toplamXerc = layiheler.reduce(
    (sum, l) => sum + Number(l.fakt_xerc ?? 0),
    0
  )
  const aiMode = aiStatusQuery.data?.AI_MODE ?? aiStatusQuery.data?.ai_mode

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold text-gray-900">İdarə paneli</h1>
        <div
          className={`flex items-center gap-2 rounded-full px-3 py-1 text-xs font-medium ${
            healthQuery.isError
              ? 'bg-red-100 text-red-700'
              : 'bg-emerald-100 text-emerald-700'
          }`}
        >
          <span
            className={`h-2 w-2 rounded-full ${
              healthQuery.isError ? 'bg-red-500' : 'bg-emerald-500'
            }`}
          />
          {healthQuery.isError ? 'API əlaqəsi yoxdur' : 'API aktiv'}
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Layihə sayı"
          value={layiheler.length}
          sub={layihelerQuery.isError ? 'Yüklənmədi' : 'aktiv layihələr'}
        />
        <StatCard label="Plan büdcə" value={formatAZN(toplamBudce)} />
        <StatCard label="Faktiki xərc" value={formatAZN(toplamXerc)} />
        <StatCard
          label="AI status"
          value={aiStatusQuery.isError ? '—' : aiModeLabel(aiMode)}
          sub={aiStatusQuery.isLoading ? 'Yoxlanılır...' : undefined}
        />
      </div>

      {layihelerQuery.isError && (
        <div className="rounded-lg bg-red-50 p-4 text-sm text-red-700">
          Layihə məlumatları yüklənmədi:{' '}
          {layihelerQuery.error?.response?.data?.mesaj ||
            layihelerQuery.error?.response?.data?.message ||
            layihelerQuery.error?.message}
        </div>
      )}

      <div className="overflow-hidden rounded-xl bg-white shadow-sm ring-1 ring-gray-200">
        <div className="border-b border-gray-100 px-5 py-4">
          <h2 className="text-sm font-semibold text-gray-900">Son layihələr</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Kod
                </th>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Layihə
                </th>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Status
                </th>
                <th className="px-5 py-3 text-right font-medium text-gray-500">
                  Plan büdcə
                </th>
                <th className="px-5 py-3 text-right font-medium text-gray-500">
                  Faktiki xərc
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {layihelerQuery.isLoading && (
                <tr>
                  <td colSpan={5} className="px-5 py-6 text-center text-gray-500">
                    Yüklənir...
                  </td>
                </tr>
              )}
              {!layihelerQuery.isLoading &&
                layiheler.slice(0, 5).map((l) => (
                  <tr key={l.layihe_id ?? l.id} className="hover:bg-gray-50">
                    <td className="px-5 py-3 font-medium text-gray-900">
                      {l.kod}
                    </td>
                    <td className="px-5 py-3 text-gray-700">{l.ad}</td>
                    <td className="px-5 py-3">
                      <span className="inline-flex rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-700 ring-1 ring-inset ring-slate-200">
                        {l.status_ad ?? '—'}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right text-gray-700">
                      {formatAZN(l.plan_budce)}
                    </td>
                    <td className="px-5 py-3 text-right text-gray-700">
                      {formatAZN(l.fakt_xerc)}
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
          {!layihelerQuery.isLoading &&
            !layihelerQuery.isError &&
            layiheler.length === 0 && (
              <p className="px-5 py-6 text-center text-sm text-gray-500">
                Məlumat yoxdur
              </p>
            )}
        </div>
      </div>
    </div>
  )
}
