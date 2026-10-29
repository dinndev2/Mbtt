import { useId } from 'react'
import { ISLAND_PATHS, ISLAND_ORDER, ISLAND_VIEWBOX } from '../components/Island/island-paths'
import { cn } from './cn'
import { Label } from './Text'

// Ticao's west shore, Masbate City, then Burias's southern tip - the crossing
// the whole app is about, in the same coordinate space as the island paths.
const ROUTE = 'M250 208 C240 220 232 226 222 228 C196 214 168 176 152 150'
const ORIGIN = { x: 250, y: 208 }
const STOPOVER = { x: 222, y: 228 }
const DESTINATION = { x: 152, y: 150 }

// One loop is 3.2s: the boat sails for the first 80% and the rest is the
// pause before it sets off again. The wake and the boat's fade in index.css
// run on the same clock, so the three stay in step.
const DURATION = '3.2s'

/** A bangka - hull, cabin and outrigger - drawn around its own origin. */
function Bangka() {
  return (
    <g className="fill-venice">
      <path d="M-15 -2 Q0 9 15 -2 Z" />
      <rect x="-5" y="-9" width="10" height="7" rx="1.5" />
      <path d="M-18 6 H18" className="stroke-venice" strokeWidth="2" strokeLinecap="round" />
    </g>
  )
}

/**
 * The loading state. A bangka crosses from Ticao to Burias by way of Masbate
 * City and draws its wake behind it, so waiting reads as the journey the app
 * is about to show rather than as a grey placeholder.
 *
 * `fullscreen` centres it in the viewport for page-level loads; leave it off
 * inside a card or section.
 */
export function Loader({
  label = 'Charting the crossings',
  fullscreen,
  className,
}: {
  label?: string
  fullscreen?: boolean
  className?: string
}) {
  // Several loaders can be on screen at once, and <mpath> finds its route by id.
  const routeId = `route-${useId().replace(/:/g, '')}`

  return (
    <div
      role="status"
      aria-live="polite"
      className={cn(
        'flex flex-col items-center justify-center gap-4 py-10',
        fullscreen && 'min-h-dvh',
        className,
      )}
    >
      <svg viewBox={ISLAND_VIEWBOX} className="h-auto w-40 sm:w-48" aria-hidden="true">
        {ISLAND_ORDER.map((key) => (
          <path
            key={key}
            d={ISLAND_PATHS[key]}
            className="fill-venice-muted stroke-venice-muted"
            strokeWidth="11"
            strokeLinejoin="round"
          />
        ))}

        {/* The route still to sail, then the wake drawing over it. */}
        <path
          id={routeId}
          d={ROUTE}
          fill="none"
          className="stroke-venice/35"
          strokeWidth="3"
          strokeLinecap="round"
          strokeDasharray="1 8"
        />
        <path
          d={ROUTE}
          fill="none"
          pathLength={1}
          strokeDasharray="1"
          className="stroke-venice animate-route-wake"
          strokeWidth="3.5"
          strokeLinecap="round"
        />

        <circle cx={ORIGIN.x} cy={ORIGIN.y} r="5" className="fill-surface stroke-venice" strokeWidth="2.5" />
        <circle cx={STOPOVER.x} cy={STOPOVER.y} r="5" className="fill-surface stroke-venice" strokeWidth="2.5" />
        <circle
          cx={DESTINATION.x}
          cy={DESTINATION.y}
          r="7"
          className="fill-sun origin-center [transform-box:fill-box] motion-safe:animate-ping"
        />
        <circle cx={DESTINATION.x} cy={DESTINATION.y} r="6" className="fill-sun stroke-venice" strokeWidth="2.5" />

        {/* SMIL rather than CSS offset-path, which is unreliable on SVG
            children. Reduced motion swaps it for a boat already moored. */}
        <g className="animate-route-boat motion-reduce:hidden">
          <animateMotion
            dur={DURATION}
            repeatCount="indefinite"
            calcMode="spline"
            keyTimes="0;0.8;1"
            keyPoints="0;1;1"
            keySplines="0.45 0 0.55 1;0 0 1 1"
          >
            <mpath href={`#${routeId}`} />
          </animateMotion>
          <g transform="translate(0 -12)">
            <Bangka />
          </g>
        </g>
        <g className="motion-safe:hidden" transform={`translate(${DESTINATION.x} ${DESTINATION.y - 12})`}>
          <Bangka />
        </g>
      </svg>

      <Label>{label}</Label>
    </div>
  )
}

/**
 * Three dots bobbing in sequence like a boat's wake. For inline waits, such as
 * a button that is submitting, where the full crossing would not fit.
 */
export function LoaderDots({ className }: { className?: string }) {
  return (
    <span aria-hidden="true" className={cn('inline-flex items-center gap-1', className)}>
      {[0, 1, 2].map((i) => (
        <span
          key={i}
          className="size-1.5 rounded-full bg-current motion-safe:animate-wake-bob"
          style={{ animationDelay: `${i * 0.14}s` }}
        />
      ))}
    </span>
  )
}
