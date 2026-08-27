import { useState } from 'react'
import { useNavigate, Navigate } from 'react-router-dom'
import api from '../services/api'
import { setToken, isAuthenticated } from '../utils/auth'

export default function Login() {
  const navigate = useNavigate()
  const [form, setForm] = useState({ usernameOrEmail: '', password: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  if (isAuthenticated()) {
    return <Navigate to="/" replace />
  }

  function handleChange(e) {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const res = await api.post('/auth/login', form)
      const token = res.data?.token
      if (!token) throw new Error('Token tapılmadı')
      setToken(token)
      navigate('/', { replace: true })
    } catch (err) {
      setError(
        err.response?.data?.mesaj ||
          err.response?.data?.message ||
          'Giriş uğursuz oldu. İstifadəçi adı və ya şifrə yanlışdır.'
      )
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-900 px-4">
      <div className="w-full max-w-md rounded-xl bg-white p-8 shadow-xl">
        <h1 className="text-center text-2xl font-bold text-slate-900">
          DeepSeek-5 ERP
        </h1>
        <p className="mt-1 text-center text-sm text-slate-500">
          Təsərrüfathesablı Əsaslı Tikinti və Təchizat İdarəsi
        </p>
        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label
              htmlFor="usernameOrEmail"
              className="mb-1 block text-sm font-medium text-slate-700"
            >
              İstifadəçi adı və ya e-poçt
            </label>
            <input
              id="usernameOrEmail"
              name="usernameOrEmail"
              type="text"
              value={form.usernameOrEmail}
              onChange={handleChange}
              required
              autoComplete="username"
              className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none"
            />
          </div>
          <div>
            <label
              htmlFor="password"
              className="mb-1 block text-sm font-medium text-slate-700"
            >
              Şifrə
            </label>
            <input
              id="password"
              name="password"
              type="password"
              value={form.password}
              onChange={handleChange}
              required
              autoComplete="current-password"
              className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:border-slate-500 focus:outline-none"
            />
          </div>
          {error && (
            <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">
              {error}
            </p>
          )}
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-md bg-slate-900 py-2 text-sm font-semibold text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? 'Daxil olunur...' : 'Daxil ol'}
          </button>
        </form>
      </div>
    </div>
  )
}
