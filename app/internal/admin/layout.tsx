/**
 * Admin Portal Layout
 *
 * Dedicated layout for admin-only features
 * - Separate navigation from studio dashboard
 * - Platform-wide oversight tools
 * - Clean, professional admin UI
 */

'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuthContext } from '@/lib/context/AuthContext';
import {
  LayoutDashboard,
  Building2,
  Users,
  DollarSign,
  TrendingUp,
  Settings,
  CreditCard,
  Menu,
  X,
  LogOut,
  Shield,
} from 'lucide-react';

interface AdminNavItem {
  id: string;
  label: string;
  href: string;
  icon: React.ElementType;
  badge?: number;
}

const adminNavItems: AdminNavItem[] = [
  {
    id: 'overview',
    label: 'Platform Overview',
    href: '/internal/admin',
    icon: LayoutDashboard,
  },
  {
    id: 'studios',
    label: 'Studios',
    href: '/internal/admin/studios',
    icon: Building2,
  },
  {
    id: 'instructors',
    label: 'Instructors',
    href: '/internal/admin/instructors',
    icon: Users,
  },
  {
    id: 'payouts',
    label: 'Payouts',
    href: '/internal/admin/payouts',
    icon: DollarSign,
  },
  {
    id: 'revenue',
    label: 'Revenue Analytics',
    href: '/internal/admin/revenue',
    icon: TrendingUp,
  },
  {
    id: 'stripe',
    label: 'Stripe Connect',
    href: '/internal/admin/stripe',
    icon: CreditCard,
  },
  {
    id: 'settings',
    label: 'Settings',
    href: '/internal/admin/settings',
    icon: Settings,
  },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, signOut } = useAuthContext();
  const pathname = usePathname();
  const router = useRouter();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const handleSignOut = async () => {
    await signOut();
    router.push('/auth/signin');
  };

  return (
    <>
      {/* SEO Protection */}
      <head>
        <meta name="robots" content="noindex, nofollow" />
        <meta name="googlebot" content="noindex, nofollow" />
      </head>

      <div className="min-h-screen bg-gray-50">
        {/* Top Bar */}
        <div className="bg-white border-b border-gray-200 sticky top-0 z-50">
          <div className="flex items-center justify-between px-4 py-3">
            <div className="flex items-center space-x-4">
              {/* Mobile menu button */}
              <button
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                className="lg:hidden p-2 rounded-md hover:bg-gray-100"
              >
                {isMobileMenuOpen ? (
                  <X className="h-6 w-6" />
                ) : (
                  <Menu className="h-6 w-6" />
                )}
              </button>

              {/* Logo/Title */}
              <div className="flex items-center space-x-2">
                <Shield className="h-6 w-6 text-blue-600" />
                <h1 className="text-xl font-bold text-gray-900">
                  Hobbyist Admin
                </h1>
              </div>
            </div>

            {/* User Menu */}
            <div className="flex items-center space-x-4">
              <div className="hidden sm:block text-right">
                <p className="text-sm font-medium text-gray-900">{user?.name || user?.email}</p>
                <p className="text-xs text-gray-500 flex items-center justify-end">
                  <Shield className="h-3 w-3 mr-1" />
                  Administrator
                </p>
              </div>
              <button
                onClick={handleSignOut}
                className="p-2 rounded-md hover:bg-gray-100 text-gray-600 hover:text-gray-900"
                title="Sign Out"
              >
                <LogOut className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>

        <div className="flex">
          {/* Sidebar Navigation */}
          <aside
            className={`
              fixed lg:static inset-y-0 left-0 z-40
              w-64 bg-white border-r border-gray-200
              transform transition-transform duration-200 ease-in-out
              lg:transform-none
              ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
            `}
            style={{ top: '64px' }}
          >
            <nav className="p-4 space-y-1">
              {adminNavItems.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href || pathname?.startsWith(item.href + '/');

                return (
                  <Link
                    key={item.id}
                    href={item.href}
                    onClick={() => setIsMobileMenuOpen(false)}
                    className={`
                      flex items-center space-x-3 px-3 py-2 rounded-lg
                      transition-colors duration-150
                      ${
                        isActive
                          ? 'bg-blue-50 text-blue-700 font-medium'
                          : 'text-gray-700 hover:bg-gray-50'
                      }
                    `}
                  >
                    <Icon className={`h-5 w-5 ${isActive ? 'text-blue-700' : 'text-gray-500'}`} />
                    <span>{item.label}</span>
                    {item.badge !== undefined && item.badge > 0 && (
                      <span className="ml-auto bg-red-500 text-white text-xs font-bold px-2 py-1 rounded-full">
                        {item.badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </nav>
          </aside>

          {/* Mobile overlay */}
          {isMobileMenuOpen && (
            <div
              className="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
              onClick={() => setIsMobileMenuOpen(false)}
            />
          )}

          {/* Main Content */}
          <main className="flex-1 p-6 lg:p-8">
            <div className="max-w-7xl mx-auto">
              {children}
            </div>
          </main>
        </div>
      </div>
    </>
  );
}
