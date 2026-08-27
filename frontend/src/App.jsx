import { Routes, Route, Navigate } from 'react-router-dom'
import { isAuthenticated } from './utils/auth'
import Layout from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Layiheler from './pages/Layiheler'
import Tenderler from './pages/Tenderler'
import AiPaneli from './pages/AiPaneli'
import Error from './pages/Error'

function ProtectedRoute({ children }) {
  if (!isAuthenticated()) {
    return <Navigate to="/login" replace />
  }
  return children
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Dashboard />} />
        <Route path="layiheler" element={<Layiheler />} />
        <Route path="tenderler" element={<Tenderler />} />
        <Route path="ai" element={<AiPaneli />} />
        <Route path="*" element={<Error />} />
      </Route>
    </Routes>
  )
}
