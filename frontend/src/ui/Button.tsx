import type { ComponentPropsWithRef } from 'react'
import { cn } from './cn'

type Variant = 'primary' | 'secondary' | 'ghost'

const VARIANTS: Record<Variant, string> = {
  primary: 'bg-venice text-white hover:bg-venice-light',
  // Sits on cream, so it needs the white fill to read as a control.
  secondary: 'bg-surface text-ink border border-divider hover:bg-chip',
  ghost: 'text-venice hover:bg-venice-pale',
}

export function Button({
  className, variant = 'primary', ...props
}: ComponentPropsWithRef<'button'> & { variant?: Variant }) {
  return (
    <button
      type="button"
      className={cn(
        'rounded-input px-5 py-3 text-sm font-medium transition-colors disabled:opacity-50',
        VARIANTS[variant],
        className,
      )}
      {...props}
    />
  )
}
