import { useState, useEffect } from 'react'
import type { Bundle, IslandItem, Place } from '../../App'
import { useSearchParams } from "react-router";
import { Results } from './Results';
import { useRef } from 'react';
import { type PlaceItem } from '../../App';
import { useContext } from "react";
import { ModalContext } from "../../App";

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

function searchFor(places: Place, query: string): Place {
  const flatten:any = Object.values(places).flat();
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

export function Search({places, setCurrentSelectedPlace, currentSelectedPlace}: {places: Place, currentSelectedPlace: PlaceItem | null, setCurrentSelectedPlace: (place: PlaceItem) => void} ) { 
  const [results, setResults] = useState<Place>()
  const [searchParams, setSearchParams] = useSearchParams("");
  const [resultContainerVisibility, setResultContainerVisibility] = useState<boolean>(false)
  const query = searchParams.get('q')
  const islandParams = searchParams.get('island')
  const resultRef = useRef<HTMLDivElement | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const setPlaceModalContext = useContext(ModalContext)
  const openPlaceModal = setPlaceModalContext?.openPlaceModal
  // check if search param exist and render search result if so
  useEffect(() => {
    setResultContainerVisibility(true)

  }, [query]);
  
  const togglePlaceInformation = (selectedPlace: PlaceItem) => {
    // set the current selected place
    setCurrentSelectedPlace(selectedPlace)
    const selectedName = selectedPlace && selectedPlace?.name || ""
    if (inputRef.current) {
      inputRef.current.value = selectedName
    }

    // open modal
    openPlaceModal && openPlaceModal()
  }
  
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
    triggerSearch(places, e.target.value)
    if (!resultContainerVisibility) {
      setResultContainerVisibility(true);
    }
  }

  function handleFocusRecommendation() {
    const recommendedIslandPlaces = inputRef.current?.value || islandParams || "masbate";
    if(!resultContainerVisibility) setResultContainerVisibility(true)
    triggerSearch(places, recommendedIslandPlaces)
  }

  function triggerSearch(searchFromArray: any, keyword: string) {
    setResults(searchFor(searchFromArray, trimString(keyword)))
  }

  // supports form submission 
  const handleSubmit = (e: React.SubmitEvent<HTMLFormElement>) => {
    e.preventDefault()
  }

  

  return <div className='w-full'>
    <form className='mx-auto w-full max-w-xl' onSubmit={handleSubmit} onFocus={handleFocusRecommendation}>
      <input type="string" ref={inputRef} className=' w-full focus:outline-0' placeholder="Beach, Town or Terminal" id="queryInput" name="query" onChange={handleQuery} />
    </form>  
    {(resultContainerVisibility && results) &&   
      <div ref={resultRef} className="z-10 absolute gap-6 shadow-xl right-0 lg:flex-row w-full bg-white top-28 rounded-2xl text-left p-4">
        <Results results={results} togglePlaceInformation={togglePlaceInformation} onClose={() => setResultContainerVisibility(false)} />
      </div>}
  </div>
}