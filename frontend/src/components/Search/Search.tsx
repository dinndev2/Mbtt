import { useState, useEffect } from 'react'
import type { Bundle, IslandItem, Place } from '../../App'
import { useSearchParams } from "react-router";
import { Search as SearchIcon } from "lucide-react";
import { Results } from './Results';


type Route = {
  island: string
  name: string
  municipality: string
  fare_note: string
  operator: string
}

export const searchableLabels = ["island", "name", "municipality", "fare_note"] as const satisfies (keyof Route)[]
export type SearchableLabel = typeof searchableLabels[number]





function trimString(s: any) {
  var l=0, r=s.length -1;
  while(l < s.length && s[l] == ' ') l++;
  while(r > l && s[r] == ' ') r-=1;
  return s.substring(l, r+1).toLowerCase();
}

function compareObjects(o1: any, o2: any) {
  var k = '';
  for(k in o1) if(o1[k] != o2[k]) return false;
  for(k in o2) if(o1[k] != o2[k]) return false;
  return true;
}

function itemExists(haystack: any, needle: any) {
  for(var i=0; i<haystack.length; i++) if(compareObjects(haystack[i], needle)) return true;
  return false;
}

function searchFor(bundle: Bundle, query: string): Place {
  const flatten:any = Object.values(bundle.places).flat();
  const results: Place = []
  for(let i = 0; i < flatten.length; i++) {
    for(const property in flatten[i]) { 
      const key = property as SearchableLabel
      // check if the property key matches the key we are looking for
      if (searchableLabels.includes(key)) {
        const placeName = flatten[i][property].toLowerCase()
        if (placeName != null && placeName.indexOf(query) != -1) {
          if(!itemExists(results, flatten[i])) {
            results.push(flatten[i])
          } 
        }
      }
    }
  }
  console.log(results)
  return results
}

export function Search({bundle}: {bundle: Bundle} ) { 
  const [results, setResults] = useState<Place>()
  const [searchParams, setSearchParams] = useSearchParams("");
  const [resultContainerVisibility, setResultContainerVisibility] = useState<boolean>(false)
  const query = searchParams.get('q')

  // check if search param exist and render search result if so
  useEffect(() => { 
    if (query == null || query == "") return
    setResultContainerVisibility(true) 
  }, [query]);
  
  const handleQuery = (e: React.ChangeEvent<HTMLInputElement>) => {
    // store the search query to params for later access
    setSearchParams((prev) =>  {
      const next = new URLSearchParams(prev);
      next.set('q', e.target.value)
      return next
    })

    // return if empty 
    if (e.target.value == ""){
      setResultContainerVisibility(false)
      return
    }
    
    setResults(searchFor(bundle, trimString(e.target.value)))
    if (!resultContainerVisibility) {
      setResultContainerVisibility(true);
    }

  }

  // supports form submission 
  const hundleSubmit = (e:  React.SubmitEvent<HTMLFormElement>) => {
    e.preventDefault()
  }

  

  return <div className="mx-auto w-full max-w-7xl px-5 py-8 h-screen">
    <form className='relative mx-auto w-full max-w-xl' onSubmit={hundleSubmit}>
      <SearchIcon className='absolute bottom-4 left-3' size={18} strokeWidth={2.2} color="#16587b" />
      <input className='pl-10 h-12 w-full rounded-xl bg-white border border-gray-200 focus:shadow-xl' placeholder="Beach, Town or Terminal" id="queryInput" name="query" onChange={handleQuery} />
    </form> 
    <div className="mt-5 flex flex-col gap-6 lg:flex-row">
      <div className="w-1/2">Recommendations</div>
      {(resultContainerVisibility && results) && <Results results={results} /> }
    </div>
  </div>
}