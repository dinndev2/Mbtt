import { useState, useEffect, useMemo, useContext, createContext } from 'react'
import { useSearchParams } from "react-router";
import { Island } from './components/Island/Island';
import DynamicIsland from './components/Island/DynamicIsland';
import IslandSelector from './components/Island/IslandSelector';
import { Display, Loader, Muted } from './ui';
import PlaceModalContent from './components/Place/PlaceModalContent';
import Modal from './components/Modal';
import "leaflet/dist/leaflet.css";

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

/**
 * gateway - an inter-island port. terminal - land transport.
 * jump_off - where a ride or boat is arranged. landing - where one drops you.
 */
export type StopRole = 'gateway' | 'terminal' | 'jump_off' | 'landing'

/**
 * A terminal, as something to preview before travelling to it.
 *
 * Most fields come from data/stops.csv, not the GTFS feed, which has nowhere
 * to record that Aroroy is not a RoRo port or that San Jacinto is daytime
 * navigation only - both decide whether a crossing is possible at all.
 * Thirteen of the thirty-four stops carry nothing but a role, and those nulls
 * are the honest record of what is published about a roadside arch.
 */
export type StopItem = {
  id: number
  gtfs_id: string
  name: string
  description: string | null
  /** Which island the terminal is on. Derived from its GTFS zone. */
  island: string | null
  role: StopRole | null
  latitude: number | null
  longitude: number | null
  /** PPA, LGU or private - who to ask when a timetable is wrong. */
  port_authority: string | null
  /** A daytime-only port has no evening crossing, however late the operator runs. */
  navigation: 'daytime' | 'day_and_night' | null
  serves: string[]
  operators: string[]
  facilities: string[]
  ticketing: string | null
  arrive_before_min: number | null
  notes: string | null
  /** Null where nothing about this stop was researched. */
  detail: { confidence: Confidence; as_of: string | null; source_url: string | null } | null
  /**
   * Photos from data/stop_images.csv. Only on `bundle.stops` - a stop nested
   * under a place or a transfer comes without them, so look the stop up with
   * useStop() rather than reading them off the nested copy.
   */
  images?: ImageItem[]
}

/** A photo of a place or a stop. Both come from the one images table. */
export type ImageItem = {
  url: string
  id: number
  license: string
  attribution: string | null
  source_page: string | null
  /** Must be displayed wherever the photo is - all images are CC BY-SA. */
  credit: string
  /** What it shows. Set on stop photos, where a poblacion shot is the town and not the pier. */
  caption: string | null
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

/** How a hop's times are expressed. `window` is a service that leaves when it
 *  fills - operating hours, never departures. Inventing departures for one is
 *  the failure that strands someone. */
export type ScheduleKind = 'departures' | 'window' | 'on_demand' | 'unknown'

export type FareLegItem = {
  id: string
  mode: string | null
  /**
   * Which way round the hop is being ridden. A leg is stored one way, but a
   * crossing *towards* Masbate City rides the same row backwards - `from`,
   * `to` and `departures` already account for it, so just render them.
   */
  direction: 'out' | 'back'
  from: string | null
  to: string | null
  from_island: string | null
  to_island: string | null
  /** Look these up in `bundle.stops` for the terminal detail. */
  from_stop_id: string | null
  to_stop_id: string | null
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
  /** HH:MM, earliest first, for the direction ridden. Empty unless `schedule_kind` is 'departures'. */
  departures: string[]
  service_start: string | null
  service_end: string | null
  headway_min: number | null
  schedule_kind: ScheduleKind
  schedule: LegSchedule | null
}

/**
 * The gap between where one crossing lands and where the next hop leaves.
 * Null when they are the same pier. `same_zone` is the difference between a
 * tricycle across town and a second journey: Masbate City Port to Rendezvous
 * Beach is the first, Masbate City Port to Mobo Port is the second.
 */
export type TransferItem = {
  arrive_at: StopItem | null
  depart_from: StopItem | null
  same_zone: boolean
  /** False when nothing in the dataset joins the two stops. */
  researched: boolean
  link: FareLegItem | null
}

/** One island boundary and every researched way across it, best first. */
export type ConnectionStep = {
  from_island: string
  to_island: string
  transfer: TransferItem | null
  crossings: FareLegItem[]
}

/**
 * How to get from the island the traveller is standing on to the island a
 * place's access chain starts from. Null when they are already there, which
 * is the common case. Deliberately NOT folded into the estimate's total:
 * getting to the island and getting to the place are two decisions, and one
 * unresearched crossing would otherwise drag a solid estimate to `unknown`.
 */
export type IslandConnectionItem = {
  from_island: string
  to_island: string
  reachable: boolean
  hops: number
  /** The crossings connect only on paper - render this, it is the difference
   *  between a journey and a pair of ferries. */
  has_unresearched_transfer: boolean
  steps: ConnectionStep[]
  arrival_transfer: TransferItem | null
}

/**
 * Where a last-trip figure came from, and therefore how much weight it bears.
 *
 * `collected` - somebody asked at the pier. The gold standard.
 * `timetable` - read off a published schedule that is trusted.
 * `round_trip` - chartered, so it waits. There is no last trip to miss.
 * `unknown`   - nobody knows. Never render this as a time.
 */
export type LastTripBasis = 'collected' | 'timetable' | 'round_trip' | 'unknown'

export type ReturnHop = {
  leg_id: string
  mode: string | null
  board_at: string | null
  board_stop_id: string | null
  to: string | null
  duration_min: number | null
  last_departure: string | null
  overnight: boolean
  basis: LastTripBasis
  confidence: Confidence
  source_url: string | null
  note: string | null
}

/**
 * The last moment you can leave and still get home today.
 *
 * This answers the question behind the fear of travelling here - not getting
 * lost, but getting stranded. Three states must never be collapsed into each
 * other:
 *
 *   same_day === false  you cannot get back today
 *   same_day === null   nobody knows, so go and ask at the terminal
 *   no_deadline         you chartered the boat and it waits
 */
export type ReturnTripItem = {
  /** HH:MM. Null when nothing on the way home runs to a timetable we trust. */
  latest_start: string | null
  latest_start_min: number | null
  earliest_arrival: string | null
  time_there_min: number | null
  /** null means "we cannot tell" and must never be rendered as "no". */
  same_day: boolean | null
  no_deadline: boolean
  /** The only way back is tomorrow morning. */
  overnight: boolean
  complete: boolean
  /** The single hop that decides the day. Worth naming, so it can be checked. */
  binding: ReturnHop | null
  /** Hops where nobody knows the last departure - the questions to ask. */
  unknown: ReturnHop[]
  /** Hops that cannot be ridden backwards at all: a distance band, a habal-habal. */
  unmodelled: ReturnHop[]
  hops: ReturnHop[]
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
  /** The island this way in assumes you are starting from. */
  origin_island: string | null
  /** You are already on the destination island and only the gate is left to pay. */
  local: boolean
  connection: IslandConnectionItem | null
  /** When the last way home goes, and which hop decides it. */
  return_trip: ReturnTripItem | null
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
  original: boolean
  name: string | undefined
  description: string | null
  latitude: number
  longitude: number
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
  images: ImageItem[]
  fare_estimates: FareEstimateItem[]
}

export type AdvisoryScope = 'province' | 'island' | 'municipality' | 'place' | 'route' | 'leg'
export type AdvisoryKind =
  | 'season' | 'tide' | 'last_departure' | 'cash' | 'permit' | 'fee'
  | 'safety' | 'connectivity' | 'access' | 'event' | 'disruption'
/** info: worth knowing. plan: changes what you book. warn: could strand you. */
export type AdvisorySeverity = 'info' | 'plan' | 'warn'

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
  /** Where the traveller is. Not a filter - see the bundles controller. */
  from_island: string | null
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
  /** The terminal directory, sent once and referenced by id from every leg. */
  stops: StopItem[]
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

/**
 * The terminal directory, keyed by gtfs_id. The bundle sends it once and legs
 * reference it by id, so anything rendering a pier can look up what is there
 * without the stop being nested into every leg it appears on.
 */
export const StopsContext = createContext<Map<string, StopItem>>(new Map())

export function useStop(gtfsId: string | null | undefined): StopItem | null {
  const stops = useContext(StopsContext)
  return gtfsId ? stops.get(gtfsId) ?? null : null
}
const API_URL = import.meta.env.VITE_API_URL;
const API = `${API_URL}/bundles`

function App() { 
  const [bundle, setBundle ] = useState<Bundle>()
  const [islandParams, setIslandParams] = useSearchParams();
  const [loading, setLoading] = useState(true)
  const [islandSelectorVisibility, setIslandSelectorVisibility] = useState(false)
  const savedId = islandParams.get('id')
  const [currentSelectedPlace, setCurrentSelectedPlace] = useState<PlaceItem | null>(null)
  // The island the traveller is on. `island` in the URL, because that is what
  // the selector, the search and the island buttons all read.
  const fromIsland = islandParams.get('island') || "masbate"
  const [placeModal, setPlaceModal] = useState(false)
  const stopsById = useMemo(
    () => new Map((bundle?.stops ?? []).map((stop) => [stop.gtfs_id, stop])),
    [bundle],
  )

  async function fetchBundle(from: string) {
    try {
      const url = new URL(API)
      url.searchParams.set('from', from)
      const data = await fetch(url, { method: 'GET' })
      setBundle(await data.json())
      if(data) {
        setLoading(false)
      }
    }
    catch(e) {
      console.log('something went wrong', e)
    }
  }

  useEffect(() => {
    if (islandParams.get('island')) return
    setIslandParams((params) => {
      params.set('island', fromIsland)
      return params
    }, { replace: true })
  }, [islandParams])

  useEffect(() => {
    fetchBundle(fromIsland)
  }, [fromIsland])

  useEffect(() => {
    if (!bundle) return

    const openId = savedId ?? currentSelectedPlace?.id
    if (!openId) return

    const place = bundle.places.find((place) => String(place.id) === String(openId))
    if (place) setCurrentSelectedPlace(place)
    if (savedId) openPlaceModal()
  }, [bundle])

  const closePlaceModal = () => {
    setPlaceModal(false)
    setIslandParams(
      (params) => {
      params.delete('id')
      return params
    })
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
      {bundle && !loading ? 
        <>
          <StopsContext value={stopsById}>
          <ModalContext value={{openPlaceModal: openPlaceModal, placeModal: placeModal, closePlaceModal: closePlaceModal}}>
            <div className="flex flex-col gap-4 mx-auto w-full max-w-7xl px-4 py-8 sm:p-10 items-start min-h-dvh">
              <Display as="h1" size="xxl">
                Where in Masbate
                are you <em>headed?</em>
              </Display>
              <Muted className='text-left hidden lg:block mb-4' size="lg">
                Masbate, Ticao or Burias - start from the island you're on. We show the boat or
                ride, what it costs, where to board, and the last trip back.
              </Muted>
                {<DynamicIsland openIslandModal={openIslandModal} places={bundle.places} setCurrentSelectedPlace={setCurrentSelectedPlace} currentSelectedPlace={currentSelectedPlace} />}
            </div>
          </ModalContext>
          {(islandSelectorVisibility) && <Modal closePlaceModal={closeIslandModal}><IslandSelector bundle={bundle} /></Modal>}
          {(placeModal && currentSelectedPlace) && <Modal closePlaceModal={closePlaceModal}><PlaceModalContent currentSelectedPlace={currentSelectedPlace} /></Modal> }
          </StopsContext>
        </>
      : <Loader fullscreen label="Charting the crossings" /> }
    </>
  )
}

export default App

