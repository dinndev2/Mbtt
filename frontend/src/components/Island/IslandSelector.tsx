import IslandMap from "./IslandMap"
import { Display, Muted } from "../../ui"
import { toIslandKey } from "./island-paths"
import { useSearchParams } from "react-router"
import { Island } from "./Island"
import type { Bundle } from "../../App"


export default function IslandSelector({bundle}: {bundle: Bundle}) {
  const [islandParams, setIslandParams] = useSearchParams();
  const islandQuery = islandParams.get('island') 

  const handleSetIslandParams = (island: string) => {
    setIslandParams({ island: island.toLocaleLowerCase()})
  }

  return <div className="mx-auto flex w-full max-w-6xl flex-col items-center justify-center gap-6 px-5 py-8 sm:px-8 sm:py-12 lg:h-dvh lg:max-w-none lg:flex-row lg:gap-10 lg:p-20">
    <div className="flex w-full items-center justify-center lg:w-1/2">
      <IslandMap
        className="max-w-[15rem] sm:max-w-xs lg:max-w-md"
        onSelect={handleSetIslandParams}
        selected={toIslandKey(islandQuery)}
      />
    </div>
    <div className="w-full lg:w-1/2">
      <Display className='lg:font-medium' size={"xxl"} >
        Which island
        <br/>
        are you on?
      </Display>
      <Muted className='my-2 max-w-prose' >
        Fares, terminals and crossings differ by island. Pick one to start
        {/* Hard break only where the line is wide enough to want one. */}
        <br className="hidden lg:inline" /> you can switch any time.
      </Muted>
      <Island
        handleSetIslandParams={handleSetIslandParams}
        islands={bundle?.islands}
        places={bundle?.places}
      />
    </div>
  </div>
}