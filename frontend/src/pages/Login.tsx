import { useState, useRef, useContext, useEffect } from 'react'
import { AuthContext } from '../api/AuthContext'
import { Button, Card, Display, Divider, Input, Label, LoaderDots, Muted } from '../ui'
import { replace, useNavigate } from 'react-router'

const ACCESS_EMAIL = 'dinndev@gmail.com'
const ACCESS_SUBJECT = 'MBTT admin access request'
const ACCESS_BODY = `Hi,

I'd like admin access to MBTT.

Name:
Email to sign in with:
What I'd like to update (fares, terminals, crossings, places):
How I know the info (e.g. local, operator, frequent traveller):

Thanks!`

const requestAccessHref = `mailto:${ACCESS_EMAIL}?subject=${encodeURIComponent(ACCESS_SUBJECT)}&body=${encodeURIComponent(ACCESS_BODY)}`

export default function Login() {
  const navigate = useNavigate()
  const userData = useRef<HTMLFormElement>(null)
  const auth = useContext(AuthContext)
  const [submitting, setSubmitting] = useState(false)
 
  async function submitSession (e: React.SubmitEvent) {
    e.preventDefault()
    const form = userData.current
    if(!form) return
    const user = new FormData(form)
    const email = user.get('email')
    const password = user.get('password')
    if(typeof email !== 'string' || !email) return
    if(typeof password !== 'string' || !password) return
    setSubmitting(true)
    try {
      await auth?.login(email, password)
      navigate("/admin", {replace: true})
    } catch {
      // login already put the message in auth.error
    } finally {
      setSubmitting(false)
    }
  }

  return <div className="mx-auto flex min-h-dvh w-full max-w-7xl flex-col items-center justify-center px-4 py-8 sm:p-10">
    <Card className="w-full max-w-md p-6 sm:p-8">
        <Display as="h1" size="lg" className="mt-2">
          Sign <em>in</em>
        </Display>
        <Muted className="mt-2">
          For keeping fares, terminals and crossings up to date.
        </Muted>
        <form ref={userData} onSubmit={submitSession} className="mt-6 flex flex-col gap-4">
          <label className="flex flex-col gap-2">
            <Label>Email</Label>
            <Input name="email" type="email" autoComplete="email" required />
          </label>
          <label className="flex flex-col gap-2">
            <Label>Password</Label>
            <Input name="password" type="password" autoComplete="current-password" required />
          </label>
          {auth?.error && <p role="alert" className="rounded-panel border border-sun bg-sun-pale px-4 py-3 text-sm text-ink">{auth.error.details}</p>}
          <Button type="submit" className="mt-2 inline-flex w-full items-center justify-center gap-2" disabled={submitting}>
            {submitting ? <>Signing in <LoaderDots /></> : 'Sign in'}
          </Button>
        </form>
        <Divider className="mx-0 my-6" />
        <Muted>Don't have an account?</Muted>
        <a
          href={requestAccessHref}
          className="rounded-pill mt-3 block w-full border-[1.5px] border-venice bg-surface px-5 py-3 text-center text-sm font-semibold text-venice transition-colors hover:bg-venice hover:text-surface"
        >
          Request access
        </a>

    </Card>
  </div>
}
