import type { PlaceItem } from "../../App"

export default function ImageSlider({place}: {place: PlaceItem}) {
  const { images, name } = place
  
  return <div className="w-full">
    <ul className="flex w-full gap-4 lg:overflow-x-hidden snap-x snap-mandatory scrollbar-none rounded-2xl">
      {images.map(({url}) => {
        // Keyed by url, not license - both photos of a place usually share one
        // licence, which made the keys collide.
        return <img className="object-cover max-h-96 snap-center rounded-2xl w-1/2 shrink-0" key={url} src={url} alt={name} />
      })}
    </ul>
  </div>
}