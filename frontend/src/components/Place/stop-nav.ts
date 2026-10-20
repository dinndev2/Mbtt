import { createContext } from "react"

/**
 * Opens a terminal as its own page inside the place sheet. Provided by
 * PlaceModalContent; a pier name anywhere in the way in calls it.
 */
export const StopNavContext = createContext<(gtfsId: string) => void>(() => {})
