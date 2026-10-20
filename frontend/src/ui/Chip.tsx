import type { ComponentPropsWithRef } from 'react'
import { cn } from './cn'

/**
 * A filter or tag pill - the portfolio's `.pill`. Outlined in ink, and
 * `active` fills it. Use it for the selected category, mode, or party size.
 */
export function Chip({
  className, active, ...props
}: ComponentPropsWithRef<'button'> & { active?: boolean }) {
  return (
    <button
      type="button"
      aria-pressed={active}
      className={cn(
        'rounded-pill border-[1.5px] border-venice px-4 py-1.5 text-sm font-semibold transition-colors self-start',
        active ? 'bg-venice text-surface' : 'bg-surface text-venice hover:bg-venice hover:text-surface',
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
        'rounded-pill border-[1.5px] border-venice font-display px-5 py-2 text-xl capitalize transition-colors',
        selected ? 'bg-venice text-surface' : 'bg-surface text-venice hover:bg-venice hover:text-surface',
        className,
      )}
      {...props}
    />
  )
}

/**
 * A non-interactive tag - a category on a place card, a confidence marker.
 * The portfolio's `.tag-pill`: mono, hairline-outlined, so it reads as a
 * label rather than something to press.
 */
export function Tag({ className, tinted, ...props }: ComponentPropsWithRef<'span'> & { tinted?: boolean }) {
  return (
    <span
      className={cn(
        'rounded-pill inline-flex items-center border px-2.5 py-0.5 font-mono text-[11px] font-medium tracking-wide',
        tinted ? 'border-venice/40 bg-venice-pale text-venice' : 'border-divider bg-surface text-ink-soft',
        className,
      )}
      {...props}
    />
  )
}
