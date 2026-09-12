import { type IslandItem, type PlaceItem } from "../../App"
import { IslandButton } from "./IslandButton"

type IslandProps = {
  islands: IslandItem[] | undefined
  places: PlaceItem[] | undefined
  handleSetIslandParams: (island: string) => void
}

export function Island({ islands, places, handleSetIslandParams }: IslandProps) {
  return (
    <div className="flex flex-col gap-3 sm:gap-4 lg:gap-5">
      {islands?.map((island) => (
        <IslandButton
          key={island.name}
          island={island}
          // The mock hard-coded "8 places" per island; count the bundle instead.
          placeCount={
            places?.filter(
              (place) => place.island?.toLocaleLowerCase() === island.name?.toLocaleLowerCase(),
            ).length ?? 0
          }
          handleSetIslandParams={handleSetIslandParams}
        />
      ))}
    </div>
  )
}
