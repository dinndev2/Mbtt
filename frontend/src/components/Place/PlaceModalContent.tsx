import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import Map from './Map'
import { ChevronDown, Clock } from 'lucide-react'
import { type FareEstimateItem, type FareFeeItem, type PlaceItem, useStop } from '../../App'
import { Chip, Display, Muted, Label, Fare } from '../../ui'
import { duration, estimateFare, peso } from '../../utilities'
import FareLeg from './FareLeg'
import Crossing from './Crossing'
import LastWayBack from './LastWayBack'
import ImageSlider from './ImageSlider'
import TerminalPage from './Terminal'
import { StopNavContext } from './stop-nav'


export default function PlaceModalContent({currentSelectedPlace}: { currentSelectedPlace: PlaceItem}) {
  const { municipality } = currentSelectedPlace
  // "A" first - the options are alternative routes in, in preference order.
  const estimate = currentSelectedPlace.fare_estimates[0]

  // A terminal opens as a second page in the same sheet rather than a second
  // modal, so the fare bar and the way back to the place stay where they are.
  const [stopId, setStopId] = useState<string | null>(null)
  const [direction, setDirection] = useState<'forward' | 'back'>('forward')
  const stop = useStop(stopId)
  const rootRef = useRef<HTMLDivElement>(null)
  const placeScroll = useRef(0)
  const pendingBreakdown = useRef(false)

  // The sheet's scroll container is the Modal's, one level up.
  const scroller = () => rootRef.current?.parentElement

  const openStop = (gtfsId: string) => {
    placeScroll.current = scroller()?.scrollTop ?? 0
    setDirection('forward')
    setStopId(gtfsId)
  }

  const back = () => {
    setDirection('back')
    setStopId(null)
  }

  // An island switch re-resolves the place; whatever stop was open belonged
  // to the old route.
  useEffect(() => setStopId(null), [currentSelectedPlace.id])

  // A new page starts at its top; going back returns to where the traveller
  // was reading, which is usually the leg they tapped.
  useLayoutEffect(() => {
    const el = scroller()
    if (!el) return
    if (pendingBreakdown.current && !stopId) {
      pendingBreakdown.current = false
      document.getElementById('fare-breakdown')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
      return
    }
    el.scrollTop = stopId ? 0 : placeScroll.current
  }, [stopId])

  const showBreakdown = () => {
    if (stopId) {
      pendingBreakdown.current = true
      back()
      return
    }
    document.getElementById('fare-breakdown')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }

  return <StopNavContext value={openStop}>
    <div ref={rootRef} className='flex flex-1 flex-col'>
      {/* Keyed so each page change replays the slide. */}
      <div key={stopId ?? 'place'} className={direction === 'forward' ? 'animate-page-forward' : 'animate-page-back'}>
        {stop
          ? <TerminalPage stop={stop} backLabel={currentSelectedPlace.name ?? 'place'} onBack={back} />
          : <>
            <ImageSlider place={currentSelectedPlace} />
            {/* Only lifted over a photo; with none it would tuck the chips
                under the top of the sheet. */}
            <div className={`rounded-t-card px-5 md:pt-5 md:translate-y-0 bg-surface ${currentSelectedPlace.images.length ? 'pt-5 -translate-y-7' : 'pt-12'}`}>
              <span className="flex flex-wrap gap-2">
                <Chip className='inline'>{municipality}</Chip>
                <Chip active className='inline'>{currentSelectedPlace.island} Island</Chip>
              </span>
              <Display size="xl" className='mt-4 text-4xl md:text-5xl'>{currentSelectedPlace.name}</Display>
              <Muted className='mt-2'>{currentSelectedPlace.description}</Muted>
            </div>

            {estimate && <div className="flex flex-col gap-3 px-5 pb-6 -mt-3 md:mt-4">
              {/* Before anything about getting there. People are not afraid of
                  getting lost here, they are afraid of being stranded, and this is
                  the number that decides it. */}
              {estimate.return_trip && <LastWayBack trip={estimate.return_trip} />}

              {/* Getting to the island comes before getting to the place, and is
                  shown as its own block rather than folded into the total - see
                  Crossing. Null whenever the traveller is already there. */}
              {estimate.connection && <Crossing connection={estimate.connection} />}

              <div id="fare-breakdown" className="flex scroll-mt-4 flex-col gap-2">
                <Label>
                  {estimate.connection ? `Then, on ${estimate.connection.to_island}` : 'Getting there'}
                </Label>
                <FareLeg place={currentSelectedPlace} estimates={estimate} />
              </div>

              {estimate.fees.length > 0 && <Fees fees={estimate.fees} />}
            </div>}
          </>}
      </div>
      {(currentSelectedPlace) && <Map currentSelectedPlace={currentSelectedPlace} />}
      <FareBar estimate={estimate} onBreakdown={showBreakdown} />
    </div>
  </StopNavContext>
}

/**
 * What the trip costs, pinned to the bottom of the sheet so it never scrolls
 * out of view. It is the number people open a place to find, and it used to
 * sit below every leg and crossing.
 *
 * Always rendered, even with nothing to show: an empty bar saying the fare is
 * not researched is more honest than the price quietly not being there.
 */
function FareBar({ estimate, onBreakdown }: { estimate: FareEstimateItem | undefined; onBreakdown: () => void }) {
  const fare = estimateFare(estimate)

  return (
    <div className="sticky bottom-0 z-10 mt-auto border-t border-divider bg-surface px-5 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
      {fare && estimate ? (
        <button
          type="button"
          onClick={onBreakdown}
          className="group flex w-full cursor-pointer items-center justify-between gap-4 text-left"
        >
          <span className="flex min-w-0 flex-col gap-1">
            <Label weight='font-bold'>
              {estimate.complete ? 'Trip fare' : 'Trip fare, so far'} · {estimate.pax === 1 ? 'per person' : `each, party of ${estimate.pax}`}
            </Label>
            <span className="flex flex-wrap items-baseline gap-x-3">
              <Fare weight='font-bold' highlight>{fare}</Fare>
              {estimate.duration_min != null && (
                <span className="inline-flex items-center gap-1 text-sm text-ink-soft">
                  <Clock size={13} /> {duration(estimate.duration_min)}
                </span>
              )}
            </span>
            {/* The caveats that change what a traveller should carry. */}
            {(!estimate.complete || estimate.negotiable || estimate.group_sensitive) && (
              <Muted as="span" className="text-xs">
                {[
                  !estimate.complete && `${estimate.unpriced_legs.length || 'Some'} leg${estimate.unpriced_legs.length === 1 ? '' : 's'} unpriced`,
                  estimate.negotiable && 'part of it is haggled',
                  estimate.group_sensitive && 'cheaper in a group',
                ].filter(Boolean).join(' · ')}
              </Muted>
            )}
          </span>
          <span className="flex shrink-0 items-center gap-1 rounded-pill border-[1.5px] border-venice px-3 py-1.5 text-xs font-semibold text-venice transition-colors group-hover:bg-venice group-hover:text-surface">
            Breakdown <ChevronDown size={14} />
          </span>
        </button>
      ) : (
        <div className="flex flex-col gap-1">
          <Label>Trip fare</Label>
          <Muted className="text-sm">
            Nobody has published a fare for this trip yet. Ask the driver or boatman before you set off.
          </Muted>
        </div>
      )}
    </div>
  )
}

/**
 * Gate, environmental and landing fees. FareEstimate sums them into the trip
 * fare, so they are listed as part of it rather than as an extra.
 */
function Fees({ fees }: { fees: FareFeeItem[] }) {
  return (
    <div className="flex flex-col gap-2">
      <Label>Fees · in the trip fare</Label>
      <ul className="flex flex-col gap-1">
        {fees.map((fee) => (
          <li key={fee.label} className="flex items-baseline justify-between gap-3 text-sm">
            <span>
              {fee.label}
              {!fee.required && <span className="text-ink-soft"> · optional</span>}
            </span>
            <span className="shrink-0 tabular-nums text-ink-soft">
              {peso(fee.amount_min_php, fee.amount_max_php) ?? 'not published'}
              {fee.basis !== 'per_person' && ` ${fee.basis === 'per_boat' ? 'per boat' : 'per vehicle'}`}
            </span>
          </li>
        ))}
      </ul>
      
    </div>
  )
}
