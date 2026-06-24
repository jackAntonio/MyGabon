import type { Metadata } from "next"
import { Poppins } from "next/font/google"
import "./globals.css"
import { SessionProvider } from "next-auth/react"

const poppins = Poppins({
  subsets: ["latin"],
  weight: ["400", "600", "700"],
  variable: "--font-sans",
})

export const metadata: Metadata = {
  title: "MyGabon Admin Dashboard",
  description: "Administration dashboard for MyGabon marketplace",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={poppins.variable}>
      <body className="bg-background text-foreground">
        <SessionProvider>
          {children}
        </SessionProvider>
      </body>
    </html>
  )
}
