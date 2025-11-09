import './globals.css'
import type { Metadata, Viewport } from 'next'
import { Inter } from 'next/font/google'
import { AuthProvider } from '@/lib/context/AuthContext'
import { PaymentModelProvider } from '@/lib/contexts/PaymentModelContext'
import { Toaster } from 'react-hot-toast'
import GlobalErrorBoundary from '@/components/error/GlobalErrorBoundary'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'Hobbyist Partner Portal',
  description: 'Studio management dashboard for fitness and wellness partners',
  keywords: ['fitness', 'wellness', 'studio', 'management', 'booking', 'classes'],
  authors: [{ name: 'Hobbyist Team' }],
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
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
        <GlobalErrorBoundary>
          <AuthProvider>
            <PaymentModelProvider>
              <div id="root">{children}</div>
              <div id="modal-root" />
              <Toaster
                position="top-right"
                toastOptions={{
                  duration: 4000,
                  style: {
                    background: '#363636',
                    color: '#fff',
                  },
                  success: {
                    duration: 3000,
                    iconTheme: {
                      primary: '#4ade80',
                      secondary: '#fff',
                    },
                  },
                  error: {
                    duration: 5000,
                    iconTheme: {
                      primary: '#ef4444',
                      secondary: '#fff',
                    },
                  },
                }}
              />
            </PaymentModelProvider>
          </AuthProvider>
        </GlobalErrorBoundary>
      </body>
    </html>
  )
}