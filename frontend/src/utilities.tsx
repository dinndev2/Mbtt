import { WavesHorizontal, Building, Leaf, Ship, Sailboat, Bus, Bike, Van, CarTaxiFront, Route } from "lucide-react"

export function titleize(str: string | undefined ) {
  if(str == undefined || str == "") return "Text"
  return str.replace(/\b\w/g, char => char.toUpperCase())
}

// Each category's icon and solid fill - see the category tokens in index.css.
// Cream text on every fill clears 4.5:1, so the label stays readable at 11px.
const CATEGORIES: Record<string, { icon: typeof Leaf; fill: string }> = {
  Sea:    { icon: WavesHorizontal, fill: "bg-sea" },
  City:   { icon: Building,        fill: "bg-city" },
  Nature: { icon: Leaf,            fill: "bg-nature" },
}

/** The icon alone, in whatever colour its parent sets. */
export function CategoryLogo(str: string, size=13) {
  const Icon = CATEGORIES[str]?.icon ?? WavesHorizontal
  return <Icon size={size} aria-hidden className="shrink-0" />
}

/**
 * A category as a solid pill in its own colour, so sea, nature and city
 * places can be told apart down a list before reading a word. A category
 * without a colour yet falls back to the brand blue.
 */
export function CategoryTag({ name }: { name: string }) {
  const fill = CATEGORIES[name]?.fill ?? "bg-venice"
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-pill px-2.5 py-0.5 font-mono text-[11px] font-medium tracking-wide text-surface ${fill}`}>
      {CategoryLogo(name, 11)} {name}
    </span>
  )
}
/** ₱1,080 or ₱1,080–1,550. Null when there is nothing published to show. */
export function peso(min: number | null, max: number | null) {
  if (min == null) return null
  const fmt = (n: number) => `₱${n.toLocaleString("en-PH")}`
  return max == null || max === min ? fmt(min) : `${fmt(min)}–${max.toLocaleString("en-PH")}`
}

/**
 * The headline price for a way in, worded honestly. An incomplete estimate
 * has a leg nobody has priced, so its total is a floor - "from", never a
 * price. Null when nothing at all is priced.
 */
export function estimateFare(estimate: { min_php: number | null; max_php: number | null; complete: boolean } | undefined) {
  if (!estimate) return null
  const figure = peso(estimate.min_php, estimate.max_php)
  if (figure == null) return null
  if (estimate.min_php === 0 && estimate.max_php === 0 && estimate.complete) return "Free"
  return estimate.complete ? figure : `from ${figure}`
}

export function duration(minutes: number) {
  if (minutes < 60) return `${minutes} min`
  const hours = Math.floor(minutes / 60)
  const rest = minutes % 60
  return rest ? `${hours}h ${rest}m` : `${hours}h`
}

/**
 * An icon for a leg's vehicle. Matched loosely because the name comes from the
 * vihicles table, where a ferry may be a "RoRo" or a "Fastcraft" and a boat a
 * "Bangka". A tricycle gets the taxi, since that is the job it does here.
 */
export function ModeIcon(mode: string | null | undefined, size = 12) {
  const name = mode?.toLowerCase() ?? ""
  const props = { size, "aria-hidden": true, className: "shrink-0" }
  if (/ferry|roro|fastcraft|ship/.test(name)) return <Ship {...props} />
  if (/boat|bangka|banca/.test(name)) return <Sailboat {...props} />
  if (/bus|jeep/.test(name)) return <Bus {...props} />
  if (/van|uv/.test(name)) return <Van {...props} />
  if (/tricycle|trike/.test(name)) return <CarTaxiFront {...props} />
  if (/motor|habal/.test(name)) return <Bike {...props} />
  return <Route {...props} />
}

type TimedEstimate = {
  local: boolean
  legs: { duration_min: number | null }[]
  connection: {
    reachable: boolean
    steps: { crossings: { duration_min: number | null }[] }[]
  } | null
}

/**
 * Time on the move from the island the traveller picked, or null when there
 * is nothing to add up.
 *
 * The API's `duration_min` covers only the chain on the place's own island -
 * the crossing over is kept out of it on purpose, like it is kept out of the
 * fare - so the best crossing for each hop is added back here. Transfers
 * between piers have no duration anywhere, and some legs have none either, so
 * any gap makes the total a floor: `partial`, shown as "from".
 */
export function tripTime(estimate: TimedEstimate | undefined) {
  if (!estimate || (estimate.connection && !estimate.connection.reachable)) return null

  const parts = [
    ...estimate.legs.map((leg) => leg.duration_min),
    ...(estimate.connection?.steps ?? []).map((step) => step.crossings[0]?.duration_min ?? null),
  ]
  const known = parts.filter((minutes): minutes is number => minutes != null)
  if (known.length === 0) return null

  return { minutes: known.reduce((sum, minutes) => sum + minutes, 0), partial: known.length < parts.length }
}
