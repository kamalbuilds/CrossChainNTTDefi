"use client"

import { SiteHeader } from "./site-header"
import { TailwindIndicator } from "./tailwind-indicator"
import { ClientProviders } from "./client-providers"

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ClientProviders>
      <div className="relative flex min-h-screen flex-col">
        <SiteHeader />
        <div className="flex-1">{children}</div>
      </div>
      <TailwindIndicator />
    </ClientProviders>
  )
} 