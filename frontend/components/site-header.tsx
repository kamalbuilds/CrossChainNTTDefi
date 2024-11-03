import { createThirdwebClient } from "thirdweb"

import { siteConfig } from "@/config/site"
import { MainNav } from "@/components/main-nav"
import { ThemeToggle } from "@/components/theme-toggle"

import ParticleConnect from "./ParticleNetwork/ParticleConnect"

export function SiteHeader() {
  const client = createThirdwebClient({
    clientId: process.env.NEXT_PUBLIC_THIRDWEB_KEY!,
  })
  return (
    <header className="sticky top-0 z-40 w-full border-b bg-background">
      <div className="container flex h-16 items-center space-x-4 sm:justify-between sm:space-x-0">
        <MainNav items={siteConfig.mainNav} />
        <div className="flex flex-1 items-center justify-end space-x-4">
          <nav className="flex items-center space-x-1">
            <ThemeToggle />
            <ParticleConnect />
            {/* <ConnectButton client={client} /> */}
          </nav>
        </div>
      </div>
    </header>
  )
}
