import { type Place } from "../../App";
import { Label, Muted, Tag } from "../../ui";
import { useSearchParams } from "react-router";
import { type PlaceItem } from "../../App";
import { ImageIcon } from "lucide-react";
import { CategoryLogo } from "../../utilities";

type ResultTypes = {
  results: Place,
  togglePlaceInformation: (place: PlaceItem) => void,
  onClose: () => void
}

export function Results ({results, togglePlaceInformation, onClose}: ResultTypes) {
  const [islandParams, _] = useSearchParams();
  const islandQuery = islandParams.get('island')
  const limitedResults = results.slice(0, 9)

  return  <> {limitedResults.length > 0 ?
            <>
              <div className="flex items-center justify-between gap-4">
                <Label> Places on {islandQuery} </Label>
                <button
                  type="button"
                  onClick={onClose}
                  className="text-venice text-sm font-medium cursor-pointer hover:underline"
                >
                  Close
                </button>
              </div>

              {/* Two columns of rows rather than a card grid, so a thumbnail,
                  the travel time and the mode all sit on one line. Capped and
                  scrollable because this is a dropdown. */}
              <ul className="grid grid-cols-1 lg:grid-cols-2 gap-x-6 gap-y-1 mt-3 max-h-[60vh] overflow-y-auto">
                {limitedResults?.map((place) => {
                    const {name, id, municipality, categories, images, island} = place
                    const category = categories?.[0]?.name
                    const preview = images?.[0]
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
                          className="group flex gap-4 items-start p-3 rounded-2xl cursor-pointer transition-colors hover:bg-well focus-visible:bg-well"
                        >
                          <div className="w-36 h-32 shrink-0 rounded-xl overflow-hidden">
                            {preview
                              ? <img
                                  src={preview.url}
                                  alt=""
                                  loading="lazy"
                                  decoding="async"
                                  className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                                />
                              /* Nine of the 33 places still have no photograph.
                                 Presentational only - dropping a file here does
                                 nothing yet. */
                              : <div className="w-full h-full grid place-items-center rounded-xl border border-dashed border-ink-soft/40 bg-well px-2 text-center text-ink-soft">
                                  <span className="flex flex-col items-center gap-1">
                                    <ImageIcon size={16} />
                                  </span>
                                </div>}
                          </div>

                          <div className="flex flex-1 min-w-0 flex-col gap-1.5 py-1">
                            <div className="flex items-start justify-between gap-3">
                              <span className="font-medium leading-snug line-clamp-2" title={name}>{name}</span>
                              
                            </div>
                            <div className="flex items-center gap-2 flex-wrap">
                              {category && <Tag className="flex gap-2" tinted>{category} {CategoryLogo(category)}</Tag>}
                              <Muted className="text-sm">{municipality}, {island}</Muted>
                            </div>
                          </div>
                        </div>
                      </li>
                  })}
              </ul>
            </> : 'No Places' }
          </>
}
