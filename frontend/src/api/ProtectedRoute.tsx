import { useNavigate, Outlet } from "react-router"
import { useContext } from "react"
import { AuthContext } from "./AuthContext"

export default function ProtectedRoute() {
  const context = useContext(AuthContext);
  const user = context?.user
  const navigate = useNavigate()
  if(!user) {
    navigate('/login', { replace: true })
  }

  return <Outlet />
}