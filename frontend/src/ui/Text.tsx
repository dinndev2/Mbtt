import type { ComponentPropsWithRef, ElementType } from 'react'
import { cn } from './cn'

/** Instrument Serif in ink blue. Headlines, island names, anything meant to be looked at first. */
export function Display({
  className, as, size = 'md', ...props
}: ComponentPropsWithRef<'h2'> & { as?: ElementType; size?: 'sm' | 'md' | 'lg' | 'xl' | 'xxl' }) {
  const Tag = as ?? 'h2'
  // A size up from a sans scale: the serif is narrow and light, and reads
  // small at the same pixel size.
  const sizes = { sm: 'text-2xl', md: 'text-3xl', lg: 'text-4xl', xl: 'text-5xl', xxl: 'text-5xl lg:text-7xl' }
  return <Tag className={cn('font-display text-venice leading-[0.95] tracking-tight', sizes[size], className)} {...props} />
}

/**
 * A price. Display face in ink blue, because a fare is the number people
 * scan for. Pass the preformatted `label` from the API - it already handles
 * ranges and the "from" case.
 */
export function Fare({
  className, size = 'md', weight, highlight, ...props
}: ComponentPropsWithRef<'span'> & {
  size?: 'sm' | 'md' | 'lg'
  weight?: 'font-medium' | 'font-bold'
  /** Marker-pen highlight in sun yellow - the same pair as ::selection. */
  highlight?: boolean
}) {
  const sizes = { sm: 'text-xl', md: 'text-3xl', lg: 'text-4xl' }
  return <span
    className={cn(
      'font-display text-venice tabular-nums leading-none',
      highlight && 'bg-sun text-venice-deep px-1.5 py-0.5 box-decoration-clone',
      weight,
      sizes[size],
      className,
    )}
    {...props}
  />
}

/**
 * Secondary copy. Ink at 73%, never a separate grey.
 *
 * `as` exists for the same reason it does on Display: a button may only hold
 * phrasing content, so a blurb inside one has to render as a span.
 */
export function Muted({
  className, as, size = 'sm', ...props
}: ComponentPropsWithRef<'p'> & { as?: ElementType; size?: 'sm' | 'md' | 'lg' | 'xl' }) {
  const Tag = as ?? 'p'
  const sizes = { sm: 'text-base', md: 'text-md', lg: 'text-lg', xl: 'text-xl' }
  return <Tag className={cn('text-ink-soft text-sm font-light leading-relaxed', className, sizes[size])} {...props} />
}

/** Small uppercase label above a group - the portfolio's mono label. */
export function Label({ className,  weight = 'font-medium', ...props }: ComponentPropsWithRef<'span'> & { weight?: 'font-bold' | 'font-medium' }) {

  return (
    <span
      className={cn(`text-venice font-mono text-xs ${weight} uppercase tracking-[0.12em]`, className)}
      {...props}
    />
  )
}
