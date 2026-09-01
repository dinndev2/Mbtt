import { type Place } from "../../App";
import { Muted } from "../../ui";


export function Results ({results}: {results: Place }) {
  const limitedResults = results.slice(0, 9)
  return  <ul className="w-1/2">
    {limitedResults?.map(({name, id, island, municipality, categories}) => {
        const displayableCategories = categories ? categories.map(({name}) => name)?.join(",") : "Other"
        return <li className="bg-white rounded-2xl my-3 cursor-pointer p-4 flex flex-col gap-1" key={id}> {name} <Muted>{island} · {municipality} · {displayableCategories}</Muted> </li>
      })}
  </ul>
}