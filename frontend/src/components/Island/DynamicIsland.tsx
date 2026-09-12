import { Label, Button } from "../../ui"
import { ChevronDown, SearchIcon } from "lucide-react"
import { Search } from "../Search/Search"
import {  type Place, type PlaceItem } from "../../App"
import { ModalContext } from "../../App"
import { useContext } from "react"

export default function DynamicIsland ({ places, setCurrentSelectedPlace, currentSelectedPlace, openIslandModal }: { places: Place, setCurrentSelectedPlace: React.Dispatch<React.SetStateAction<PlaceItem | null>>,currentSelectedPlace: PlaceItem | null, openIslandModal: () => void } ) {
  const placeModal = useContext(ModalContext)
  const openPlaceModal = placeModal?.openPlaceModal
  const usableButton = Boolean(openPlaceModal && currentSelectedPlace)

  return <div className="relative w-full py-12 px-8 justify-between shadow-md h-22 rounded-3xl cursor-pointer bg-white hover:shadow-xl border-gray-200 flex items-center">
    <button onClick={ () => openIslandModal() } aria-haspopup className="flex flex-col gap-2 w-1/4  ">
      <Label className="text-left text-xs">leaving from</Label>
      <div className="flex items-center gap-2">
        <span className="text-base font-semibold">Ticao</span>
        <ChevronDown className="text-venice" size={15} />
      </div>
    </button>
    {/* A plain div, not a button: it carries no onClick of its own, and the
        search input and result list inside it are the real controls. Nesting
        those in a button is invalid HTML and cost the results list its
        keyboard access. */}
    <div className="flex flex-col gap-2 justify-center w-1/2 border-l border-l-divider pl-5">
      <Label className="text-left text-xs">going to</Label>
      <div className="flex items-center gap-2 justify-between">
        <Search currentSelectedPlace={currentSelectedPlace} places={places} setCurrentSelectedPlace={setCurrentSelectedPlace} />
        <ChevronDown className="text-venice" size={15} />
      </div>
    </div>
    <Button disabled={!usableButton} onClick={() => openPlaceModal && openPlaceModal()} className="flex gap-2 w-50 items-center py-4 justify-center">
      <SearchIcon size={15} />
      {currentSelectedPlace ? `View ${currentSelectedPlace?.name?.slice(0, 12) + "..."}` : "View place"}
    </Button>
  </div>
}

