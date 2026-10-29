import { ArrowRight, Clock } from "lucide-react"
import { Muted, Tag } from "../../ui"
import { type FareEstimateItem, type FareLegItem, type PlaceItem } from "../../App"
import { usePier } from "./Terminal"
import { ModeIcon } from "../../utilities"

/**
 * The way in, once the traveller is on the right island.
 *
 * Legs the traveller has already made are not here: a chain is joined at the
 * last point it reaches where they already stand, so a Ticao local looking at
 * a Ticao waterfall is not shown the fastcraft from Masbate City. Getting to
 * the island, when that is still needed, is <Crossing />.
 */
export default function FareLeg({ estimates, place }: { estimates: FareEstimateItem; place: PlaceItem | null }) {
  if (!estimates) return null

  if (estimates.local) {
    return (
      <Muted className="text-sm">
        You are already on {place?.island}. Nothing left to arrange
        {estimates.fees.length > 0 ? " but the gate." : "."}
      </Muted>
    )
  }

  return (
    <ol className="flex flex-col gap-3">
      {estimates.legs.map((leg, index) => (
        <li key={`${leg.id}-${index}`} className="flex gap-3">
          <span className="mt-0.5 text-sm font-medium text-ink-soft tabular-nums">{index + 1}</span>
          <Leg leg={leg} fallback={place?.name} />
        </li>
      ))}
    </ol>
  )
}

function Leg({ leg, fallback }: { leg: FareLegItem; fallback: string | undefined }) {
  // Six legs have no destination stop and always will: a provincial bus fare
  // is a distance band, a habal-habal goes wherever you point it, and an
  // island-hopping charter ends where it started. They still have to render.
  const destination = leg.to ?? fallback ?? "onward"
  const from = usePier(leg.from_stop_id)
  const to = usePier(leg.to_stop_id)

  return (
    <div className="flex-1">
      <div className="flex flex-wrap items-baseline gap-x-2 text-sm">
        {leg.from && (
          <>
            {from.trigger(leg.from)}
            <ArrowRight className="shrink-0 text-ink-soft" size={12} />
          </>
        )}
        {to.trigger(destination)}
        {leg.mode && <Tag className="gap-1">{ModeIcon(leg.mode)} {leg.mode}</Tag>}
      </div>

      <div className="mt-1 flex flex-wrap items-center gap-x-3">
        <Muted className="text-sm">{price(leg)}</Muted>
        {leg.duration_min != null && <Muted className="text-sm">{duration(leg.duration_min)}</Muted>}
        {leg.schedule_kind === "departures" && leg.departures.length > 0 && (
          <span className="inline-flex items-center gap-1 text-sm text-ink-soft">
            <Clock size={12} /> {leg.departures.join(" · ")}
          </span>
        )}
      </div>
    </div>
  )
}

function price(leg: FareLegItem) {
  const { amount_min_php: min, amount_max_php: max } = leg
  if (min == null) return "Fare not published"
  const figure = min === max ? `₱${min}` : `₱${min}–${max}`
  // per_boat and per_vehicle are charged once to the whole party, so the
  // number on screen is not what one person hands over.
  return leg.basis === "per_person" ? figure : `${figure} for the boat`
}

function duration(minutes: number) {
  if (minutes < 60) return `${minutes} min`
  const hours = Math.floor(minutes / 60)
  const rest = minutes % 60
  return rest ? `${hours}h ${rest}m` : `${hours}h`
}
