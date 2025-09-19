'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  LayoutDashboard,
  Calendar,
  Users,
  BookOpen,
  TrendingUp,
  Settings,
  Bell,
  Menu,
  X,
  LogOut,
  Building2,
  DollarSign,
  MessageSquare,
  BarChart3,
  Clock,
  Star,
  UserPlus,
  CreditCard,
  Megaphone,
  Zap,
  MapPin,
  GraduationCap,
  Crown,
  Wallet,
  MessageCircle,
  Brain
} from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

const navigationItems = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard, href: '/dashboard' },
  { id: 'locations', label: 'Locations', icon: MapPin, href: '/dashboard/locations' },
  { id: 'classes', label: 'Classes', icon: BookOpen, href: '/dashboard/classes' },
  { id: 'instructors', label: 'Instructors', icon: GraduationCap, href: '/dashboard/instructors' },
  { id: 'reservations', label: 'Reservations', icon: Calendar, href: '/dashboard/reservations' },
  { id: 'waitlist', label: 'Waitlist', icon: Clock, href: '/dashboard/waitlist' },
  { id: 'students', label: 'Students', icon: Users, href: '/dashboard/students' },
  { id: 'reviews', label: 'Reviews', icon: Star, href: '/dashboard/reviews' },
  { id: 'staff', label: 'Staff', icon: UserPlus, href: '/dashboard/staff' },
  { id: 'credits', label: 'Credits & Payments', icon: CreditCard, href: '/dashboard/pricing' },
  { id: 'subscriptions', label: 'Subscriptions', icon: Crown, href: '/dashboard/subscriptions' },
  { id: 'payouts', label: 'Payouts', icon: Wallet, href: '/dashboard/payouts' },
  
  { id: 'analytics', label: 'Analytics', icon: BarChart3, href: '/dashboard/analytics' },
  { id: 'intelligence', label: 'Studio Intelligence', icon: Brain, href: '/dashboard/intelligence' },
  { id: 'revenue', label: 'Revenue', icon: DollarSign, href: '/dashboard/revenue' },
  { id: 'marketing', label: 'Marketing', icon: Megaphone, href: '/dashboard/marketing' },
  { id: 'messages', label: 'Messages', icon: MessageSquare, href: '/dashboard/messages' },
  { id: 'settings', label: 'Settings', icon: Settings, href: '/dashboard/settings' },
  // Admin Section
  { id: 'instructor-approvals', label: 'Instructor Approvals', icon: Users, href: '/dashboard/admin/instructor-approvals' }
];

interface DashboardLayoutProps {
  children: React.ReactNode;
  studioName?: string;
  userName?: string;
}

export default function DashboardLayout({ children, studioName = 'Your Studio', userName = 'Studio Owner' }: DashboardLayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const pathname = usePathname();

  const notifications = [
    { id: 1, type: 'booking', message: 'New booking for Yoga Class', time: '5 min ago' },
    { id: 2, type: 'review', message: 'New 5-star review received', time: '1 hour ago' },
    { id: 3, type: 'staff', message: 'Staff member accepted invitation', time: '3 hours ago' }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar with Glassmorphism */}
      <div className={`fixed inset-y-0 left-0 z-50 w-64 glass-sidebar shadow-xl transform transition-transform duration-300 ${
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      } lg:translate-x-0`}>
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="px-6 py-6 border-b">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <Building2 className="h-8 w-8 text-blue-600 mr-3" />
                <div>
                  <h2 className="text-xl font-bold text-gray-900">Hobbyist</h2>
                  <p className="text-xs text-gray-500">Partner Portal</p>
                </div>
              </div>
              <button
                onClick={() => setSidebarOpen(false)}
                className="lg:hidden"
              >
                <X className="h-6 w-6 text-gray-500" />
              </button>
            </div>
          </div>

          {/* Studio Info with Glass Effect */}
          <div className="px-6 py-4 border-b glass-blue">
            <h3 className="font-semibold text-gray-900">{studioName}</h3>
            <p className="text-sm text-gray-600 mt-1">Premium Partner</p>
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-4 py-4 overflow-y-auto">
            {navigationItems.map((item) => {
              const isActive = pathname === item.href;
              const Icon = item.icon;
              
              return (
                <Link
                  key={item.id}
                  href={item.href}
                  className={`flex items-center px-4 py-3 mb-2 rounded-lg transition-colors ${
                    isActive
                      ? 'bg-blue-100 text-blue-700'
                      : 'text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  <Icon className={`h-5 w-5 mr-3 ${isActive ? 'text-blue-700' : 'text-gray-500'}`} />
                  <span className="font-medium">{item.label}</span>
                  {item.id === 'messages' && (
                    <span className="ml-auto bg-red-500 text-white text-xs px-2 py-1 rounded-full">3</span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* User Menu */}
          <div className="px-4 py-4 border-t">
            <div className="flex items-center px-4 py-3">
              <div className="flex-shrink-0">
                <div className="h-10 w-10 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold">
                  {userName.charAt(0).toUpperCase()}
                </div>
              </div>
              <div className="ml-3 flex-1">
                <p className="text-sm font-medium text-gray-900">{userName}</p>
                <p className="text-xs text-gray-500">Admin</p>
              </div>
              <button className="text-gray-500 hover:text-gray-700">
                <LogOut className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="lg:pl-64">
        {/* Top Bar with Glassmorphism */}
        <header className="glass-nav sticky top-0 z-40">
          <div className="px-4 sm:px-6 lg:px-8 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <button
                  onClick={() => setSidebarOpen(true)}
                  className="lg:hidden mr-4"
                >
                  <Menu className="h-6 w-6 text-gray-600" />
                </button>
                <h1 className="text-2xl font-bold text-gray-900">
                  {navigationItems.find(item => item.href === pathname)?.label || 'Dashboard'}
                </h1>
              </div>

              <div className="flex items-center space-x-4">
                {/* Quick Stats */}
                <div className="hidden md:flex items-center space-x-6">
                  <div className="text-sm">
                    <span className="text-gray-500">Today's Revenue:</span>
                    <span className="ml-2 font-semibold text-green-600">$1,234</span>
                  </div>
                  <div className="text-sm">
                    <span className="text-gray-500">Active Classes:</span>
                    <span className="ml-2 font-semibold text-blue-600">12</span>
                  </div>
                </div>

                {/* Notifications */}
                <div className="relative">
                  <button
                    onClick={() => setNotificationsOpen(!notificationsOpen)}
                    className="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg"
                  >
                    <Bell className="h-6 w-6" />
                    <span className="absolute top-0 right-0 h-2 w-2 bg-red-500 rounded-full"></span>
                  </button>

                  {notificationsOpen && (
                    <motion.div
                      initial={{ opacity: 0, y: -10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-xl border z-50"
                    >
                      <div className="p-4 border-b">
                        <h3 className="font-semibold text-gray-900">Notifications</h3>
                      </div>
                      <div className="max-h-96 overflow-y-auto">
                        {notifications.map(notification => (
                          <div key={notification.id} className="px-4 py-3 hover:bg-gray-50 border-b last:border-b-0">
                            <p className="text-sm text-gray-900">{notification.message}</p>
                            <p className="text-xs text-gray-500 mt-1">{notification.time}</p>
                          </div>
                        ))}
                      </div>
                      <div className="p-3 border-t">
                        <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                          View all notifications
                        </button>
                      </div>
                    </motion.div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="p-4 sm:p-6 lg:p-8">
          {children}
        </main>
      </div>
    </div>
  );
}
