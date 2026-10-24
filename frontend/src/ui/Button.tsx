import type { ComponentPropsWithRef } from 'react'
import { cn } from './cn'

type Variant = 'primary' | 'secondary' | 'ghost'

// The portfolio's buttons: solid ink that deepens on hover, and an outlined
// paper pill that fills with ink.
const VARIANTS: Record<Variant, string> = {
  primary: 'bg-venice text-surface hover:bg-venice-deep',
  secondary: 'bg-surface text-venice border-[1.5px] border-venice hover:bg-venice hover:text-surface',
  ghost: 'text-venice hover:bg-venice-pale',
}

export function Button({
  className, variant = 'primary', ...props
}: ComponentPropsWithRef<'button'> & { variant?: Variant }) {
  return (
    <button
      type="button"
      className={cn(
        'cursor-pointer rounded-pill px-5 py-3 text-sm font-semibold transition-colors disabled:opacity-50 disabled:pointer-events-none',
        VARIANTS[variant],
        className,
      )}
      {...props}
    />
  )
}
