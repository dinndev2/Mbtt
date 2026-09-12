import { type PlaceItem } from '../../App'
import { Chip, Display, Muted } from '../../ui'
import ImageSlider from './ImageSlider'

export default function PlaceModalContent({currentSelectedPlace}: { currentSelectedPlace: PlaceItem}) {
  const { municipality } = currentSelectedPlace

  return <>
      {currentSelectedPlace && <div className='flex flex-col gap-2'>
        <ImageSlider place={currentSelectedPlace} />
        <span className="flex gap-2">
          <Chip  className='inline'>{municipality} </ Chip>
          <Chip active className='inline'>{currentSelectedPlace.island} Island </ Chip>
        </span>  
        <Display size="xl"> {currentSelectedPlace.name}</Display>
        <Muted> {currentSelectedPlace.description} </Muted>
      </div>}    
  </>
}
