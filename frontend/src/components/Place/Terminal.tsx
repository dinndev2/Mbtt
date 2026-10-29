import { useContext } from "react"
import { Ship, Bus, Anchor, MapPin, TriangleAlert, Clock, ArrowLeft, ChevronRight, ImageOff } from "lucide-react"
import { Chip, Display, Label, Muted } from "../../ui"
import type { StopItem, StopRole } from "../../App"
import { useStop } from "../../App"
import { titleize } from "../../utilities"
import { StopNavContext } from "./stop-nav"

const ICON: Record<StopRole, typeof Ship> = {
  gateway: Ship, terminal: Bus, jump_off: MapPin, landing: Anchor,
}

const ROLE: Record<StopRole, string> = {
  gateway: "Inter-island port",
  terminal: "Land terminal",
  jump_off: "Jump-off point",
  landing: "Boat landing",
}

/**
 * What is actually at a pier, for someone deciding whether to travel to it -
 * a page of its own inside the place sheet, so it has room for photos and
 * every fact without pushing the way in down the screen.
 *
 * Thirteen of the thirty-four stops have nothing here but a role - a roadside
 * arch and a village path have no published detail and this says so rather
 * than filling the space. The two facts worth shouting are the ones that
 * decide whether a crossing happens at all: a daytime-only port has no evening
 * sailing however late the operator's timetable runs, and a port that cannot
 * take a RoRo cannot take your vehicle.
 */
export default function TerminalPage({ stop, backLabel, onBack }: {
  stop: StopItem
  /** The place this was opened from, named on the way back. */
  backLabel: string
  onBack: () => void
}) {
  const Icon = (stop.role && ICON[stop.role]) || MapPin
  const daytimeOnly = stop.navigation === "daytime"
  const noRoRo = stop.facilities.some((f) => /not viable for RoRo/i.test(f))

  return (
    <div className="flex flex-col">
      {/* Zero height, so the button floats over the photo the way the close
          button does, and stays put while the page scrolls. */}
      <div className="sticky top-0 z-30 h-0">
        <button
          type="button"
          onClick={onBack}
          aria-label={`Back to ${backLabel}`}
          className="absolute left-4 top-4 flex size-11 cursor-pointer items-center justify-center rounded-full border-[1.5px] border-venice bg-surface text-venice transition-colors hover:bg-venice hover:text-surface md:left-4 md:top-4"
        >
          <ArrowLeft size={20} />
        </button>
      </div>

      <Photos stop={stop} icon={Icon} />

      <div className="rounded-t-card bg-surface px-5 pt-5 -translate-y-7 md:translate-y-0">
        <span className="flex flex-wrap gap-2">
          {stop.role && (
            <Chip className="inline-flex items-center gap-1.5">
              <Icon size={14} aria-hidden /> {ROLE[stop.role]}
            </Chip>
          )}
          {stop.island && <Chip active>{titleize(stop.island)}</Chip>}
        </span>
        <Display size="xl" className="mt-4 text-4xl md:text-5xl">{stop.name}</Display>
        {stop.description && <Muted className="mt-2">{stop.description}</Muted>}
      </div>

      <div className="flex flex-col gap-4 px-5 pb-6 -mt-3 md:mt-4">
        {(daytimeOnly || noRoRo) && (
          <div className="flex items-start gap-3 rounded-panel border border-sun bg-sun-pale p-4">
            <TriangleAlert className="mt-0.5 shrink-0 text-venice" size={18} />
            <div className="flex flex-col gap-1">
              {daytimeOnly && (
                <p className="text-sm">
                  <b className="font-semibold">Daylight crossings only.</b> There is no evening sailing here,
                  whatever the timetable says.
                </p>
              )}
              {noRoRo && (
                <p className="text-sm">
                  <b className="font-semibold">Not a RoRo port.</b> No vehicles - foot passengers only.
                </p>
              )}
            </div>
          </div>
        )}

        {stop.arrive_before_min != null && (
          <div className="flex items-center gap-3 rounded-panel border border-venice/30 bg-venice-pale p-4">
            <Clock className="shrink-0 text-venice" size={18} />
            <p className="text-sm">
              Be there <b className="font-semibold">{stop.arrive_before_min} minutes</b> before departure.
            </p>
          </div>
        )}

        {stop.notes && <Muted className="text-sm">{stop.notes}</Muted>}

        <dl className="flex flex-col">
          {stop.serves.length > 0 && <Fact label="Sails to">{stop.serves.join(" · ")}</Fact>}
          {stop.operators.length > 0 && <Fact label="Operators">{stop.operators.join(" · ")}</Fact>}
          {stop.facilities.length > 0 && <Fact label="Facilities">{stop.facilities.join(" · ")}</Fact>}
          {stop.ticketing && <Fact label="Tickets">{stop.ticketing}</Fact>}
          {stop.port_authority && <Fact label="Run by">{stop.port_authority}</Fact>}
        </dl>

        {/* No detail at all is the common case for a jump-off, and pretending
            otherwise would be worse than the blank. */}
        {!stop.detail && (
          <Muted className="text-sm italic">
            Nothing published about this stop beyond where it is. Ask locally - drivers and
            boatmen know it by name.
          </Muted>
        )}

        {stop.detail && (
          <p className="font-mono text-[11px] uppercase tracking-wider text-ink-soft">
            {stop.detail.confidence}
            {stop.detail.as_of && ` · checked ${stop.detail.as_of}`}
            {stop.detail.source_url && (
              <>
                {" · "}
                <a className="text-venice underline underline-offset-2" href={stop.detail.source_url}
                   target="_blank" rel="noreferrer">source</a>
              </>
            )}
          </p>
        )}

        <button
          type="button"
          onClick={onBack}
          className="mt-2 inline-flex cursor-pointer items-center gap-2 self-start text-sm font-semibold text-venice underline decoration-venice/30 underline-offset-4 hover:decoration-venice"
        >
          <ArrowLeft size={14} /> Back to {backLabel}
        </button>
      </div>
    </div>
  )
}

/**
 * Photos where Commons has one, and a deliberate blank where it does not -
 * which is most stops. The credit is shown on every photo because it is a
 * condition of the licence, and the caption because a poblacion photo shows
 * the town, not the pier.
 */
function Photos({ stop, icon: Icon }: { stop: StopItem; icon: typeof Ship }) {
  const images = stop.images ?? []

  if (images.length === 0) {
    return (
      <div className="grid h-56 place-items-center bg-[repeating-linear-gradient(-45deg,#2231b833_0_1.4px,transparent_1.4px_9px)] md:m-1 md:h-72 md:rounded-card">
        <span className="flex flex-col items-center gap-3">
          <span className="grid size-16 place-items-center rounded-full border-[1.5px] border-venice bg-surface text-venice">
            <Icon size={26} />
          </span>
          <span className="flex items-center gap-1.5 bg-surface px-2.5 py-1 font-mono text-[11px] uppercase tracking-wider text-ink-soft">
            <ImageOff size={12} /> No open-licence photo yet
          </span>
        </span>
      </div>
    )
  }

  return (
    <ul className="flex w-full snap-x snap-mandatory overflow-x-auto scrollbar-none md:gap-2 md:p-1">
      {images.map((image) => (
        <li key={image.url} className="relative w-full shrink-0 snap-center md:w-1/2">
          <img
            src={image.url}
            alt={image.caption ?? stop.name}
            className="h-72 w-full object-cover md:h-80 md:rounded-card"
          />
          <span className="absolute inset-x-0 bottom-0 flex flex-col gap-0.5 bg-linear-to-t from-venice-deep/80 to-transparent px-4 pt-8 pb-9 text-surface md:rounded-b-card md:pb-3">
            {image.caption && <span className="text-sm leading-snug">{image.caption}</span>}
            <a
              href={image.source_page ?? undefined}
              target="_blank"
              rel="noreferrer"
              className="font-mono text-[10px] opacity-80 hover:underline"
            >
              {image.credit}
            </a>
          </span>
        </li>
      ))}
    </ul>
  )
}

function Fact({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1 border-t border-divider py-3">
      <dt><Label>{label}</Label></dt>
      <dd className="text-sm">{children}</dd>
    </div>
  )
}

/**
 * A pier name that opens its terminal page.
 *
 * Plain text where the stop is unknown to the directory - a control that
 * opens nothing is worse than no control. The chevron is what says it goes
 * somewhere, rather than expanding in place.
 */
export function usePier(gtfsId: string | null | undefined) {
  const stop = useStop(gtfsId)
  const openStop = useContext(StopNavContext)

  return {
    stop,
    trigger: (label: string | null) =>
      stop ? (
        <button
          type="button"
          onClick={() => openStop(stop.gtfs_id)}
          className="inline-flex cursor-pointer items-center gap-0.5 font-semibold text-venice underline decoration-venice/30 underline-offset-4 transition-colors hover:decoration-venice"
        >
          {label}
          <ChevronRight size={14} aria-hidden className="shrink-0" />
        </button>
      ) : (
        <span className="font-medium">{label}</span>
      ),
  }
}
