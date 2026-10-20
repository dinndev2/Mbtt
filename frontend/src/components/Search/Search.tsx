import { useState, useEffect, useMemo } from 'react'
import type { Place } from '../../App'
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
        const value = flatten[i][property];
        const placeName = typeof value === "string" ? value.toLowerCase() : value;
        if (placeName != null && placeName.indexOf(query) != -1) {
          if(!itemExists(results, flatten[i])) {
            results.push(flatten[i])
          } 
        }
      }
    }
  }
  return results
}

export function Search({places, setCurrentSelectedPlace}: {places: Place, setCurrentSelectedPlace: (place: PlaceItem) => void} ) { 
  const [results, setResults] = useState<Place>()
  const [searchParams, setSearchParams] = useSearchParams("");
  const [resultContainerVisibility, setResultContainerVisibility] = useState<boolean>(false)
  const islandParams = searchParams.get('island') || 'masbate'
  const resultRef = useRef<HTMLDivElement | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  // The term behind the results on screen, for the header. Empty when the
  // list is the island's own places rather than an answer to a search.
  const [query, setQuery] = useState('')
  const setPlaceModalContext = useContext(ModalContext)
  const openPlaceModal = setPlaceModalContext?.openPlaceModal
  // check if search param exist and render search result if so
  useEffect(() => {
    setResultContainerVisibility(true)
    setQuery('')
    triggerSearch(places, islandParams)
  }, [ islandParams]);
  
  const togglePlaceInformation = (selectedPlace: PlaceItem) => {
    // set the current selected place
    setCurrentSelectedPlace(selectedPlace)
    const selectedName = selectedPlace?.name || ""
    setSearchParams(
      (params) => {
      params.set('id', String(selectedPlace?.id))
      return params
    })
    if (inputRef.current) {
      inputRef.current.value = selectedName
    }

    // open modal
    openPlaceModal && openPlaceModal()
  }
  
  const handleQuery = (e: React.ChangeEvent<HTMLInputElement>) => {
    console.log(results)
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
    setQuery(e.target.value.trim())
    triggerSearch(places, e.target.value)
    if (!resultContainerVisibility) {
      setResultContainerVisibility(true);
    }
  }

  function handleFocusRecommendation() {
    const recommendedIslandPlaces = inputRef.current?.value || islandParams || "masbate";
    if(!resultContainerVisibility) setResultContainerVisibility(true)
    setQuery(inputRef.current?.value.trim() ?? '')
    triggerSearch(places, recommendedIslandPlaces)
  }

  // Something to tap when a search comes back empty: the towns with places
  // on this island first, so a suggestion is never itself a dead end.
  const suggestions = useMemo(() => {
    const onIsland = places.filter((place) => place.island?.toLowerCase() === islandParams.toLowerCase())
    const towns = (onIsland.length ? onIsland : places).map((place) => place.municipality)
    return [...new Set(towns.filter((town): town is string => Boolean(town)))].slice(0, 4)
  }, [places, islandParams])

  const searchFromSuggestion = (term: string) => {
    if (inputRef.current) inputRef.current.value = term
    setQuery(term)
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev)
      next.set('q', term)
      return next
    })
    triggerSearch(places, term)
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
      <input
        type="text"
        ref={inputRef}
        enterKeyHint="search"
        autoComplete="off"
        className='w-full bg-transparent text-base font-semibold text-ink placeholder:font-normal placeholder:text-ink-soft focus:outline-0'
        placeholder="Beach, town or terminal"
        id="queryInput"
        name="query"
        aria-label="Where are you going?"
        onChange={handleQuery}
      />
    </form>  
    {(resultContainerVisibility && results) &&   
      <div ref={resultRef} className="z-10 absolute left-0 right-0 top-full mt-2 w-full rounded-card border border-divider bg-surface p-3 sm:p-4 text-left shadow-[0_18px_40px_-18px_#17206e59]">
        <Results
          results={results}
          query={query}
          island={islandParams}
          suggestions={suggestions}
          togglePlaceInformation={togglePlaceInformation}
          onSuggest={searchFromSuggestion}
          onClose={() => setResultContainerVisibility(false)}
        />
      </div>}
      
  </div>
}