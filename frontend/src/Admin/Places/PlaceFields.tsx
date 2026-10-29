import { type ImageItem, type PlaceItem } from "../../App"
import { type ReactNode } from "react"
import { Divider, Input, Label } from "../../ui"
import { Trash2 } from "lucide-react"
import { useState, useEffect } from "react"

const ISLANDS = ["Masbate", "Ticao", "Burias"]
const COORD_STATUSES = [
  { value: "verified", label: "Verified" },
  { value: "web_sourced", label: "Web sourced" },
  { value: "town_centroid", label: "Town centroid" },
]
const PROMINENCE_TIERS = ["anchor", "established", "documented", "sparse", "unverified"]

// Same look as the ui Input, for the elements it doesn't cover.
const control = "rounded-input w-full border border-divider bg-surface px-4 py-3 text-base font-light outline-none placeholder:text-ink-soft"

function Field({ label, hint, className, children }: { label: string; hint?: string; className?: string; children: ReactNode }) {
  return (
    <label className={`flex flex-col gap-2 ${className ?? ""}`}>
      <Label>{label}</Label>
      {children}
      {hint && <span className="text-xs font-light text-ink-soft">{hint}</span>}
    </label>
  )
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <fieldset className="flex flex-col gap-4">
      <legend className="mb-4 font-display text-2xl text-venice">{title}</legend>
      {children}
    </fieldset>
  )
}

export default function PlaceFields({ place, handleSelectedMultipleFiles, handleDeleteMultipleFiles }: { place?: PlaceItem | null, handleSelectedMultipleFiles?: (e: React.ChangeEvent<HTMLInputElement>) => void, handleDeleteMultipleFiles?: (id: number) => void }) {
  
  return <>
    <Section title="Basics">
      <Field label="Name">
        <Input type="text" name="name" defaultValue={place?.name ?? ""} required />
      </Field>
      <input
        type="file"
        multiple={true}
        onChange={handleSelectedMultipleFiles}
        accept="image/*"
      />
      {place && <div className="w-full overflow-x-scroll"> 
        <ul className="flex w-full lg:overflow-x-scroll snap-x snap-mandatory scrollbar-none rounded md:rounded-2xl">
          {place.images.map(({url, id}) => {
            return <div key={id} className="w-96 max-h-68 relative">
              <span onClick={(e) => handleDeleteMultipleFiles && handleDeleteMultipleFiles(id)} className="absolute cursor-pointer hover:opacity-90 top-2 left-3 rounded-full p-2 font-display text-venice bg-white border border-venice"><Trash2 className="h-3 w-3"/></span>
              <img className="object-cover md:p-1 max-h-68 snap-center md:rounded-2xl w-full shrink-0" key={url} src={url} alt={place.name} />
              </div>
          })}
        </ul>
      </div>}
        
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Island">
          <select name="island" defaultValue={place?.island ?? ""} className={control}>
            <option value="" disabled>Choose an island</option>
            {ISLANDS.map((island) => <option key={island} value={island}>{island}</option>)}
          </select>
        </Field>
        <Field label="Town">
          <Input type="text" name="municipality" defaultValue={place?.municipality ?? ""} />
        </Field>
      </div>
      <Field label="Description">
        <textarea name="description" rows={4} defaultValue={place?.description ?? ""} className={`${control} resize-y`} />
      </Field>
    </Section>

    <Divider className="mx-0" />

    <Section title="Location">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Latitude">
          <Input type="number" name="latitude" step="0.000001" defaultValue={place?.latitude ?? ""} />
        </Field>
        <Field label="Longitude">
          <Input type="number" name="longitude" step="0.000001" defaultValue={place?.longitude ?? ""} />
        </Field>
      </div>
      <Field label="Coordinate status" hint="Only verified coordinates are survey-grade. The rest are approximate.">
        <select name="coord_status" defaultValue={place?.coord_status ?? ""} className={control}>
          <option value="" disabled>Choose a status</option>
          {COORD_STATUSES.map((status) => <option key={status.value} value={status.value}>{status.label}</option>)}
        </select>
      </Field>
    </Section>

    <Divider className="mx-0" />

    <Section title="Getting there">
      <Field label="Travel time note">
        <Input type="text" name="travel_time_note" defaultValue={place?.travel_time_note ?? ""} />
      </Field>
      <Field label="Access note">
        <textarea name="access_note" rows={3} defaultValue={place?.access_note ?? ""} className={`${control} resize-y`} />
      </Field>
    </Section>

    <Divider className="mx-0" />

    <Section title="Source">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Source">
          <Input type="text" name="source" defaultValue={place?.source ?? ""} />
        </Field>
        <Field label="Prominence tier">
          <select name="prominence_tier" defaultValue={place?.prominence?.tier ?? ""} className={`${control} capitalize`}>
            <option value="">None</option>
            {PROMINENCE_TIERS.map((tier) => <option key={tier} value={tier}>{tier}</option>)}
          </select>
        </Field>
      </div>
    </Section>
    
  </>
}
