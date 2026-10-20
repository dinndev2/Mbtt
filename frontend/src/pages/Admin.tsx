import { useRef, useState } from 'react'

export default function Admin() {
  const userData = useRef<HTMLFormElement>(null)
  const API_URL = import.meta.env.VITE_API_URL;
  const API = `${API_URL}/places`

  return <>
    Welcome
   </>
}

