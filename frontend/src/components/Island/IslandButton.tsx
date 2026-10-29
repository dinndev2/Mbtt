import { ChevronRight } from "lucide-react"
import { useSearchParams } from "react-router"
import { cn, Display, Muted, Tag } from "../../ui"
import { type IslandItem } from "../../App"

type IslandButtonProps = {
  island: IslandItem
  /** Counted from the bundle, so the chip can't drift from what the list shows. */
  placeCount: number
  handleSetIslandParams: (island: string) => void
}

export function IslandButton({ island, placeCount, handleSetIslandParams }: IslandButtonProps) {
  const [islandParams] = useSearchParams()
  const isCurrent = islandParams.get("island") === island.name?.toLocaleLowerCase()

  /* A real button, so it is reachable by keyboard and reads as a control to a
     screen reader on a phone. Height grows with the blurb instead of clipping
     it at narrow widths; hover is paired with active, which is all a touch
     device gets. Everything inside is a span - a button may only hold phrasing
     content, and a heading in here would land in the screen reader's outline. */
  return (
    <button
      type="button"
      aria-pressed={isCurrent}
      onClick={() => handleSetIslandParams(island.name)}
      className={cn(
        "rounded-card flex w-full cursor-pointer items-center gap-4 p-4 text-left transition-colors sm:p-5",
        // Same border width in both states, so selecting one doesn't nudge
        // its text over.
        isCurrent
          ? "border-[1.5px] border-venice bg-venice-pale"
          : "border-[1.5px] border-divider bg-surface hover:border-venice active:border-venice",
      )}
    >
      <span className="min-w-0 flex-1">
        <span className="flex items-center gap-2">
          <span
            className={cn("h-2.5 w-2.5 shrink-0 rounded-full", isCurrent ? "bg-sun" : "border-[1.5px] border-venice/40")}
          />
          <Display as="span">
            {island.name}
          </Display>
        </span>

        <Muted as="span" className="mt-1 block">
          {island.description}
        </Muted>

        {/* Wraps, because a second chip belongs here once crossings are in the
            bundle - the mock showed ferry time alongside the count. */}
        <span className="mt-2 flex flex-wrap gap-1.5">
          <Tag tinted={isCurrent}>
            {placeCount} {placeCount === 1 ? "place" : "places"}
          </Tag>
        </span>
      </span>

      <ChevronRight className="text-venice shrink-0" size={20} strokeWidth={2.4} aria-hidden />
    </button>
  )
}
