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
        "bg-surface rounded-card flex w-full cursor-pointer items-center gap-4 p-4 text-left transition-all sm:p-5",
        "hover:shadow-lg active:shadow-lg",
        // The border is on the row in both states - transparent when idle, so
        // selecting one doesn't nudge its text over by 2px.
        isCurrent ? "border-venice border-2 shadow-lg" : "border-2 border-transparent shadow",
      )}
    >
      <span className="min-w-0 flex-1">
        <span className="flex items-center gap-2">
          <span
            className={cn("h-2 w-2 shrink-0 rounded-full", isCurrent ? "bg-venice" : "bg-venice-muted")}
          />
          <Display as="span" className={cn(isCurrent && "text-venice")}>
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
