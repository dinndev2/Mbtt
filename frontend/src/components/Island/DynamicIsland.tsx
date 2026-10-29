import { Label, Button } from "../../ui"
import { ChevronDown, SearchIcon } from "lucide-react"
import { Search } from "../Search/Search"
import {  type Place, type PlaceItem } from "../../App"
import { ModalContext } from "../../App"
import { useContext } from "react"
import { useSearchParams } from "react-router";
import { titleize } from "../../utilities"
export default function DynamicIsland ({ places, setCurrentSelectedPlace, currentSelectedPlace, openIslandModal }: { places: Place, setCurrentSelectedPlace: React.Dispatch<React.SetStateAction<PlaceItem | null>>,currentSelectedPlace: PlaceItem | null, openIslandModal: () => void } ) {
  const placeModal = useContext(ModalContext)
  const [searchParams, _] = useSearchParams("");
  const openPlaceModal = placeModal?.openPlaceModal
  const islandParams = searchParams.get('island') || "Masbate"
  const usableButton = Boolean(openPlaceModal && currentSelectedPlace)

  // Stacks on phones - three fields side by side leave the search input a
  // few characters wide at 360px - and becomes one bar from md.
  return <div className="relative flex w-full flex-col gap-3 rounded-card border border-divider bg-surface p-3 shadow-[0_6px_20px_-10px_#17206e40] md:flex-row md:items-center md:gap-0 md:p-2 md:pl-6">
    <button onClick={ () => openIslandModal() } aria-haspopup className="flex cursor-pointer flex-col gap-1 px-2 py-1 text-left md:w-1/4 md:px-0">
      <Label>Leaving from</Label>
      <span className="flex items-center gap-2">
        <span className="text-base font-semibold">{titleize(islandParams)}</span>
        <ChevronDown className="text-venice" size={15} />
      </span>
    </button>
    <div className="flex flex-1 flex-col gap-1 border-t border-divider px-2 pt-3 md:mr-4 md:border-t-0 md:border-l md:px-0 md:pt-0 md:pl-5">
      <Label>Going to</Label>
      <Search places={places} setCurrentSelectedPlace={setCurrentSelectedPlace} />
    </div>
    <Button disabled={!usableButton} onClick={() => openPlaceModal && openPlaceModal()} className="flex min-w-0 cursor-pointer items-center justify-center gap-2 py-4 md:w-56">
      <SearchIcon size={15} className="shrink-0" />
      <span className="truncate">{currentSelectedPlace ? `View ${currentSelectedPlace.name}` : "View place"}</span>
    </Button>
  </div>
}

