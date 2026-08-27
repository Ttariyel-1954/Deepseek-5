import { Link } from 'react-router-dom'

export default function Error() {
  return (
    <div className="flex flex-col items-center justify-center py-24 text-center">
      <p className="text-6xl font-bold text-gray-300">404</p>
      <h1 className="mt-3 text-lg font-semibold text-gray-900">
        Səhifə tapılmadı
      </h1>
      <p className="mt-1 text-sm text-gray-500">
        Axtardığınız səhifə mövcud deyil və ya ünvan dəyişdirilib.
      </p>
      <Link
        to="/"
        className="mt-5 rounded-md bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-slate-700"
      >
        İdarə panelinə qayıt
      </Link>
    </div>
  )
}
