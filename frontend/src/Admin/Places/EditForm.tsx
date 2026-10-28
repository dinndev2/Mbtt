import { type PlaceItem } from "../../App"
import  { useRef, useState, useContext} from "react"
import { AuthContext } from "../../api/AuthContext"
import { ModalControlContext } from "../../components/Modal"
import { Button } from "../../ui"
import PlaceFields from "./PlaceFields"



export default function EditForm({place, onSavedPlace, selectedFiles}: {place: PlaceItem; onSavedPlace: (place: PlaceItem) => void, selectedFiles: File[]}) {
  const API_URL = import.meta.env.VITE_API_URL;
  const API = `${API_URL}/places`
  const placeData = useRef<HTMLFormElement>(null)
  const [loading, setLoading] = useState(false)
  const [updatedPlace, setUpdatedPlace] = useState<PlaceItem | null >(place)
  const context = useContext(AuthContext)
  const setAlert = context?.setAlert
  const requestClose = useContext(ModalControlContext)?.requestClose
  const [removedIds, setRemovedIds] = useState<number[]>([])


  function handleDeleteMultipleFiles(id: number) {
    setRemovedIds(prev => prev.includes(id) ? prev : [...prev, id] )
  }
  
  async function onEdit(e: React.SubmitEvent) {
    let i = 0
    e.preventDefault()
    const form = placeData.current; if(!form) return
    const body = new FormData(form)
    removedIds.forEach(id => {
      body.append(`place[images_attributes][${i}][id]`, String(id))
      body.append(`place[images_attributes][${i++}][_destroy]`, "1")

    })
    selectedFiles.forEach(file => body.append(`place[images_attributes][${i++}][image]`, file))

    for (const [key, value] of new FormData(form)) body.append(`place[${key}]`, value)
    try {
      setLoading(true)
      const response = await fetch(`${API}/${place.id}`, {
        method: 'PUT',
        credentials: "include",
        body
      })
      const data = await response.json()
      if(response.ok) {
        if (data) {
          setUpdatedPlace(data.place)
          onSavedPlace(data.place)
          requestClose?.()
        }
        if(setAlert) setAlert("Saved")
      }
    }  catch (e) {
      console.log(e)
    } finally {
      setLoading(false)
    }
  } 


  return <>
    {updatedPlace && <form ref={placeData} onSubmit={onEdit} className="mt-6 flex flex-col gap-8">
    <PlaceFields  handleDeleteMultipleFiles={handleDeleteMultipleFiles} place={{ ...updatedPlace, images: updatedPlace.images.filter(image => !removedIds.includes(image.id)) }} />

    {/* Sticks to the bottom of the modal's scroll area so Save stays in reach. */}
    <div className="sticky bottom-0 -mx-6 flex justify-end gap-2 border-t border-divider bg-surface px-6 py-4 md:-mx-8 md:px-8">
      <Button disabled={loading} variant="ghost" onClick={() => requestClose?.()}>Cancel</Button>
      <Button type="submit">{loading ? "Saving.." : "Save Changes"}</Button>
    </div>
  </form>}
  </>
}
