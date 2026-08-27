import axios from 'axios'
import { getToken, clearToken } from '../utils/auth'

const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = getToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (res) => res,
  (error) => {
    const config = error.config
    const isLogin =
      config && config.url && String(config.url).includes('/auth/login')
    if (error.response && error.response.status === 401 && !isLogin) {
      clearToken()
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

/**
 * API cavabından massivi çıxarır.
 * Dəstəklənən formalar:
 *   - birbaşa massiv: [...]
 *   - { data: [...] }
 *   - { status, total, data: [...] }
 *   - { items: [...] }
 */
export function extractList(response) {
  const payload = response?.data
  if (Array.isArray(payload)) return payload
  if (payload && Array.isArray(payload.data)) return payload.data
  if (payload && Array.isArray(payload.items)) return payload.items
  return []
}

export default api
