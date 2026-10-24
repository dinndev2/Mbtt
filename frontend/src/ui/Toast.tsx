import { useEffect, useState } from 'react'
import { CircleCheck } from 'lucide-react'

// How long a toast stays up. The timer bar in index.css runs on the same 3s.
const VISIBLE_MS = 3000

/**
 * A short confirmation, like "Saved". Drops in at the top of the screen, above
 * any modal, and leaves on its own. `onDone` runs once the exit animation has
 * finished, which is where the caller clears the message.
 */
export function Toast({ message, onDone }: { message: string; onDone: () => void }) {
  const [closing, setClosing] = useState(false)

  useEffect(() => {
    if (!message) return
    setClosing(false)
    const timer = setTimeout(() => setClosing(true), VISIBLE_MS)
    return () => clearTimeout(timer)
  }, [message])

  if (!message) return null

  return (
    <div className="pointer-events-none fixed inset-x-0 top-[max(1rem,env(safe-area-inset-top))] z-[200] flex justify-center px-4">
      <div
        role="status"
        aria-live="polite"
        onAnimationEnd={(e) => {
          if (closing && e.target === e.currentTarget) onDone()
        }}
        className={`pointer-events-auto relative flex items-center gap-3 overflow-hidden rounded-card bg-venice-deep py-3 pl-4 pr-5 text-surface shadow-[0_18px_40px_-18px_#17206e99] ${
          closing ? 'animate-toast-out' : 'animate-toast-in'
        }`}
      >
        <CircleCheck className="size-5 shrink-0 text-sun" />
        <span className="text-sm font-semibold">{message}</span>
        {/* Time left before it goes. */}
        <span className="absolute inset-x-0 bottom-0 h-0.5 origin-left bg-sun motion-safe:animate-toast-timer" />
      </div>
    </div>
  )
}
