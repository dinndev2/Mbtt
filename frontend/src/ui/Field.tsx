import type { ComponentPropsWithRef } from 'react'
import { cn } from './cn'

/** A text input. White on cream, chip-filled when nested inside a card. */
export function Input({
  className, inset, ...props
}: ComponentPropsWithRef<'input'> & { inset?: boolean }) {
  return (
    <input
      className={cn(
        'rounded-input placeholder:text-ink-soft w-full px-4 py-3 text-base font-light outline-none',
        inset ? 'bg-chip' : 'bg-surface border-divider border',
        className,
      )}
      {...props}
    />
  )
}

/**
 * A tappable list row. Use `as="li"` inside a list, or leave it a div and put
 * a button inside when only part of the row is interactive.
 */
export function Row({ className, ...props }: ComponentPropsWithRef<'div'>) {
  return (
    <div
      className={cn('rounded-row bg-surface flex items-center gap-3 px-4 py-3', className)}
      {...props}
    />
  )
}

/** Hairline between rows. Inset by default so it stops short of the card edge. */
export function Divider({ className, ...props }: ComponentPropsWithRef<'hr'>) {
  return <hr className={cn('border-divider mx-4 border-t', className)} {...props} />
}
