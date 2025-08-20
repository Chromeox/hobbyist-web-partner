import './globals.css'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { AuthProvider } from '@/lib/context/AuthContext'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Hobbyist Partner Portal',
  description: 'Studio management dashboard for fitness and wellness partners',
  keywords: ['fitness', 'wellness', 'studio', 'management', 'booking', 'classes'],
  authors: [{ name: 'Hobbyist Team' }],
  viewport: 'width=device-width, initial-scale=1',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/favicon.ico" />
        <meta name="theme-color" content="#3b82f6" />
      </head>
      <body className={inter.className}>
        <AuthProvider>
          <div id="root">{children}</div>
          <div id="modal-root" />
        </AuthProvider>
      </body>
    </html>
  )
}