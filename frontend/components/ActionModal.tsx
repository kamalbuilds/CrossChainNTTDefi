// @ts-nocheck
import React, { useEffect, useState } from "react"
import {
  useAccount,
  useSwitchChain,
  useWallets,
} from "@particle-network/connectkit"
import { Contract, ethers } from "ethers"
import {
  createThirdwebClient,
  defineChain,
  getContract,
  prepareContractCall,
} from "thirdweb"
import { useSendTransaction } from "thirdweb/react"

import { SPOKE_TOKEN_ABI } from "@/config/SpokeTokenABI"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

import { Button } from "./ui/button"
import { Input } from "./ui/input"
import { Label } from "./ui/label"

export default function ActionModal({ action, chains, updateStats }) {
  const [amount, setAmount] = useState("")
  const [selectedChain, setSelectedChain] = useState(chains[0])

  const [buttonText, setButtonText] = useState("Execute")

  const { mutate: sendTransaction } = useSendTransaction()

  const { switchChain, switchChainAsync, error, status } = useSwitchChain()
  const { chainId } = useAccount()

  const client = createThirdwebClient({
    clientId: process.env.NEXT_PUBLIC_THIRDWEB_KEY!,
  })

  const [primaryWallet] = useWallets()

  const handleSubmit = async () => {
    console.log(selectedChain, amount)

    console.log("Called submit")
    if (!selectedChain || !amount) return

    try {
      console.log("action", action, amount.toString())
      const weiAmount = ethers.parseEther(amount.toString())

      if (action === "Deposit") {
        console.log("selectedChain", selectedChain, weiAmount)

        const walletClient = primaryWallet.getWalletClient()

        const contract = new Contract(
          selectedChain?.spokeAddress,
          SPOKE_TOKEN_ABI,
          walletClient
        )

        console.log("Contract", contract)

        const tx = await contract.deposit(weiAmount)

        console.log("tx", tx)
      } else if (action === "Withdraw") {
        const walletClient = primaryWallet.getWalletClient()

        const contract = new Contract(
          selectedChain?.spokeAddress,
          SPOKE_TOKEN_ABI,
          walletClient
        )

        console.log("Contract", contract)

        const tx = await contract.requestWithdraw(weiAmount)

        console.log("tx", tx)
      } else if (action === "Borrow") {
        const walletClient = primaryWallet.getWalletClient()

        const contract = new Contract(
          selectedChain?.spokeAddress,
          SPOKE_TOKEN_ABI,
          walletClient
        )

        console.log("Contract", contract)

        const tx = await contract.requestBorrow(weiAmount)

        console.log("tx", tx)
      } else if (action === "Repay") {
        const walletClient = primaryWallet.getWalletClient()

        const contract = new Contract(
          selectedChain?.spokeAddress,
          SPOKE_TOKEN_ABI,
          walletClient
        )

        console.log("Contract", contract)

        const tx = await contract.repayBorrow(weiAmount)

        console.log("tx", tx)
      }

      updateStats(weiAmount) // Update stats after the transaction
      // setIsModalOpen(false);
    } catch (err) {
      console.error(err)
    }
  }

  const updatetheselectedchain = (value) => {
    const chain = chains.find((chain) => chain.name === value)
    setSelectedChain(chain)
  }

  const handleChainSwitch = async () => {
    if (chainId !== selectedChain.chainID) {
      console.log("Switching chain", selectedChain, chainId)
      await switchChain({ chainId: selectedChain.chainID })
      return
    }
  }

  return (
    <>
      <AlertDialog>
        <AlertDialogTrigger asChild>
          <Button variant="outline">{action}</Button>
        </AlertDialogTrigger>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{action}</AlertDialogTitle>
            <AlertDialogDescription></AlertDialogDescription>
          </AlertDialogHeader>
          <div className="modal">
            <div className="modal-content">
              <div className="mb-3">
                <Label htmlFor="amount">Amount</Label>
                <Input
                  type="number"
                  className="form-control"
                  id="amount"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="Enter amount"
                />
              </div>
              <div className="mb-3">
                <Label htmlFor="chains-dropdown">Chain</Label>
                <Select
                  onValueChange={(value) => updatetheselectedchain(value)}
                >
                  <SelectTrigger className="">
                    <SelectValue placeholder="Select Chain" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectGroup>
                      <SelectLabel>Select Chain</SelectLabel>
                      {chains.map((chain, id) => (
                        <SelectItem key={id} value={chain.name}>
                          {chain.name}
                        </SelectItem>
                      ))}
                    </SelectGroup>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            {selectedChain && selectedChain.chainID !== chainId ? (
              <Button className="btn btn-primary" onClick={handleChainSwitch}>
                Switch Chain
              </Button>
            ) : (
              <Button
                className="btn btn-primary"
                type="submit"
                onClick={handleSubmit}
              >
                Execute
              </Button>
            )}
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}
