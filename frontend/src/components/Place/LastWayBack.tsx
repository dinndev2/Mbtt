import { useId, useState } from "react"
import { TriangleAlert, Clock, CircleHelp, Anchor, ChevronDown } from "lucide-react"
import { Panel, Muted, Label } from "../../ui"
import type { ReturnTripItem, ReturnHop } from "../../App"

/**
 * The last way home, shown before anything about getting there.
 *
 * People are not afraid of getting lost here, they are afraid of being
 * stranded, and that is decided by one number: the last boat, the last jeep,
 * the last van out of the terminal. It sits above the fare because it is the
 * fact that changes whether the trip happens at all.
 *
 * The four states below are deliberately not collapsed. "Nobody knows" is not
 * "no", and neither is "the boat waits for you" - one sends a traveller to ask
 * at the terminal, one tells them to relax, and showing either as the other is
 * how someone ends up sleeping on a pier.
 */
export default function LastWayBack({ trip }: { trip: ReturnTripItem }) {
  if (trip.overnight) return <Stranded trip={trip} />
  if (trip.same_day === false) return <NotInADay trip={trip} />
  if (trip.no_deadline) return <NoDeadline />
  if (trip.latest_start) return <Deadline trip={trip} />
  return <Unknown trip={trip} />
}

/** The only way back is tomorrow. Bugui Point is why this exists. */
function Stranded({ trip }: { trip: ReturnTripItem }) {
  const hop = trip.hops.find((h) => h.overnight)
  return (
    <Alert tone="warn" icon={TriangleAlert} heading="There is no way back today">
      {hop?.last_departure
        ? `The only public boat back leaves ${hop.board_at} at ${hop.last_departure} tomorrow morning. Going today means staying the night, or chartering.`
        : "The return is the next morning. Going today means staying the night, or chartering."}
    </Alert>
  )
}

function NotInADay({ trip }: { trip: ReturnTripItem }) {
  return (
    <Alert tone="warn" icon={TriangleAlert} heading="Not a day trip">
      {trip.earliest_arrival && trip.latest_start
        ? `The earliest you can arrive is ${trip.earliest_arrival}, and you would have to start back by ${trip.latest_start}. Plan an overnight.`
        : "You cannot reach this and get home the same day. Plan an overnight."}
      {trip.binding && <Binding hop={trip.binding} />}
    </Alert>
  )
}

/** You hired the boat. It waits. */
function NoDeadline() {
  return (
    <Alert tone="calm" icon={Anchor} heading="No last trip to catch">
      You charter the boat for the trip, so it waits and brings you back. Agree the return
      time with the boatman before you set off.
    </Alert>
  )
}

/** The headline case: one number the traveller has to beat. */
function Deadline({ trip }: { trip: ReturnTripItem }) {
  return (
    <Alert tone="clock" icon={Clock} heading={`Start back by ${trip.latest_start}`}>
      {trip.time_there_min != null && trip.earliest_arrival && (
        <>
          Arrive from {trip.earliest_arrival}, which gives you{" "}
          <b className="font-medium">{hours(trip.time_there_min)}</b> there.{" "}
        </>
      )}
      {trip.binding && <Binding hop={trip.binding} />}
      {!trip.complete && <StillToAsk trip={trip} />}
    </Alert>
  )
}

/** Nobody knows. That is a finding, and it comes with the question to ask. */
function Unknown({ trip }: { trip: ReturnTripItem }) {
  return (
    <Alert tone="ask" icon={CircleHelp} heading="Nobody publishes the last trip back">
      No timetable covers the way home from here, so the safest plan is to ask when you
      arrive — the driver or the ticket booth will know.
      <StillToAsk trip={trip} />
    </Alert>
  )
}

/**
 * The hop that decides the day, named. "Back by 14:15" is a rule you can hold
 * in your head; "the 15:00 fastcraft off Lagundi is what decides it" is one
 * you can plan around, and can check when the boat turns out not to run.
 */
function Binding({ hop }: { hop: ReturnHop }) {
  return (
    <span className="mt-1 block">
      The <b className="font-medium">{hop.last_departure} {hop.mode?.toLowerCase()}</b> off{" "}
      {hop.board_at} is what decides this.
      {hop.basis === "collected" && " Asked on the ground, not read off a timetable."}
      {hop.basis === "timetable" && hop.confidence === "stale" && " That figure is years old — check it."}
    </span>
  )
}

/** The questions worth asking at the terminal, listed. */
function StillToAsk({ trip }: { trip: ReturnTripItem }) {
  const gaps = [...trip.unknown, ...trip.unmodelled]
  if (gaps.length === 0) return null

  return (
    <span className="mt-2 block">
      <Label className="text-xs">Still worth asking about</Label>
      <ul className="mt-1 flex flex-col gap-0.5">
        {gaps.map((hop) => (
          <li key={hop.leg_id} className="text-sm">
            The last {hop.mode?.toLowerCase() ?? "ride"}
            {hop.board_at ? ` out of ${hop.board_at}` : ""}
            {hop.to ? ` to ${hop.to}` : ""}.
          </li>
        ))}
      </ul>
    </span>
  )
}

// Warm sun for the two that could strand someone, so they never read as
// just another blue panel; ink tints for the rest.
const TONES = {
  warn:  "border border-sun bg-sun-pale",
  clock: "border border-venice/30 bg-venice-pale",
  calm:  "border border-divider bg-chip",
  ask:   "border border-divider bg-chip",
} as const

/**
 * Collapsed to its headline by default. The headline is the fact - "Start
 * back by 15:00", "There is no way back today" - so it is always on screen;
 * the reasoning behind it is one tap away instead of filling the sheet.
 */
function Alert({ tone, icon: Icon, heading, children }: {
  tone: keyof typeof TONES
  icon: typeof Clock
  heading: string
  children: React.ReactNode
}) {
  const [open, setOpen] = useState(false)
  const id = useId()

  return (
    <Panel className={`${TONES[tone]} flex flex-col`}>
      <button
        type="button"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        aria-controls={id}
        className="flex w-full cursor-pointer items-center gap-3 p-4 text-left"
      >
        <Icon className="shrink-0 text-venice" size={18} />
        <span className="flex-1 text-base font-semibold">{heading}</span>
        <span className="flex shrink-0 items-center gap-1 font-mono text-[11px] uppercase tracking-wider text-venice">
          {open ? "Less" : "Why"}
          <ChevronDown size={14} className={`transition-transform duration-200 ${open ? "rotate-180" : ""}`} />
        </span>
      </button>

      {/* grid-rows 0fr -> 1fr animates to the content's own height, which a
          max-height transition can only guess at. */}
      <div
        id={id}
        className={`grid transition-[grid-template-rows] duration-200 ease-out ${open ? "grid-rows-[1fr]" : "grid-rows-[0fr]"}`}
      >
        <div className="overflow-hidden" inert={!open}>
          <Muted as="div" className="block px-4 pb-4 pl-[3.125rem] text-sm">{children}</Muted>
        </div>
      </div>
    </Panel>
  )
}

function hours(minutes: number) {
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  if (h === 0) return `${m} minutes`
  return m ? `${h}h ${m}m` : `${h} hours`
}
