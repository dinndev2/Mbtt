import type { ComponentPropsWithRef, ElementType } from 'react'
import { cn } from './cn'

/** Rozha One. Headlines, island names, anything meant to be looked at first. */
export function Display({
  className, as, size = 'md', ...props
}: ComponentPropsWithRef<'h2'> & { as?: ElementType; size?: 'sm' | 'md' | 'lg' | 'xl' | 'xxl' }) {
  const Tag = as ?? 'h2'
  const sizes = { sm: 'text-xl', md: 'text-2xl', lg: 'text-3xl', xl: 'text-4xl', xxl: 'text-3xl lg:text-5xl' }
  return <Tag className={cn('font-display leading-tight', sizes[size], className)} {...props} />
}

/**
 * A price. Display face in Venice Blue, because a fare is the number people
 * scan for. Pass the preformatted `label` from the API - it already handles
 * ranges and the "from" case.
 */
export function Fare({
  className, size = 'md', ...props
}: ComponentPropsWithRef<'span'> & { size?: 'sm' | 'md' | 'lg' }) {
  const sizes = { sm: 'text-base', md: 'text-xl', lg: 'text-2xl' }
  return <span className={cn('font-display text-venice tabular-nums', sizes[size], className)} {...props} />
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

/** Small uppercase label above a group. */
export function Label({ className, ...props }: ComponentPropsWithRef<'span'>) {
  return (
    <span
      className={cn('text-ink-soft text-xs font-medium uppercase tracking-wide', className)}
      {...props}
    />
  )
}
