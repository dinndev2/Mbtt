import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { BrowserRouter, Routes, Route } from "react-router";
import Admin from './pages/Admin.tsx';
import Login from './pages/Login.tsx'
import Auth from './api/AuthContext.tsx';
import ProtectedRoute from './api/ProtectedRoute.tsx';





createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <Auth>
        <Routes >
          <Route element={<App />}  index/> 
          <Route path="login" element={<Login />} />
          <Route element={ <ProtectedRoute /> }>
            <Route path="admin" element={<Admin />} />
          </Route>
        </Routes>
      </Auth>  
    </BrowserRouter>
  </StrictMode>,
)
