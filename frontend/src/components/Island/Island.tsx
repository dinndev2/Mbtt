
import { type IslandItem } from "../../App" 
import { IslandButton } from "./IslandButton"

export function Island({ handleSetIslandParams, islands}: { islands: IslandItem[] | undefined, handleSetIslandParams: (island: string) => void }, ){
 
  return <div className="flex flex-col gap-3 sm:gap-4 lg:gap-5">
    {islands && islands.map((island) => {
      return <IslandButton key={island.name} handleSetIslandParams={handleSetIslandParams} island={island}  />
    })}
</div>
}