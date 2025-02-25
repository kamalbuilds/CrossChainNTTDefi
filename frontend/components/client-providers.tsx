"use client"

import { ThemeProvider } from "@/components/theme-provider"
import dynamic from 'next/dynamic'

const ParticleConnectkit = dynamic(
  () => import('@/app/ParticleProvider').then(mod => mod.ParticleConnectkit),
  { ssr: false }
)

const ThirdwebProvider = dynamic(
  () => import('thirdweb/react').then(mod => mod.ThirdwebProvider),
  { ssr: false }
)

export function ClientProviders({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <ParticleConnectkit>
        <ThirdwebProvider>
          {children}
        </ThirdwebProvider>
      </ParticleConnectkit>
    </ThemeProvider>
  )
}