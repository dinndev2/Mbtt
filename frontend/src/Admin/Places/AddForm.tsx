import { useContext, useRef, useState, useEffect } from "react"
import { ModalControlContext } from "../../components/Modal"
import { Button } from "../../ui"
import PlaceFields from "./PlaceFields"
import { AuthContext } from "../../api/AuthContext"
import { type PlaceItem, } from "../../App"


export default function AddForm({ onCreatedPlace, selectedFiles, setSelectedFiles}: { onCreatedPlace: (place: PlaceItem) => void, selectedFiles: File[], setSelectedFiles: React.Dispatch<React.SetStateAction<File[]>> }) {
  const API_URL = import.meta.env.VITE_API_URL;
  const API = `${API_URL}/places`
  const [loading, setLoading] = useState(false)
  const requestClose = useContext(ModalControlContext)?.requestClose
  const setAlert = useContext(AuthContext)?.setAlert
  const ref = useRef<HTMLFormElement>(null)
  const body = new FormData()

  function handleSelectedMultipleFiles (e: React.ChangeEvent<HTMLInputElement> ) {
    setSelectedFiles(Array.from(e.target.files ?? []))
  }

  async function onAdd(e: React.SubmitEvent<HTMLFormElement>) {
    e.preventDefault()
    const form = ref.current; if(!form) return 
    for (const [key, value] of new FormData(form)) body.append(`place[${key}]`, value)
      selectedFiles.forEach((file, index) => body.append(`place[images_attributes][${index}][image]`, file))
    setLoading(true)
    try {
      const response = await fetch(API, {
        method: 'POST',
        credentials: "include",
        body,
      })
      const data = await response.json()
      if(response.ok) { 
        onCreatedPlace(data.place)
        requestClose?.()
        if(setAlert) setAlert("Created")
      }
    } catch (e) {
      if(setAlert) setAlert("") 
    } finally {
      setLoading(false)
    }
  }

  return <form ref={ref} onSubmit={onAdd} className="mt-6 flex flex-col gap-8">
    <PlaceFields handleSelectedMultipleFiles={handleSelectedMultipleFiles}/>
    <div className="sticky bottom-0 -mx-6 flex justify-end gap-2 border-t border-divider bg-surface px-6 py-4 md:-mx-8 md:px-8">
      <Button disabled={loading} variant="ghost" onClick={() => requestClose?.()}>Cancel</Button>
      <Button disabled={loading} type="submit">{loading ? "Adding…" : "Add place"}</Button>
    </div>
  </form>
}
