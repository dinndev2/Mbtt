/**
 * Joins class names, dropping falsey ones. Later classes win only if they come
 * later in the stylesheet, so pass overrides last and avoid fighting the same
 * property twice on one element.
 */
export function cn(...parts: Array<string | false | null | undefined>) {
  return parts.filter(Boolean).join(' ')
}
