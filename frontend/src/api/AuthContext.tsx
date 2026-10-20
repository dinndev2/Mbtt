import { createContext, type ReactNode, useEffect, useState } from "react";

type currentUser = {
  email: string
  name: string
  id: number
}


type Error = {
  type: string
  details: string
}

type AuthContextType = {
  user: currentUser | null
  loading: boolean
  error: Error | null
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

export const AuthContext = createContext<AuthContextType | null>(null)


export default function Auth({ children }: {children: ReactNode}) {
  const [currentUser, setCurrentUser] = useState<currentUser | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)
  const API_URL = import.meta.env.VITE_API_URL;
  const API = `${API_URL}/sessions`

  useEffect(() => {
    async function checkSession() {
      try {
        const response = await fetch(API, {
          method: "GET",
          credentials: "include"})
        const data = await response.json()
        if (response.ok) {
          setCurrentUser({ email: data.email, name: data.name, id: data.id })
        }
      } finally {
        setLoading(false)
      }
    }
    checkSession()
  },[])

  async function logout() {
    await fetch(API, {
      method: "DELETE",
      credentials: "include"
    })
    setCurrentUser(null)
  }

  async function login (email: string, password: string){
    const response = await fetch(API, {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password })
    })
    const data = await response.json()

    if (!response.ok) {
      setError({type: "error", details: `${data.error}`})
      throw new Error(data.error ?? "Login failed");
    }

    setCurrentUser({email: data.email, name: data.name, id: data.id})

  }

  const contextData: AuthContextType = {
    user: currentUser,
    login: login,
    error: error,
    logout: logout,
    loading: loading
  }
  return <AuthContext.Provider value={contextData}>
    {children}
  </AuthContext.Provider>
}