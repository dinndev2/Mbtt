import { useState, useEffect, createContext } from 'react'
import { useSearchParams } from "react-router";
import { Island } from './components/Island/Island';
import DynamicIsland from './components/Island/DynamicIsland';
import IslandSelector from './components/Island/IslandSelector';
import { createPortal } from "react-dom"
import { Display, Muted } from './ui';
import PlaceModalContent from './components/Place/PlaceModalContent';
import Modal from './components/Modal';
export type CategoryItem = {
  id: number
  name: string
  slug: string | null
  description: string | null
}

export type VihicleItem = {
  id: number
  name: string
  route_type: 'road' | 'ferry'
}

export type StopItem = {
  id: number
  gtfs_id: string
  name: string
  latitude: number | null
  longitude: number | null
}

export type PlaceImageItem = {
  url: string
  license: string
  attribution: string | null
  source_page: string | null
  /** Must be displayed wherever the photo is - all images are CC BY-SA. */
  credit: string
}

/** How a fare is charged. per_boat is split across the party; per_person is not. */
export type FareBasis = 'per_person' | 'per_boat' | 'per_vehicle'
export type FareKind = 'ticket' | 'range' | 'negotiated' | 'hire'
export type Confidence = 'published' | 'reported' | 'estimate' | 'stale' | 'unknown'

/**
 * How far to trust the timetable for a hop, as opposed to its price. Null when
 * no GTFS route is priced by the leg. Nothing in the feed is `published` -
 * every ferry time came from an aggregator or a blog, never the operator.
 */
export type LegSchedule = {
  confidence: Confidence
  as_of: string | null
  source_url: string | null
  note: string | null
}

export type FareLegItem = {
  id: string
  mode: string | null
  from: string | null
  to: string | null
  amount_min_php: number | null
  amount_max_php: number | null
  basis: FareBasis
  covers_pax: number
  fare_kind: FareKind
  duration_min: number | null
  confidence: Confidence
  valid_as_of: string | null
  source_url: string | null
  notes: string | null
  schedule: LegSchedule | null
}

export type FareFeeItem = {
  label: string
  amount_min_php: number | null
  amount_max_php: number | null
  basis: FareBasis
  required: boolean
  confidence: Confidence
}

/** One costed way in, for the party size requested. */
export type FareEstimateItem = {
  /** 'A', 'B', ... - alternative routes in, not consecutive steps. */
  option: string
  pax: number
  min_php: number | null
  max_php: number | null
  /** Preformatted, e.g. "PHP 1080-1550". */
  label: string
  duration_min: number | null
  exact: boolean
  /** False when a leg has no published fare - show the total as "from X". */
  complete: boolean
  unpriced_legs: string[]
  negotiable: boolean
  /** True when a boat hire dominates, so the per-person cost drops with group size. */
  group_sensitive: boolean
  confidence: Confidence
  oldest_source: string | null
  legs: FareLegItem[]
  fees: FareFeeItem[]
}

/**
 * How well known a place is, measured as published coverage - nothing in this
 * project counts visits. Render this as "best known on Ticao", never as "most
 * visited". `rank` is province-wide; inside an island-filtered bundle, sorting
 * by it already gives the island order.
 */
export type Prominence = {
  rank: number | null
  tier: 'anchor' | 'established' | 'documented' | 'sparse' | 'unverified' | null
  source_count: number | null
  basis: string | null
  as_of: string | null
}

export type PlaceItem = {
  id: number
  external_id: string
  name: string | undefined
  description: string | null
  latitude: number | null
  longitude: number | null
  municipality: string | null
  island: string | null
  coord_status: string | null
  /** Only `verified` is survey-grade; the rest are municipality centroids. */
  coordinates_approximate: boolean
  travel_time_note: string | null
  access_note: string | null
  source: string | null
  prominence: Prominence
  categories: CategoryItem[]
  vihicles: VihicleItem[]
  stop: StopItem | null
  images: PlaceImageItem[]
  fare_estimates: FareEstimateItem[]
}

export type AdvisoryScope = 'province' | 'island' | 'municipality' | 'place' | 'route' | 'leg'
export type AdvisoryKind =
  | 'season' | 'tide' | 'last_departure' | 'cash' | 'permit' | 'fee'
  | 'safety' | 'connectivity' | 'access' | 'event' | 'disruption'
/** info: worth knowing. plan: changes what you book. warn: could strand you. */
export type AdvisorySeverity = 'info' | 'plan' | 'warn'

/**
 * A hand-written operational note - the thing a local would tell you that no
 * fare table or timetable holds.
 *
 * Every one of these is a claim about how things *usually* are, never about
 * right now, which is what lets them ship in the bundle and stay true offline.
 * There is deliberately no server-computed "applies today" flag: the client
 * owns the clock and may be days offline, so it evaluates the season itself
 * with `isInSeason` below.
 */
export type AdvisoryItem = {
  id: string
  scope: AdvisoryScope
  /** A place's external_id, a route's gtfs_id, or an island name. Null province-wide. */
  scope_ref: string | null
  kind: AdvisoryKind
  severity: AdvisorySeverity
  headline: string
  detail: string | null
  /** MM-DD, inclusive. May wrap the new year. Both null = applies all year. */
  season_from: string | null
  season_to: string | null
  confidence: Confidence
  valid_as_of: string | null
  source_url: string | null
}

/**
 * Whether an advisory applies on `date`. The dry season runs 11-01 to 04-30,
 * so it wraps the new year and a plain range check gets December wrong.
 */
export function isInSeason(advisory: AdvisoryItem, date = new Date()): boolean {
  const { season_from: from, season_to: to } = advisory
  if (!from || !to) return true

  const today = `${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
  return from <= to ? today >= from && today <= to : today >= from || today <= to
}

export type IslandItem = {
  id: number
  name: string
  description: string
}

export type BundleMeta = {
  pax: number
  island: string | null
  currency: 'PHP'
  data_quality: 'researched'
}

// The plural aliases the components already pass around.
export type Category = CategoryItem[]
export type Place = PlaceItem[]
type Island = IslandItem[]

export type Bundle = {
  categories: Category
  places: Place
  islands: Island
  /** Already scoped to the island when the request carried one. Sorted warn-first. */
  advisories: AdvisoryItem[]
  meta: BundleMeta
}

type ModalContentContextType = {
  closePlaceModal: () => void
  openPlaceModal: () => void
  placeModal: boolean
}

export const ModalContext = createContext<ModalContentContextType | null>(null)

function App() { 
  const [bundle, setBundle ] = useState<Bundle>()
  const [islandParams, setIslandParams] = useSearchParams();
  const [islandSelectorVisibility, setIslandSelectorVisibility] = useState(false)
  const [currentSelectedPlace, setCurrentSelectedPlace] = useState<PlaceItem | null>(null)
  const islandQuery = islandParams.get('island') || "masbate"
  const [placeModal, setPlaceModal] = useState(false)
  const root = document.querySelector("#root")
  
  async function fetchCategories() {
    const data = await fetch('http://localhost:3000/api/v1/bundles', {
      method: 'GET'
    })
    const bundleData = await data.json()
    setBundle(bundleData)
  }
  useEffect(() => { 
    // set default island to masbate 
    if(!islandQuery) setIslandParams({ island: 'masbate'})
    fetchCategories()
  }, [])

  const closePlaceModal = () => {
    setPlaceModal(false)
  }

  const openPlaceModal = () => {
    setPlaceModal(true)
  }

  const openIslandModal = () => {
    setIslandSelectorVisibility(true)
  }

  const closeIslandModal = () => {
    setIslandSelectorVisibility(false)
  }


  return ( 
    <>
      {bundle ? 
        <div className="flex flex-col gap-3 mx-auto w-full max-w-7xl p-10 items-start h-screen">
          <Display size="xxl">
            Where are you
            going today?
          </Display>
          <Muted className='text-left hidden lg:block' size="lg">
            Pick your island, then a place. We show the best ride, the fare and where to board.
          </Muted>
          <ModalContext value={{openPlaceModal: openPlaceModal, placeModal: placeModal, closePlaceModal: closePlaceModal}}>
          {(placeModal && currentSelectedPlace) && <Modal closePlaceModal={closePlaceModal}><PlaceModalContent currentSelectedPlace={currentSelectedPlace} /></Modal> }
          {/* One column on phones, two side by side from lg. `min-h-dvh` rather
              than `h-screen` so mobile browser chrome doesn't crop the page. */}
          {<DynamicIsland openIslandModal={openIslandModal} places={bundle.places} setCurrentSelectedPlace={setCurrentSelectedPlace} currentSelectedPlace={currentSelectedPlace} />}
          {/* island switch (modal) */}
          {(islandSelectorVisibility) && <Modal closePlaceModal={closeIslandModal}><IslandSelector bundle={bundle} /></Modal>}
        </ModalContext>
        </div>
 
    : <>Something went wrong</> }
    </>
  )
}

export default App
