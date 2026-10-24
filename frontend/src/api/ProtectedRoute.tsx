import { Outlet, Navigate } from "react-router"
import { useContext } from "react"
import { AuthContext } from "./AuthContext"
import { Loader } from "../ui"

export default function ProtectedRoute() {
  const auth = useContext(AuthContext);

  if(auth?.loading) return <Loader fullscreen label="Checking your session" />
  if(!auth?.user) return  <Navigate to="/login" replace />


  return <Outlet />
}
