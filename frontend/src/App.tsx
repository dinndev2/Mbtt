import { useState, useEffect } from 'react'

interface Bundle {
  categories: [
    {
      name: string
      description: string
      slug: string
      id: number
    }
  ]
}

function App() {
  const [bundle, setBundle ] = useState<Bundle>()
  async function fetchCategories() {
    const data = await fetch('http://localhost:3000/api/v1/bundles', {
      method: 'GET'
    })
    const bundleData = await data.json()
    setBundle(bundleData)
  }
  useEffect(() => { 
    fetchCategories()
  }, [])

  return (
    <>
      {bundle?.categories.map(({slug, name, description}) => {
        return <p> {name} </p>
      })}
    </>
  )
}

export default App
