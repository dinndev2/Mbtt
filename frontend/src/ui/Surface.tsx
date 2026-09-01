import type { ComponentPropsWithRef, ElementType } from 'react'
import { cn } from './cn'

/**
 * White card floating on the cream screen. The default shape for a place, a
 * result row group, or any self-contained block.
 */
export function Card({ className, as, ...props }: ComponentPropsWithRef<'div'> & { as?: ElementType }) {
  const Tag = as ?? 'div'
  return <Tag className={cn('bg-surface rounded-card', className)} {...props} />
}

/**
 * An inset area *within* a card - a fare breakdown, a note, a grouped list.
 * Reads as carved into the card rather than stacked on it, so it takes no
 * shadow and no border.
 */
export function Panel({ className, tinted, ...props }: ComponentPropsWithRef<'div'> & { tinted?: boolean }) {
  return (
    <div
      className={cn(
        'rounded-panel',
        // Blue-tinted when the content is about fares or the selected island;
        // neutral otherwise.
        tinted ? 'bg-venice-pale' : 'bg-chip',
        className,
      )}
      {...props}
    />
  )
}

/**
 * Placeholder ground for an image. Sized by the caller; the fill shows while
 * the photo loads and wherever a place has no photo at all - which is most of
 * them, so this is a real state rather than a fallback.
 */
export function Well({ className, ...props }: ComponentPropsWithRef<'div'>) {
  return <div className={cn('bg-well rounded-card overflow-hidden', className)} {...props} />
}

/** The app frame itself, centred against the workspace on wide screens. */
export function Screen({ className, ...props }: ComponentPropsWithRef<'div'>) {
  return <div className={cn('bg-screen min-h-dvh mx-auto w-full max-w-md', className)} {...props} />
}
