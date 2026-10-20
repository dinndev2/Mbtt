import type { PlaceItem } from '@/App'
import { MapContainer, TileLayer, Marker, Tooltip} from 'react-leaflet'


export default function Map ({ currentSelectedPlace}: {currentSelectedPlace: PlaceItem}) {
  const { municipality, latitude, longitude, name } = currentSelectedPlace



  return <>{
    currentSelectedPlace && <MapContainer
    center={[latitude, longitude]}
    zoom={13}
    scrollWheelZoom={false}
    className="h-[500px] w-full rounded-xl border-2"
  
  
  >
    <TileLayer
      
      url="https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png"
      attribution='&copy; OpenStreetMap contributors &copy; Stadia Maps'
    />
  
    <Marker position={[latitude, longitude]}>
      <Tooltip permanent direction='top' >
        {name}
      </Tooltip>
    </Marker>
  </MapContainer>
  }</>
}
