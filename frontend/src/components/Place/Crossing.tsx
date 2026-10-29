import { useState } from "react"
import { Ship, TriangleAlert, ArrowRight, Clock } from "lucide-react"
import { Panel, Muted, Label, Tag } from "../../ui"
import type { FareLegItem, IslandConnectionItem, TransferItem } from "../../App"
import { usePier } from "./Terminal"
import { ModeIcon, titleize } from "../../utilities"

/**
 * Getting to the island, shown above the way in rather than folded into it.
 *
 * Every access chain in the dataset is written from an origin it never states
 * - Masbate City for most places, Pasacao for the Burias circuit. This is the
 * part the chain leaves out: the traveller is on Ticao, the place is not, and
 * here is the boat and the pier it leaves from.
 *
 * It is kept out of the fare total on purpose. Getting to the island and
 * getting to the place are two decisions, and one unresearched crossing -
 * Mobo to Claveria has no published fare at all - would otherwise drag an
 * otherwise solid estimate down to "unknown".
 */
export default function Crossing({ connection }: { connection: IslandConnectionItem }) {
  const [expanded, setExpanded] = useState<number | null>(null)

  if (!connection.reachable) {
    return (
      <Panel className="flex items-start gap-3 border border-divider p-4">
        <TriangleAlert className="mt-0.5 shrink-0 text-ink-soft" size={16} />
        <div>
          <p className="text-sm font-medium">
            No researched way from {titleize(connection.from_island)} to {titleize(connection.to_island)}
          </p>
          <Muted className="text-sm">
            Nobody has published a crossing between these two. Travellers normally go out
            through mainland Bicol and back in.
          </Muted>
        </div>
      </Panel>
    )
  }

  return (
    <Panel tinted className="flex flex-col gap-3 border border-venice/30 p-4">
      <div className="flex items-center gap-2">
        <Ship className="text-venice" size={16} />
        <Label className="text-xs">
          {titleize(connection.from_island)} <ArrowRight className="inline" size={11} /> {titleize(connection.to_island)}
          {connection.hops > 1 && ` · ${connection.hops} crossings`}
        </Label>
      </div>

      {connection.steps.map((step, index) => {
        const [best, ...alternatives] = step.crossings
        const open = expanded === index

        return (
          <div key={`${step.from_island}-${step.to_island}`} className="flex flex-col gap-2">
            {/* The gap between the last landing and this departure comes first:
                it is what the traveller has to solve before this boat matters. */}
            {step.transfer && <Gap transfer={step.transfer} />}

            <Hop crossing={best} />

            {alternatives.length > 0 && (
              <>
                <button
                  type="button"
                  onClick={() => setExpanded(open ? null : index)}
                  className="self-start text-xs font-medium text-venice underline underline-offset-2"
                >
                  {open ? "Hide" : `${alternatives.length} other way${alternatives.length > 1 ? "s" : ""} across`}
                </button>
                {open && alternatives.map((crossing) => <Hop key={crossing.id} crossing={crossing} muted />)}
              </>
            )}
          </div>
        )
      })}

      {connection.arrival_transfer && <Gap transfer={connection.arrival_transfer} />}
    </Panel>
  )
}

/** One boat, in the direction it is actually being ridden. */
function Hop({ crossing, muted }: { crossing: FareLegItem; muted?: boolean }) {
  // The terminal is the thing a traveller cannot see from here and most needs
  // to know about: whether it takes vehicles, whether it sails after dark,
  // how early to turn up.
  const from = usePier(crossing.from_stop_id)
  const to = usePier(crossing.to_stop_id)

  return (
    <div className={muted ? "opacity-70" : undefined}>
      <div className="flex flex-wrap items-baseline gap-x-2 text-sm">
        {from.trigger(crossing.from)}
        <ArrowRight className="shrink-0 text-ink-soft" size={12} />
        {to.trigger(crossing.to)}
        {crossing.mode && <Tag className="gap-1">{ModeIcon(crossing.mode)} {crossing.mode}</Tag>}
      </div>

      <div className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1">
        <Muted className="text-sm">{price(crossing)}</Muted>
        {crossing.duration_min && <Muted className="text-sm">{duration(crossing.duration_min)}</Muted>}
        <Times crossing={crossing} />
      </div>

      {/* A few crossings are now `published` - MARINA's nautical highway
          matrix is a regulator, not an aggregator. Most are still somebody's
          travel blog, so say so where the number is weakest. */}
      {(crossing.confidence === "stale" || crossing.confidence === "unknown") && (
        <Muted className="mt-1 block text-xs">
          {crossing.confidence === "stale"
            ? `Fare last confirmed ${crossing.valid_as_of ?? "years ago"} - check at the booth.`
            : "No published fare for this crossing."}
        </Muted>
      )}
    </div>
  )
}

/**
 * Times, or honestly nothing. A service that leaves when it fills has
 * operating hours and no timetable, and printing invented departures for one
 * is the failure that strands someone.
 */
function Times({ crossing }: { crossing: FareLegItem }) {
  if (crossing.schedule_kind === "departures" && crossing.departures.length > 0) {
    return (
      <span className="inline-flex items-center gap-1 text-sm text-ink-soft">
        <Clock size={12} /> {crossing.departures.join(" · ")}
      </span>
    )
  }

  if (crossing.service_start && crossing.service_end) {
    return (
      <span className="inline-flex items-center gap-1 text-sm text-ink-soft">
        <Clock size={12} /> {crossing.service_start}–{crossing.service_end}, leaves when full
      </span>
    )
  }

  return <Muted className="text-sm">No published times</Muted>
}

/**
 * Where this boat leaves from is not where the last one landed.
 *
 * Within one municipality that is a tricycle ride and one line of text. Across
 * municipalities it is a second journey, and staying quiet about it would turn
 * two solid ferries into a route that does not exist - which is exactly how
 * someone ends up stranded at the wrong pier.
 */
function Gap({ transfer }: { transfer: TransferItem }) {
  const serious = !transfer.same_zone && !transfer.researched

  return (
    <div className="flex items-start gap-2">
      {serious && <TriangleAlert className="mt-0.5 shrink-0 text-ink-soft" size={14} />}
      <Muted className="text-sm">
        {serious ? (
          <>
            You land at <b className="font-medium">{transfer.arrive_at?.name}</b> but this leaves from{" "}
            <b className="font-medium">{transfer.depart_from?.name}</b>, in another town. Nothing here
            covers that hop - allow for it, and probably a night.
          </>
        ) : (
          <>
            Short hop from {transfer.arrive_at?.name} to {transfer.depart_from?.name}
            {transfer.link?.mode ? ` by ${transfer.link.mode.toLowerCase()}` : " - tricycle"}.
          </>
        )}
      </Muted>
    </div>
  )
}

function price(crossing: FareLegItem) {
  const { amount_min_php: min, amount_max_php: max } = crossing
  if (min == null) return "Fare not published"
  return min === max ? `₱${min}` : `₱${min}–${max}`
}

function duration(minutes: number) {
  if (minutes < 60) return `${minutes} min`
  const hours = Math.floor(minutes / 60)
  const rest = minutes % 60
  return rest ? `${hours}h ${rest}m` : `${hours}h`
}
