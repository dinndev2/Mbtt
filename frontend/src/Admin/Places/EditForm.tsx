import { type PlaceItem } from "../../App"
import  { useRef, useState, useContext} from "react"
import { AuthContext } from "../../api/AuthContext"
import { ModalControlContext } from "../../components/Modal"
import { Button } from "../../ui"
import PlaceFields from "./PlaceFields"



export default function EditForm({place, onSavedPlace}: {place: PlaceItem; onSavedPlace: (place: PlaceItem) => void}) {
  const API_URL = import.meta.env.VITE_API_URL;
  const API = `${API_URL}/places`
  const placeData = useRef<HTMLFormElement>(null)
  const [loading, setLoading] = useState(false)
  const [updatedPlace, setUpdatedPlace] = useState<PlaceItem | null >(place)
  const context = useContext(AuthContext)
  const setAlert = context?.setAlert
  const requestClose = useContext(ModalControlContext)?.requestClose

  async function onEdit(e: React.SubmitEvent) {
    e.preventDefault()
    const form = placeData.current; if(!form) return
    const formValue = new FormData(form)
    try {
      setLoading(true)
      const response = await fetch(`${API}/${place.id}`, {
        method: 'PUT',
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ place: Object.fromEntries(formValue.entries()) })
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
    <PlaceFields place={updatedPlace} />

    {/* Sticks to the bottom of the modal's scroll area so Save stays in reach. */}
    <div className="sticky bottom-0 -mx-6 flex justify-end gap-2 border-t border-divider bg-surface px-6 py-4 md:-mx-8 md:px-8">
      <Button disabled={loading} variant="ghost" onClick={() => requestClose?.()}>Cancel</Button>
      <Button type="submit">{loading ? "Saving.." : "Save Changes"}</Button>
    </div>
  </form>}
  </>
}
