import { Muted, Display } from "../../ui";
import {type IslandItem} from '../../App'
import { useSearchParams } from "react-router";


export function IslandButton({island, handleSetIslandParams}: {island: IslandItem, handleSetIslandParams: (island: string) => void}) {
  const [islandParams, _] = useSearchParams();
  const islandQuery = islandParams.get('island')
  const isCurrent = islandQuery == island.name?.toLocaleLowerCase()
  return <>
    {/* A real button, so it is reachable by keyboard and reads as a control to
        a screen reader on a phone. Height grows with the blurb instead of
        clipping it at narrow widths; hover is paired with active, which is all
        a touch device gets. */}
    <button
      type="button"
      aria-pressed={isCurrent}
      className={`hover:text-venice ${isCurrent ? "border-venice border-2" : ""} w-full flex cursor-pointer flex-col gap-1 p-4 sm:p-5 text-left bg-white transition-all hover:shadow-lg active:shadow-lg rounded-3xl min-h-28 sm:min-h-32 ${isCurrent ? 'shadow-lg' : 'shadow'}`}
      onClick={() => handleSetIslandParams(island.name)}
    >
      <div className="flex gap-2 items-center">
        <span className={` ${isCurrent ? 'bg-venice' : 'bg-venice-pale'} h-2 w-2 shrink-0 rounded-full`}></span>
        <Display className={` ${isCurrent ? 'text-venice' : ''}`}>{island.name}</Display>
      </div>
      <Muted className="">{island.description}</Muted>
    </button>
  </>
}
