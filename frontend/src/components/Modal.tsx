import { X } from 'lucide-react'
import { useState, useRef, useEffect } from 'react'
import { createPortal } from "react-dom"




export default function Modal({closePlaceModal, children}: {closePlaceModal: any, children: React.ReactNode}) {
  const contentRef = useRef<HTMLDivElement>(null)
  const [isClosing, setIsClosing] = useState(false)
  const requestClose = () => setIsClosing(true)
  
  const closeOnBackdrop = (e: React.MouseEvent) => {
    if (contentRef.current && !contentRef.current.contains(e.target as Node)) {
      requestClose()
    }
  }
  

  const unmountWhenExitDone = (e: React.AnimationEvent) => {
    // The enter animation raises this event too, and it bubbles up from any
    // animated child - only the panel's own exit run should unmount.
    if (isClosing && e.target === contentRef.current) closePlaceModal()
  }

  return <div id="modal-wrapper">
    <div className="fixed inset-0 z-50" onClick={(e) => closeOnBackdrop(e)}>
      {/* Overlay. Fades on its own track so the scrim isn't still solid behind
          a panel that has already left. */}
      <div
        className={`absolute inset-0 bg-gray-900/20 backdrop-blur-sm ${isClosing ? 'animate-backdrop-out' : 'animate-backdrop-in'}`}
      />

      {/* Modal */}
      <div className="relative flex h-full items-center justify-center max-w-5xl mx-auto">
        <div
          ref={contentRef}
          onAnimationEnd={unmountWhenExitDone}
          className={`bg-white p-4 lg:m-5 grid rounded-2xl max-w-6xl w-full relative ${isClosing ? 'animate-out' : 'animate-in'}`}
        >
          {children}
          <button
            className="absolute transition-all hover:bg-gray-100 top-7 right-7 cursor-pointer bg-white rounded-xl shadow-xl p-2 "
            onClick={requestClose}
          >
            <X />
          </button>
        </div>
      </div>
    </div>
  </div>
}
