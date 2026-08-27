import { useQuery } from '@tanstack/react-query'
import api, { extractList } from '../services/api'
import { formatAZN, formatDate } from '../utils/format'

export default function Tenderler() {
  const query = useQuery({
    queryKey: ['tenderler'],
    queryFn: async () => extractList(await api.get('/tenderler')),
  })

  const list = query.data || []

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900">Tenderlər</h1>
        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-600">
          Cəmi: {list.length}
        </span>
      </div>

      {query.isError && (
        <div className="rounded-lg bg-red-50 p-4 text-sm text-red-700">
          Tender məlumatları yüklənmədi:{' '}
          {query.error?.response?.data?.mesaj ||
            query.error?.response?.data?.message ||
            query.error?.message}
        </div>
      )}

      <div className="overflow-hidden rounded-xl bg-white shadow-sm ring-1 ring-gray-200">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Kod
                </th>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Tender
                </th>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Layihə
                </th>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Status
                </th>
                <th className="px-5 py-3 text-right font-medium text-gray-500">
                  Qiymət sərhədi
                </th>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Elan tarixi
                </th>
                <th className="px-5 py-3 text-left font-medium text-gray-500">
                  Son tarix
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {query.isLoading && (
                <tr>
                  <td colSpan={7} className="px-5 py-6 text-center text-gray-500">
                    Yüklənir...
                  </td>
                </tr>
              )}
              {!query.isLoading &&
                list.map((t) => (
                  <tr key={t.tender_id ?? t.id} className="hover:bg-gray-50">
                    <td className="px-5 py-3 font-medium text-gray-900">
                      {t.kod}
                    </td>
                    <td className="px-5 py-3 text-gray-700">{t.ad}</td>
                    <td className="px-5 py-3 text-gray-600">
                      {t.layihe_kod ?? t.layihe?.kod ?? '—'}
                    </td>
                    <td className="px-5 py-3">
                      <span className="inline-flex rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-medium text-amber-700 ring-1 ring-inset ring-amber-200">
                        {t.status_ad ?? '—'}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right text-gray-700">
                      {formatAZN(t.qiymet_serhedi)}
                    </td>
                    <td className="px-5 py-3 text-gray-600">
                      {formatDate(t.elan_tarixi)}
                    </td>
                    <td className="px-5 py-3 text-gray-600">
                      {formatDate(t.son_tarix)}
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
          {!query.isLoading && !query.isError && list.length === 0 && (
            <p className="px-5 py-6 text-center text-sm text-gray-500">
              Məlumat yoxdur
            </p>
          )}
        </div>
      </div>
    </div>
  )
}
