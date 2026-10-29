import { useRef, useState, useContext } from 'react'
import { AuthContext } from '../api/AuthContext';
import { Button } from '../ui/Button';
import { Label, Muted } from '../ui';
import Places from '../Admin/Places/Places';

export default function Admin() {
  const userData = useRef<HTMLFormElement>(null)
  const auth = useContext(AuthContext)
  const user = auth?.user

  return <>
    <header className="border-b border-divider">
      <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4 px-4 py-3 sm:px-10">
        <div className="min-w-0">
          <Label>MBTT Admin</Label>
          <Muted as="p" className="truncate text-sm">{user?.email}</Muted>
        </div>
        <Button variant="secondary" className="shrink-0" onClick={ ( ) => auth?.logout() }>Log out</Button>
      </div>
    </header>
    <Places />
   </>
}

