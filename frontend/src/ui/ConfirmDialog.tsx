import { useEffect, useId, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { TriangleAlert } from 'lucide-react'
import { Button } from './Button'
import { Display, Muted } from './Text'

/**
 * A small yes/no dialog for actions that can't be undone, like deleting a
 * record. Rendered into <body> through a portal, so it can be opened from
 * anywhere - including a table row, where a <div> would be invalid markup.
 *
 * `onConfirm` may return a promise; the dialog shows `pendingLabel` and stays
 * open until it settles, then plays its exit animation and calls `onClose`.
 */
export function ConfirmDialog({
  title,
  children,
  confirmLabel = 'Delete',
  pendingLabel = 'Deleting…',
  onConfirm,
  onClose,
}: {
  title: string
  children?: ReactNode
  confirmLabel?: string
  pendingLabel?: string
  onConfirm: () => void | Promise<void>
  onClose: () => void
}) {
  const [isClosing, setIsClosing] = useState(false)
  const [pending, setPending] = useState(false)
  const titleId = useId()

  const requestClose = () => {
    if (!pending) setIsClosing(true)
  }

  // Escape cancels, like the backdrop does.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && requestClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  })

  async function confirm() {
    setPending(true)
    try {
      await onConfirm()
    } finally {
      setPending(false)
      setIsClosing(true)
    }
  }

  return createPortal(
    <div className="fixed inset-0 z-[150] flex items-end justify-center p-4 sm:items-center" onClick={requestClose}>
      <div
        className={`absolute inset-0 bg-venice-deep/25 backdrop-blur-sm ${isClosing ? 'animate-backdrop-out' : 'animate-backdrop-in'}`}
      />
      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
        onAnimationEnd={(e) => {
          if (isClosing && e.target === e.currentTarget) onClose()
        }}
        className={`relative w-full max-w-sm rounded-card-lg border-[1.5px] border-venice bg-surface p-6 ${
          isClosing ? 'animate-modal-out' : 'animate-modal-in'
        }`}
      >
        <span className="mb-4 flex size-11 items-center justify-center rounded-full bg-sun-pale text-venice">
          <TriangleAlert className="size-5" />
        </span>
        <Display as="h2" size="sm" id={titleId}>{title}</Display>
        {children && <Muted className="mt-2">{children}</Muted>}

        <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <Button variant="secondary" onClick={requestClose} disabled={pending} autoFocus>
            Cancel
          </Button>
          <Button onClick={confirm} disabled={pending}>
            {pending ? pendingLabel : confirmLabel}
          </Button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
