import type { ComponentPropsWithRef } from 'react'
import { cn } from './cn'

/**
 * A filter or tag pill. `active` flips it to Venice Blue - use it for the
 * selected category, mode, or party size.
 */
export function Chip({
  className, active, ...props
}: ComponentPropsWithRef<'button'> & { active?: boolean }) {
  return (
    <button
      type="button"
      aria-pressed={active}
      className={cn(
        'rounded-pill px-4 py-2 text-sm font-medium transition-colors self-start',
        active ? 'bg-venice text-white' : 'bg-chip text-ink hover:bg-venice-pale',
        className,
      )}
      {...props}
    />
  )
}

/**
 * An island selector. Bigger than a Chip and set in the display face, because
 * island is the top-level choice in the app rather than one filter among many.
 */
export function IslandPill({
  className, selected, ...props
}: ComponentPropsWithRef<'button'> & { selected?: boolean }) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      className={cn(
        'rounded-pill font-display px-5 py-2.5 text-lg capitalize transition-colors',
        selected ? 'bg-venice text-white' : 'bg-venice-muted text-venice hover:bg-venice-light hover:text-white',
        className,
      )}
      {...props}
    />
  )
}

/**
 * A non-interactive tag - a category on a place card, a confidence marker.
 * Same pill shape as Chip so they line up, but it is not a button.
 */
export function Tag({ className, tinted, ...props }: ComponentPropsWithRef<'span'> & { tinted?: boolean }) {
  return (
    <span
      className={cn(
        'rounded-pill inline-flex items-center px-3 py-1 text-xs font-medium',
        tinted ? 'bg-venice-pale text-venice' : 'bg-chip text-ink-soft',
        className,
      )}
      {...props}
    />
  )
}
