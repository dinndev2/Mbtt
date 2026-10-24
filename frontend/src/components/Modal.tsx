import { X } from 'lucide-react'
import { createContext, useRef, useState } from 'react'

/**
 * Lets anything inside a modal close it the same way the X button does, exit
 * animation included. Each Modal provides its own, so closing one never
 * touches another.
 */
export const ModalControlContext = createContext<{ requestClose: () => void } | null>(null)


type ModalProps = {
  closePlaceModal: () => void
  children: React.ReactNode
}

export default function Modal({
  closePlaceModal,
  children,
}: ModalProps) {
  const contentRef = useRef<HTMLDivElement>(null)

  const startY = useRef(0)
  const currentY = useRef(0)
  const startTime = useRef(0)

  const [isClosing, setIsClosing] = useState(false)

  const requestClose = () => {
    setIsClosing(true)
  }

  const closeOnBackdrop = (e: React.MouseEvent) => {
    if (
      contentRef.current &&
      !contentRef.current.contains(e.target as Node)
    ) {
      requestClose()
    }
  }

  const down = (e: React.PointerEvent) => {
    startY.current = e.clientY
    currentY.current = e.clientY
    startTime.current = e.timeStamp

    if (contentRef.current) {
      contentRef.current.style.transition = 'none'
    }

    e.currentTarget.setPointerCapture(e.pointerId)
  }

  const move = (e: React.PointerEvent) => {
    currentY.current = e.clientY

    const deltaY = currentY.current - startY.current

    if (deltaY <= 0 || !contentRef.current) return

    contentRef.current.style.transform = `translateY(${deltaY}px)`
  }

  const up = (e: React.PointerEvent) => {
    currentY.current = e.clientY

    const deltaY = currentY.current - startY.current
    const elapsed = Math.max(e.timeStamp - startTime.current, 1)
    // A quick flick should dismiss even if it didn't travel far.
    const isFlick = deltaY > 30 && deltaY / elapsed > 0.5

    if (!contentRef.current) return

    if (deltaY >= 100 || isFlick) {
      // Hand the drag offset to the exit keyframes so the sheet keeps
      // sliding down from where it was let go.
      contentRef.current.style.setProperty(
        '--sheet-drag-y',
        `${Math.max(deltaY, 0)}px`
      )
      contentRef.current.style.transform = ''
      requestClose()
    } else {
      contentRef.current.style.transition =
        'transform 200ms ease-out'
      contentRef.current.style.transform = 'translateY(0)'
    }

    e.currentTarget.releasePointerCapture(e.pointerId)
  }

  const unmountWhenExitDone = (
    e: React.AnimationEvent<HTMLDivElement>
  ) => {
    if (
      isClosing &&
      e.target === contentRef.current
    ) {
      closePlaceModal()
    }
  }

  return (
    <div id="modal-wrapper">
      <div
        className="fixed inset-0 z-100"
        onClick={closeOnBackdrop}
      >
        {/* Backdrop */}
        <div
          className={`absolute inset-0 bg-venice-deep/25 backdrop-blur-sm ${
            isClosing
              ? 'animate-backdrop-out'
              : 'animate-backdrop-in'
          }`}
        />

        {/* Modal positioning */}
        {/* Below md the panel is a sheet that leaves a strip of backdrop at
            the top, so it reads as something laid over the page that can be
            swiped back down. */}
        <div className="relative flex h-dvh max-w-5xl mx-auto justify-center pt-[max(1.5rem,env(safe-area-inset-top))] md:pt-0 md:items-center">
          {/* Modal */}
          <div
            ref={contentRef}
            onAnimationEnd={unmountWhenExitDone}
            className={`
              relative
              flex
              flex-col
              w-full
              max-w-6xl
              bg-surface
              rounded-t-card-lg
              md:max-h-4/5
              md:rounded-card-lg
              md:border-[1.5px]
              md:border-venice
              md:p-2
              overflow-hidden
              ${
                isClosing
                  ? 'animate-sheet-out md:animate-modal-out'
                  : 'animate-sheet-in md:animate-modal-in'
              }
            `}
          >
            {/* Drag area */}
            <div
              className="absolute top-0 left-0 right-0 z-20 h-10 touch-none md:hidden"
              onPointerDown={down}
              onPointerMove={move}
              onPointerUp={up}
              onPointerCancel={up}
            >
              {/* Drag handle */}
              <div className="mx-auto mt-3 h-1.5 w-12 rounded-full bg-venice/25" />
            </div>

            {/* Close button */}
            {/* The portfolio's round button: outlined in ink, fills on hover. */}
            <button
              type="button"
              aria-label="Close"
              className="
                absolute
                right-4
                top-4
                z-30
                flex
                size-11
                cursor-pointer
                items-center
                justify-center
                rounded-full
                border-[1.5px]
                border-venice
                bg-surface
                text-venice
                transition-colors
                hover:bg-venice
                hover:text-surface
                md:right-6
                md:top-6
              "
              onClick={requestClose}
            >
              <X size={20} />
            </button>

            {/* Scrollable content. min-h-0 lets it shrink below its content
                inside the column, which is what makes it scroll - and what
                gives the place sheet's fare bar an edge to stick to. */}
            <div className="flex min-h-0 flex-1 flex-col overflow-y-auto overscroll-contain">
              <ModalControlContext value={{ requestClose }}>
                {children}
              </ModalControlContext>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}