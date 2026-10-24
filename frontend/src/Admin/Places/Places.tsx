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

const headCell = "px-4 py-3 text-left font-mono text-[11px] font-medium uppercase tracking-[0.12em] text-venice"
type PageActions = "right" | "left";

export default function Places() {
  const API_URL = import.meta.env.VITE_API_URL;
  const [islandParams, setIslandParams] = useSearchParams();
  const [loading, setLoading] = useState(true)
  const [places, setPlaces] = useState<PlaceItem[]>([])
  const [totalPage, setTotalPage] = useState(1)
  const [currentPagePlace, setCurrentPagePlace] = useState<PlaceItem []>([])
  const [page, setPage] = useState(1)
  const [addingPlace, setAddPlaceModalContent] = useState(false)
  const [searchValue, setSearchValue] = useState("")
  const [editingPlace, setEditingPlace] = useState<PlaceItem | null>(null)
  const API = `${API_URL}/places`
  const island = islandParams.get('island') ?? "All"
  const filteredPlace = island == "All" ? places : places.filter(p => p.island?.toLowerCase() == island.toLowerCase() )
  const result = useMemo(() => searchFor(places, searchValue).slice(0, 10).sort((a, b) => (a?.name ?? "").localeCompare((b?.name ?? "")) ), [places, searchValue])

  useEffect(() => {
    setCurrentPagePlace(result)
  }, [result])

  useEffect(() => {
    fetchPlaces()
  }, [])

  function filterIsland(island: string) {
    setIslandParams((params) => {
      params.set('island', island) 
      return params
    })
    setSearchValue(island === "All" ? "" : trimString(island))

  }

  function movePage(action: PageActions) {
    let nextPage = page
    if(action === 'right' && page != totalPage) nextPage = page + 1
    if(action === 'left' && page != 1) nextPage = page - 1

    setPage(nextPage)
    const paginated = places.slice((nextPage - 1) * 10, nextPage * 10)
    setCurrentPagePlace(paginated)
  }

  function onSavedPlace(savedPlace: PlaceItem) {
    setPlaces((prev) => prev.map(p => p.id === savedPlace.id ? savedPlace : p ))
  }

  function onCreatedPlace(savedPlace: PlaceItem) {
    setPlaces((prev) => [...prev, savedPlace])
  }


  function triggerSearch(e: React.ChangeEvent<HTMLInputElement>) {
    setSearchValue(e.target.value)
  }

  async function onDelete (place: PlaceItem) {
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
      data.places?.length > 1 && setTotalPage(Math.ceil(data.places.length / 10))
      setCurrentPagePlace(data.places.slice(0, 10))
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
                  {currentPagePlace.map((place) => <Place onDelete={onDelete} onEdit={() => setEditingPlace(place)} key={place.id} place={place} />)}
                  {/* Blank rows the height of a real one, so a short last
                      page keeps the table the size of a full page. */}
                  {Array.from({ length: 10 - currentPagePlace.length }, (_, i) => (
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
          Showing <span className="font-semibold text-ink">{`${((page - 1) * 10) + 1} - ${ page * 10 }`}</span> of{" "}
          <span className="font-semibold text-ink">{ places.length}</span>
        </Muted>
        <div className="flex items-center gap-1">
          <button
            onClick={() => movePage("left")}
            type="button"
            aria-label="Previous page"
            className={`${page == 1 ? "text-gray-300" : "text-venice"} rounded-pill p-2 transition-colors hover:bg-venice-pale disabled:pointer-events-none disabled:opacity-40`}
          >
            <ChevronLeft className="size-4" />
          </button>
          <span className="px-2 font-mono text-xs text-ink-soft">{page} / {totalPage}</span>
          <button
            onClick={() => movePage("right")}
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
          <EditForm onSavedPlace={onSavedPlace} place={editingPlace} />
        </div>
      </Modal>
    )}
    {addingPlace && (
        <Modal closePlaceModal={() => setAddPlaceModalContent(false)}>
        <div className="p-6 pt-12 md:p-8">
          <Display as="h2" size="md" className="mt-2">Add Place</Display>
          <AddForm onCreatedPlace={ onCreatedPlace} />
        </div>
      </Modal>
    )}
  </section>
}
