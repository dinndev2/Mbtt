import type { PlaceItem, Prominence } from "../../App"
import { useState, useEffect, useRef } from "react"
import { Pencil, Trash2 } from "lucide-react"
import { ConfirmDialog, Tag } from "../../ui"

const TIER_LABEL: Record<NonNullable<Prominence["tier"]>, string> = {
  anchor: "Anchor",
  established: "Established",
  documented: "Documented",
  sparse: "Sparse",
  unverified: "Unverified",
}

const cell = "px-4 py-3 align-middle"

/** One row of the admin places table. */
export default function Place({
  place,
  onEdit,
  onDelete,
  highlightedPlaceId
}: {
  place: PlaceItem
  highlightedPlaceId?: number
  onEdit?: (place: PlaceItem) => void
  onDelete?: (place: PlaceItem) => void | Promise<void>
}) {
  const trRef = useRef<HTMLTableRowElement>(null)

  useEffect(() => {
    if(highlightedPlaceId == place.id) {
      trRef.current?.classList.add("border-green-500")
    
      const removeHighlight = setTimeout(() => trRef.current?.classList.remove("border-green-500"), 3000)
      return () => {
        clearTimeout(removeHighlight)
      }
    }
  },[highlightedPlaceId])

  const tier = place.prominence?.tier
  const [confirmingDelete, setConfirmingDelete] = useState(false)

  return (
    <tr ref={trRef} id={`${place.id}`} className="border-t transition-all border-divider hover:bg-chip/60">
      <td className={cell}>
        <div className="font-semibold text-ink">{place.name ?? "Untitled place"}</div>
        <div className="font-mono text-[11px] text-ink-soft">{place.external_id}</div>
      </td>

      <td className={`${cell} capitalize text-ink`}>{place.island ?? "—"}</td>

      <td className={`${cell} hidden text-ink md:table-cell`}>{place.municipality ?? "—"}</td>

      <td className={`${cell} hidden lg:table-cell`}>
        <div className="flex flex-wrap gap-1">
          {place.categories.length
            ? place.categories.map((category) => <Tag key={category.id}>{category.name}</Tag>)
            : <span className="text-ink-soft">—</span>}
        </div>
      </td>

      <td className={`${cell} hidden md:table-cell`}>
        {place.coordinates_approximate
          ? <Tag>Approximate</Tag>
          : <Tag tinted>Verified</Tag>}
      </td>

      <td className={`${cell} hidden lg:table-cell`}>
        {tier ? <Tag tinted={tier === "anchor"}>{TIER_LABEL[tier]}</Tag> : <span className="text-ink-soft">—</span>}
      </td>

      <td className={`${cell} hidden text-right tabular-nums text-ink sm:table-cell`}>{place.images.length}</td>

      <td className={`${cell} text-right`}>
        <div className="inline-flex gap-1">
          <button
            type="button"
            onClick={() => onEdit?.(place)}
            aria-label={`Edit ${place.name ?? "place"}`}
            className="rounded-pill p-2 text-venice transition-colors hover:bg-venice-pale"
          >
            <Pencil className="size-4" />
          </button>
          {!place.original && <button
            type="button"
            onClick={() => setConfirmingDelete(true)}
            aria-label={`Delete ${place.name ?? "place"}`}
            className="rounded-pill p-2 text-ink-soft transition-colors hover:bg-sun-pale hover:text-ink"
          >
            <Trash2 className="size-4" />
          </button> }
        </div>
        {confirmingDelete && (
          <ConfirmDialog
            title={`Delete ${place.name ?? "this place"}?`}
            onConfirm={() => onDelete?.(place)}
            onClose={() => setConfirmingDelete(false)}
          >
            Its photos, categories, fees and access legs go with it. This can't be undone.
          </ConfirmDialog>
        )}
      </td>
    </tr>
  )
}
