"use client"

import Link from "next/link"
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar"
import { motion } from "framer-motion"
import { useInView } from "framer-motion"
import { useRef } from "react"

const fadeIn = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 }
}

const staggerChildren = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.2
    }
  }
}

export default function Component() {
  const ref = useRef(null)
  const isInView = useInView(ref)

  return (
    <div className="flex min-h-dvh flex-col bg-gradient-to-b from-background to-muted">
      <main className="flex-1">
        <section className="w-full py-12 md:py-24 lg:py-32 xl:py-48 overflow-hidden">
          <div className="container px-4 md:px-6">
            <div className="grid gap-6 lg:grid-cols-[1fr_550px] lg:gap-12 xl:grid-cols-[1fr_650px]">
              <motion.div 
                className="flex flex-col justify-center space-y-4"
                initial="hidden"
                animate="visible"
                variants={fadeIn}
                transition={{ duration: 0.6 }}
              >
                <div className="space-y-2">
                  <h1 className="text-4xl font-bold tracking-tighter sm:text-6xl xl:text-7xl/none bg-gradient-to-r from-primary to-primary/50 bg-clip-text text-transparent">
                    Cross-Chain DeFi Revolution
                  </h1>
                  <p className="text-muted-foreground max-w-[600px] md:text-xl leading-relaxed">
                    Experience the future of DeFi with our revolutionary Hub and Spoke model. 
                    Seamlessly manage your assets across Ethereum, Arbitrum, Optimism, and Base networks.
                  </p>
                </div>
                <motion.div 
                  className="flex flex-col gap-2 min-[400px]:flex-row"
                  whileHover={{ scale: 1.02 }}
                >
                  <Link
                    href="/defi"
                    className="bg-primary text-primary-foreground hover:bg-primary/90 focus-visible:ring-ring inline-flex h-12 items-center justify-center rounded-md px-8 text-sm font-medium shadow-lg transition-all hover:shadow-xl focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50"
                    prefetch={false}
                  >
                    Launch App →
                  </Link>
                </motion.div>
              </motion.div>
              <motion.div 
                className="relative"
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.8 }}
              >
                <div className="absolute left-1/2 top-1/2 grid -translate-x-1/2 -translate-y-1/2 grid-cols-2 gap-8">
                  {[
                    { Icon: LendIcon, text: "Lend", delay: 0 },
                    { Icon: DepositIcon, text: "Deposit", delay: 0.2 },
                    { Icon: RepayIcon, text: "Repay", delay: 0.4 },
                    { Icon: RedeemIcon, text: "Redeem", delay: 0.6 }
                  ].map(({ Icon, text, delay }, index) => (
                    <motion.div
                      key={text}
                      className="flex flex-col items-center justify-center bg-background/50 backdrop-blur-sm p-6 rounded-xl shadow-lg hover:shadow-xl transition-all"
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay, duration: 0.5 }}
                      whileHover={{ scale: 1.05 }}
                    >
                      <Icon className="text-primary size-12" />
                      <span className="mt-2 text-sm font-medium">{text}</span>
                    </motion.div>
                  ))}
                </div>
              </motion.div>
            </div>
          </div>
        </section>

        <motion.section 
          ref={ref}
          className="w-full py-24 bg-gradient-to-b from-muted to-background"
          initial="hidden"
          animate={isInView ? "visible" : "hidden"}
          variants={staggerChildren}
        >
          <div className="container px-4 md:px-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
              <motion.div 
                className="bg-background rounded-xl p-6 shadow-lg"
                variants={fadeIn}
                whileHover={{ scale: 1.02 }}
              >
                <h3 className="text-2xl font-bold mb-4 bg-gradient-to-r from-primary to-primary/50 bg-clip-text text-transparent">Lend on Ethereum</h3>
                <p className="text-muted-foreground">Deploy your assets on Ethereum mainnet with industry-leading security and competitive yields.</p>
              </motion.div>

              <motion.div 
                className="bg-background rounded-xl p-6 shadow-lg"
                variants={fadeIn}
                whileHover={{ scale: 1.02 }}
              >
                <h3 className="text-2xl font-bold mb-4 bg-gradient-to-r from-primary to-primary/50 bg-clip-text text-transparent">Deposit on Arbitrum</h3>
                <p className="text-muted-foreground">Take advantage of Arbitrum's low fees and fast transactions while earning yields.</p>
              </motion.div>

              <motion.div 
                className="bg-background rounded-xl p-6 shadow-lg"
                variants={fadeIn}
                whileHover={{ scale: 1.02 }}
              >
                <h3 className="text-2xl font-bold mb-4 bg-gradient-to-r from-primary to-primary/50 bg-clip-text text-transparent">Repay on Optimism</h3>
                <p className="text-muted-foreground">Manage your loans efficiently with Optimism's lightning-fast confirmations.</p>
              </motion.div>

              <motion.div 
                className="bg-background rounded-xl p-6 shadow-lg"
                variants={fadeIn}
                whileHover={{ scale: 1.02 }}
              >
                <h3 className="text-2xl font-bold mb-4 bg-gradient-to-r from-primary to-primary/50 bg-clip-text text-transparent">Redeem on Base</h3>
                <p className="text-muted-foreground">Experience seamless redemptions with Base's optimized infrastructure.</p>
              </motion.div>
            </div>
          </div>
        </motion.section>

        <motion.section 
          className="w-full py-24 bg-muted"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={staggerChildren}
        >
          <div className="container px-4 md:px-6">
            <motion.div 
              className="text-center mb-12"
              variants={fadeIn}
            >
              <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl mb-4">Community Testimonials</h2>
              <p className="text-muted-foreground text-lg">Join thousands of users already benefiting from our cross-chain solutions.</p>
            </motion.div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {[
                {
                  name: "Alex Thompson",
                  role: "DeFi Strategist",
                  text: "The cross-chain capabilities have revolutionized my DeFi strategy. I can now optimize yields across multiple networks without the usual complexity.",
                  initials: "AT"
                },
                {
                  name: "Sarah Wu",
                  role: "Crypto Researcher",
                  text: "Finally, a platform that makes cross-chain DeFi accessible. The Hub and Spoke model is brilliantly implemented.",
                  initials: "SW"
                },
                {
                  name: "Michael Chen",
                  role: "Portfolio Manager",
                  text: "The seamless integration between chains and the intuitive interface make this platform stand out in the crowded DeFi space.",
                  initials: "MC"
                }
              ].map((testimonial, index) => (
                <motion.div
                  key={testimonial.name}
                  className="bg-background rounded-xl p-8 shadow-lg"
                  variants={fadeIn}
                  whileHover={{ scale: 1.02 }}
                  transition={{ delay: index * 0.2 }}
                >
                  <div className="flex items-center gap-4 mb-4">
                    <Avatar className="h-12 w-12">
                      <AvatarFallback className="bg-primary/10">{testimonial.initials}</AvatarFallback>
                    </Avatar>
                    <div>
                      <h4 className="font-semibold">{testimonial.name}</h4>
                      <p className="text-sm text-muted-foreground">{testimonial.role}</p>
                    </div>
                  </div>
                  <p className="text-muted-foreground italic">{testimonial.text}</p>
                </motion.div>
              ))}
            </div>
          </div>
        </motion.section>

        <motion.section 
          className="w-full py-24 bg-background"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={fadeIn}
        >
          <div className="container px-4 md:px-6 text-center">
            <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl mb-4">Ready to Get Started?</h2>
            <p className="text-muted-foreground text-lg mb-8">Join the future of cross-chain DeFi today.</p>
            <motion.div whileHover={{ scale: 1.02 }}>
              <Link
                href="/defi"
                className="bg-primary text-primary-foreground hover:bg-primary/90 inline-flex h-12 items-center justify-center rounded-md px-8 text-sm font-medium shadow-lg transition-all hover:shadow-xl"
                prefetch={false}
              >
                Launch App →
              </Link>
            </motion.div>
          </div>
        </motion.section>
      </main>
      <footer className="w-full border-t px-4 py-6 bg-background">
        <div className="container flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-muted-foreground text-sm">&copy; 2025 CrossChain DeFi. All rights reserved.</p>
          <div className="flex gap-4">
            <Link href="/terms" className="text-sm text-muted-foreground hover:text-primary">Terms</Link>
            <Link href="/privacy" className="text-sm text-muted-foreground hover:text-primary">Privacy</Link>
            <Link href="/docs" className="text-sm text-muted-foreground hover:text-primary">Docs</Link>
          </div>
        </div>
      </footer>
    </div>
  )
}

function LendIcon(props: any) {
  return (
    <svg
      {...props}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M22 2L13.8 10.2"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M13 7.8L13.8 10.2L16.2 11"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M9 13.5V10.5C9 9.67157 9.67157 9 10.5 9H13.5C14.3284 9 15 9.67157 15 10.5V13.5C15 14.3284 14.3284 15 13.5 15H10.5C9.67157 15 9 14.3284 9 13.5Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function DepositIcon(props: any) {
  return (
    <svg
      {...props}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M4 10C4 10 5.6 15.5 12 15.5C18.4 15.5 20 10 20 10"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M12 3V15"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M8 13L12 17L16 13"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M20 21H4"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function RepayIcon(props: any) {
  return (
    <svg
      {...props}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M2 9V6.5C2 4.01 4.01 2 6.5 2H9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M15 2H17.5C19.99 2 22 4.01 22 6.5V9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M22 16V17.5C22 19.99 19.99 22 17.5 22H16"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M9 22H6.5C4.01 22 2 19.99 2 17.5V15"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M10.5 7V9C10.5 9.82843 11.1716 10.5 12 10.5H14C14.8284 10.5 15.5 11.1716 15.5 12V14C15.5 14.8284 14.8284 15.5 14 15.5H12C11.1716 15.5 10.5 16.1716 10.5 17V17.5"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function RedeemIcon(props: any) {
  return (
    <svg
      {...props}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12 3V7M12 7L9 4M12 7L15 4"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M12 21V17M12 17L9 20M12 17L15 20"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M17 12H21M21 12L18 9M21 12L18 15"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M7 12H3M3 12L6 9M3 12L6 15"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle
        cx="12"
        cy="12"
        r="3"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}
