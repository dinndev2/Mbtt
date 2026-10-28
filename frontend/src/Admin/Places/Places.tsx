import type { PlaceItem } from "@/App";
import { useState, useEffect, useMemo } from "react"
import { ChevronLeft, ChevronRight, Plus, Search } from "lucide-react"
import { Button, Card, Chip, Display, Input, Label, Loader, Muted } from "../../ui"
import Place from "./Place"
import Modal from "../../components/Modal"
import { searchFor } from "../../components/Search/Search";
import EditForm from "./EditForm";
import AddForm from "./AddForm";
import { useSearchParams } from "react-router";
import { trimString } from "../../components/Search/Search";

const ISLAND_FILTERS = ["All", "Masbate", "Ticao", "Burias"]
const PAGE_SIZE = 10

const headCell = "px-4 py-3 text-left font-mono text-[11px] font-medium uppercase tracking-[0.12em] text-venice"
type PageActions = "right" | "left";

// The table's order: search matches, by name. Pages are cut from this, so it
// has to sort the whole list -- sorting each page on its own reorders across pages.
function matching(places: PlaceItem[], query: string) {
  return searchFor(places, query).sort((a, b) => (a?.name ?? "").localeCompare(b?.name ?? ""))
}

export default function Places() {
  const API_URL = import.meta.env.VITE_API_URL;
  const [searchParams, setSearchParams] = useSearchParams();
  const [loading, setLoading] = useState(true)
  const [places, setPlaces] = useState<PlaceItem[]>([])
  const [highlightedPlaceId, setHighlightedPlaceId] = useState<number>()
  const [addingPlace, setAddPlaceModalContent] = useState(false)
  const [searchValue, setSearchValue] = useState("")
  const [editingPlace, setEditingPlace] = useState<PlaceItem | null>(null)
  const API = `${API_URL}/places`
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const island = searchParams.get('island') ?? "All"
  const matches = useMemo(() => matching(places, searchValue), [places, searchValue])
  // Worked out from the list and the URL on every render, so an edit, an add
  // or a delete can't leave the page number and the rows out of step.
  const totalPage = Math.max(1, Math.ceil(matches.length / PAGE_SIZE))
  // Clamped, so ?page=99, or a last page emptied by a delete, shows the last real page.
  const page = Math.min(Math.max(Number(searchParams.get('page')) || 1, 1), totalPage)
  const currentPagePlace = matches.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  useEffect(() => {
    fetchPlaces()
  }, [])

  // Pushes by default, so Back steps through the pages turned.
  function goToPage(nextPage: number, replace = false) {
    setSearchParams((params) => {
      params.set('page', String(nextPage))
      return params
    }, { replace })
  }

  function filterIsland(island: string) {
    // One update for both keys: two in the same tick would each start from the
    // same params, and the second would undo the first.
    setSearchParams((params) => {
      params.set('island', island)
      params.set('page', '1')
      return params
    })
    setSearchValue(island === "All" ? "" : trimString(island))
  }

  function movePage(action: PageActions) {
    const nextPage = action === 'right' ? page + 1 : page - 1
    if (nextPage < 1 || nextPage > totalPage) return
    goToPage(nextPage)
  }

  // Turn to the page the place ended up on so its highlight is in view: a new
  // place sorts in by name, and a rename can move one to another page.
  function showPlace(list: PlaceItem[], id: number) {
    const index = matching(list, searchValue).findIndex(p => p.id === id)
    const placePage = Math.floor(index / PAGE_SIZE) + 1
    if (index !== -1 && placePage !== page) goToPage(placePage)
    setHighlightedPlaceId(id)
  }

  function onSavedPlace(savedPlace: PlaceItem) {
    const next = places.map(p => p.id === savedPlace.id ? savedPlace : p)
    setPlaces(next)
    showPlace(next, savedPlace.id)
  }

  function onCreatedPlace(savedPlace: PlaceItem) {
    const next = [...places, savedPlace]
    setPlaces(next)
    showPlace(next, savedPlace.id)
  }

  function triggerSearch(e: React.ChangeEvent<HTMLInputElement>) {
    setSearchValue(e.target.value)
    // Replace, or every keystroke would be a history entry.
    if (page !== 1) goToPage(1, true)
  }

  async function onDelete (place: PlaceItem) {
     if(place.original) return
    const response = await fetch(`${API}/${place.id}`, {
      method: 'DELETE',
      credentials: "include",
      headers:  { "Content-Type": "application/json" }
    })
    
    if(response.ok) {
      setPlaces(prev => prev.filter(p => p.id != place.id))
    }
  }

  async function fetchPlaces () {
    try {
      const response = await fetch(API, {
        method: 'GET',
        credentials: "include"
      })
      const data = await response.json()
      setPlaces(data.places ?? [])
    } catch (e) {
        console.log(e)
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <Loader label="Loading places" />

  return <section className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-4 py-8 sm:p-10">
    {/* Header */}
    <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <Label>Admin</Label>
        <Display as="h1" size="lg" className="mt-2">Places</Display>
        <Muted className="mt-2">{places.length} places across Masbate, Ticao and Burias.</Muted>
      </div>
    <Button onClick={() => setAddPlaceModalContent(true)} className="inline-flex items-center justify-center gap-2 self-start sm:self-auto">
        <Plus className="size-4" /> Add place
      </Button>
    </div>

    {/* Toolbar */}
    <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
      <label className="relative w-full lg:max-w-sm">
        <span className="sr-only">Search places</span>
        <Search className="pointer-events-none absolute left-4 top-1/2 size-4 -translate-y-1/2 text-ink-soft" />
        <Input type="search" placeholder="Search by name, town or island" className="pl-10" onChange={triggerSearch} />
      </label>
      <div className="flex flex-wrap gap-2">
        {ISLAND_FILTERS.map((i) => (
          <Chip className="transition-all cursor-pointer" onClick={() => filterIsland(i)} key={i} active={i === island}>{i}</Chip>
        ))}
      </div>
    </div>

    {/* Table */}
    <Card className="overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-chip">
            <tr>
              <th scope="col" className={headCell}>Place</th>
              <th scope="col" className={headCell}>Island</th>
              <th scope="col" className={`${headCell} hidden md:table-cell`}>Town</th>
              <th scope="col" className={`${headCell} hidden lg:table-cell`}>Categories</th>
              <th scope="col" className={`${headCell} hidden md:table-cell`}>Coordinates</th>
              <th scope="col" className={`${headCell} hidden lg:table-cell`}>Prominence</th>
              <th scope="col" className={`${headCell} hidden text-right sm:table-cell`}>Photos</th>
              <th scope="col" className={`${headCell} text-right`}><span className="sr-only">Actions</span></th>
            </tr>
          </thead>
          <tbody>
            {currentPagePlace.length
              ? <>
                  {currentPagePlace.map((place) => <Place highlightedPlaceId={highlightedPlaceId} onDelete={onDelete} onEdit={() => setEditingPlace(place)} key={place.id} place={place} />)}
                  {/* Blank rows the height of a real one, so a short last
                      page keeps the table the size of a full page. */}
                  {Array.from({ length: PAGE_SIZE - currentPagePlace.length }, (_, i) => (
                    <tr key={`filler-${i}`} aria-hidden="true" className="border-t border-divider">
                      <td className="px-4 py-3">
                        <div className="invisible font-semibold">&nbsp;</div>
                        <div className="invisible font-mono text-[11px]">&nbsp;</div>
                      </td>
                      <td colSpan={7} />
                    </tr>
                  ))}
                </>
              : (
                <tr>
                  <td colSpan={8} className="px-4 py-16 text-center">
                    <Display as="p" size="sm">No places yet</Display>
                    <Muted className="mt-2">Add the first one, or try a different search.</Muted>
                  </td>
                </tr>
              )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between gap-4 border-t border-divider px-4 py-3">
        <Muted as="span" className="text-sm">
          Showing <span className="font-semibold text-ink">{matches.length ? `${(page - 1) * PAGE_SIZE + 1} - ${(page - 1) * PAGE_SIZE + currentPagePlace.length}` : "0"}</span> of{" "}
          <span className="font-semibold text-ink">{matches.length}</span>
        </Muted>
        <div className="flex items-center gap-1">
          <button
            onClick={() => movePage("left")}
            disabled={page === 1}
            type="button"
            aria-label="Previous page"
            className={`${page == 1 ? "text-gray-300" : "text-venice"} rounded-pill p-2 transition-colors hover:bg-venice-pale disabled:pointer-events-none disabled:opacity-40`}
          >
            <ChevronLeft className="size-4" />
          </button>
          <span className="px-2 font-mono text-xs text-ink-soft">{page} / {totalPage}</span>
          <button
            onClick={() => movePage("right")}
            disabled={page === totalPage}
            type="button"
            aria-label="Next page"
            className={`${page == totalPage ? "text-gray-300" : "text-venice"}  rounded-pill p-2  transition-colors hover:bg-venice-pale disabled:pointer-events-none disabled:opacity-40`}
          >
            <ChevronRight className="size-4" />
          </button>
        </div>
      </div>
    </Card>

    {editingPlace && (
      <Modal closePlaceModal={() => setEditingPlace(null)}>
        <div className="p-6 pt-12 md:p-8">
          <Label>Edit place</Label>
          <Display as="h2" size="md" className="mt-2">{editingPlace.name}</Display>
          <EditForm selectedFiles={selectedFiles} onSavedPlace={onSavedPlace} place={editingPlace} />
        </div>
      </Modal>
    )}
    {addingPlace && (
        <Modal closePlaceModal={() => setAddPlaceModalContent(false)}>
        <div className="p-6 pt-12 md:p-8">
          <Display as="h2" size="md" className="mt-2">Add Place</Display>
          <AddForm selectedFiles={selectedFiles} setSelectedFiles={setSelectedFiles} onCreatedPlace={ onCreatedPlace} />
        </div>
      </Modal>
    )}
  </section>
}
