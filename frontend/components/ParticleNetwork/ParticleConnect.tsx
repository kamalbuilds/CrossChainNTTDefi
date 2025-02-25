"use client"

import React from "react"
import { ConnectButton, useAccount } from "@particle-network/connectkit"

const ParticleConnect = () => {
  const { address, isConnected, chainId } = useAccount()
  return (
    <div>
      <ConnectButton />
    </div>
  )
}

export default ParticleConnect
