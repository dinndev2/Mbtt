import { type Place } from "../../App";
import { Label, Muted } from "../../ui";
import { type PlaceItem } from "../../App";
import { Clock, ImageIcon, SearchX, X } from "lucide-react";
import { CategoryTag, duration, titleize, tripTime } from "../../utilities";

type ResultTypes = {
  results: Place,
  /** What was typed. Empty when the list is the island's own places. */
  query: string,
  island: string,
  /** Nearby searches to offer when nothing matched. */
  suggestions: string[],
  togglePlaceInformation: (place: PlaceItem) => void,
  onSuggest: (term: string) => void,
  onClose: () => void
}

export function Results ({results, query, island, suggestions, togglePlaceInformation, onSuggest, onClose}: ResultTypes) {
  const limitedResults = results.slice(0, 9)
  // Each row has its own `island` - the place's - so keep the traveller's.
  const fromIsland = titleize(island)

  return <>
    <div className="flex items-center justify-between gap-3 px-1">
      <Label>
        {query
          ? `${results.length} ${results.length === 1 ? 'match' : 'matches'} for “${query}”`
          : `Places on ${titleize(island)}`}
      </Label>
      <button
        type="button"
        onClick={onClose}
        aria-label="Close results"
        className="flex size-8 cursor-pointer items-center justify-center rounded-full text-venice transition-colors hover:bg-venice-pale"
      >
        <X size={16} />
      </button>
    </div>

    {limitedResults.length > 0 ?
      /* Two columns of rows rather than a card grid, so a thumbnail, the
         fare and the place all sit on one line. Capped and scrollable
         because this is a dropdown. */
      <ul className="grid grid-cols-1 lg:grid-cols-2 gap-x-6 gap-y-1 mt-2 max-h-[60vh] overflow-y-auto overscroll-contain">
        {limitedResults.map((place) => {
            const {name, id, municipality, categories, images, island} = place
            const category = categories?.[0]?.name
            const preview = images?.[0]
            // Time from the island picked in "leaving from", because that is
            // what decides whether a place fits in the day. The bundle is
            // fetched for that island, so the estimate already starts there.
            const estimate = place.fare_estimates[0]
            const time = tripTime(estimate)
            const open = () => togglePlaceInformation(place)

            /* Not a <button>: Muted renders a <p>, which a button may
               not contain. role/tabIndex/keydown give it the same
               keyboard behaviour without the invalid markup. */
            return <li key={id}>
                <div
                  role="button"
                  tabIndex={0}
                  onClick={open}
                  onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open() } }}
                  className="group flex gap-3 sm:gap-4 items-start p-2 sm:p-3 rounded-row cursor-pointer transition-colors hover:bg-venice-pale focus-visible:bg-venice-pale"
                >
                  <div className="w-24 h-20 sm:w-32 sm:h-28 shrink-0 rounded-xl overflow-hidden border border-divider">
                    {preview
                      ? <img
                          src={preview.url}
                          alt=""
                          loading="lazy"
                          decoding="async"
                          className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                        />
                      /* Nine of the 33 places still have no photograph. The
                         portfolio's hatch, so a gap reads as deliberate. */
                      : <div className="w-full h-full grid place-items-center bg-[repeating-linear-gradient(-45deg,#2231b833_0_1.4px,transparent_1.4px_9px)] text-venice/60">
                          <ImageIcon size={16} />
                        </div>}
                  </div>

                  <div className="flex flex-1 min-w-0 flex-col gap-1.5 py-0.5">
                    <span className="font-semibold leading-snug line-clamp-2" title={name}>{name}</span>
                    <Muted className="text-sm">{municipality}, {island}</Muted>
                    <div className="flex items-center justify-between gap-2 flex-wrap">
                      {category && <CategoryTag name={category} />}
                      {estimate?.local
                        ? <span className="font-mono text-[11px] text-ink-soft">on {fromIsland}</span>
                        : time
                          ? <span className="flex flex-col items-end" title={`Travel time from ${fromIsland}`}>
                              <span className="inline-flex items-center gap-1 font-display text-xl leading-none text-venice tabular-nums">
                                <Clock size={13} className="shrink-0" aria-hidden />
                                {time.partial && <span className="text-base">from</span>} {duration(time.minutes)}
                              </span>
                              <span className="font-mono text-[10px] uppercase tracking-wider text-ink-soft">leaving {fromIsland}</span>
                            </span>
                          : <span className="font-mono text-[11px] text-ink-soft">time not published</span>}
                    </div>
                  </div>
                </div>
              </li>
          })}
      </ul>
    : <EmptyState query={query} island={island} suggestions={suggestions} onSuggest={onSuggest} />}
  </>
}

/**
 * Nothing matched. Says what was searched, what the search understands, and
 * offers somewhere to go next - a dead end with only "No places" in it gives
 * a first-time visitor no idea whether the place is missing or misspelled.
 */
function EmptyState({ query, island, suggestions, onSuggest }: {
  query: string
  island: string
  suggestions: string[]
  onSuggest: (term: string) => void
}) {
  return (
    <div className="flex flex-col items-center gap-4 px-4 py-8 text-center">
      <span className="grid size-14 place-items-center rounded-full border-[1.5px] border-venice bg-[radial-gradient(#2231b84d_1.4px,transparent_1.7px)] bg-size-[9px_9px] text-venice">
        <SearchX size={22} />
      </span>

      <div className="flex max-w-sm flex-col gap-2">
        <p className="font-display text-3xl leading-none text-venice">
          {query ? <>Nothing called “{query}” yet</> : <>No places on {titleize(island)} yet</>}
        </p>
        <Muted className="text-sm">
          Search by a place name, a town or an island. Check the spelling,
          or try one of these.
        </Muted>
      </div>

      {suggestions.length > 0 && (
        <div className="flex flex-wrap justify-center gap-2">
          {suggestions.map((term) => (
            <button
              key={term}
              type="button"
              onClick={() => onSuggest(term)}
              className="cursor-pointer rounded-pill border-[1.5px] border-venice bg-surface px-3.5 py-1.5 text-sm font-semibold text-venice transition-colors hover:bg-venice hover:text-surface"
            >
              {term}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
