import { NavLink, useNavigate } from 'react-router-dom'
import { clearToken } from '../utils/auth'

const NAV_ITEMS = [
  { to: '/', label: 'İdarə paneli', end: true },
  { to: '/layiheler', label: 'Layihələr', end: false },
  { to: '/tenderler', label: 'Tenderlər', end: false },
  { to: '/ai', label: 'AI Paneli', end: false },
]

export default function Header() {
  const navigate = useNavigate()

  function handleLogout() {
    clearToken()
    navigate('/login', { replace: true })
  }

  return (
    <header className="bg-slate-900 text-white shadow">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-2">
          <span className="text-lg font-bold tracking-tight">DeepSeek-5 ERP</span>
        </div>
        <nav className="flex items-center gap-1 overflow-x-auto">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `whitespace-nowrap rounded-md px-3 py-2 text-sm font-medium transition ${
                  isActive
                    ? 'bg-slate-700 text-white'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
          <button
            onClick={handleLogout}
            className="ml-2 whitespace-nowrap rounded-md bg-red-600 px-3 py-2 text-sm font-medium text-white transition hover:bg-red-700"
          >
            Çıxış
          </button>
        </nav>
      </div>
    </header>
  )
}
