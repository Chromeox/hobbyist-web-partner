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
  Brain,
  ChevronDown,
  ChevronRight,
  Home,
  ArrowLeft
} from 'lucide-react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuthContext } from '@/lib/context/AuthContext';
import { isAdmin, isNavItemVisible } from '@/lib/utils/roleUtils';
import DashboardErrorBoundary from '@/components/error/DashboardErrorBoundary';

const navigationSections = [
  {
    id: 'core',
    label: 'Core Operations',
    icon: LayoutDashboard,
    expanded: true,
    items: [
      { id: 'overview', label: 'Overview', icon: LayoutDashboard, href: '/dashboard' },
      { id: 'classes', label: 'Classes', icon: BookOpen, href: '/dashboard/classes' },
      { id: 'reservations', label: 'Reservations', icon: Calendar, href: '/dashboard/reservations' },
      { id: 'students', label: 'Students', icon: Users, href: '/dashboard/students' },
      { id: 'locations', label: 'Locations', icon: MapPin, href: '/dashboard/locations' },
      { id: 'analytics', label: 'Analytics', icon: BarChart3, href: '/dashboard/analytics' }
    ]
  },
  {
    id: 'people',
    label: 'People Management',
    icon: Users,
    expanded: false,
    items: [
      { id: 'instructors', label: 'Instructors', icon: GraduationCap, href: '/dashboard/instructors' },
      { id: 'staff', label: 'Staff', icon: UserPlus, href: '/dashboard/staff' },
      { id: 'waitlist', label: 'Waitlist', icon: Clock, href: '/dashboard/waitlist' }
    ]
  },
  {
    id: 'financial',
    label: 'Financial',
    icon: DollarSign,
    expanded: false,
    items: [
      { id: 'credits', label: 'Pricing & Credits', icon: CreditCard, href: '/dashboard/pricing' },
      { id: 'subscriptions', label: 'Subscriptions', icon: Crown, href: '/dashboard/subscriptions' },
      { id: 'revenue', label: 'Revenue Reports', icon: TrendingUp, href: '/dashboard/revenue' }
    ]
  },
  {
    id: 'analytics',
    label: 'AI & Smart Tools',
    icon: Brain,
    expanded: false,
    items: [
      { id: 'intelligence', label: 'Smart Calendar', icon: Brain, href: '/dashboard/intelligence' },
      { id: 'reviews', label: 'Reviews', icon: Star, href: '/dashboard/reviews' }
    ]
  },
  {
    id: 'tools',
    label: 'Tools & Comms',
    icon: Zap,
    expanded: false,
    items: [
      { id: 'marketing', label: 'Marketing', icon: Megaphone, href: '/dashboard/marketing' },
      { id: 'messages', label: 'Messages', icon: MessageSquare, href: '/dashboard/messages' },
      { id: 'settings', label: 'Settings', icon: Settings, href: '/dashboard/settings' }
    ]
  },
  {
    id: 'admin',
    label: 'Admin',
    icon: Crown,
    expanded: false,
    items: [
      { id: 'instructor-approvals', label: 'Instructor Approvals', icon: Users, href: '/dashboard/admin/instructor-approvals' },
      { id: 'studio-approval', label: 'Studio Approval', icon: Building2, href: '/dashboard/admin/studio-approval' },
      { id: 'payouts', label: 'Payouts', icon: Wallet, href: '/dashboard/payouts' }
    ]
  }
];

interface DashboardLayoutProps {
  children: React.ReactNode;
  studioName?: string;
  userName?: string;
}

export default function DashboardLayout({ children, studioName = 'Your Studio', userName = 'Studio Owner' }: DashboardLayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>(() => {
    const initial: Record<string, boolean> = {};
    navigationSections.forEach(section => {
      initial[section.id] = section.expanded;
    });
    return initial;
  });
  const pathname = usePathname();
  const router = useRouter();
  const { signOut, user } = useAuthContext();

  const handleLogout = async () => {
    try {
      await signOut();
      router.push('/auth/signin');
    } catch (error) {
      console.error('Logout error:', error);
      // Still redirect even if logout fails
      router.push('/auth/signin');
    }
  };

  const toggleSection = (sectionId: string) => {
    setExpandedSections(prev => ({
      ...prev,
      [sectionId]: !prev[sectionId]
    }));
  };

  const isItemActive = (href: string) => {
    return pathname === href;
  };

  const isSectionActive = (section: any) => {
    return section.items.some((item: any) => isItemActive(item.href));
  };

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
              <Link href="/dashboard" className="flex items-center cursor-pointer hover:opacity-80 transition-opacity">
                <Building2 className="h-8 w-8 text-blue-600 mr-3" />
                <div>
                  <h2 className="text-xl font-bold text-gray-900">Hobbyist</h2>
                  <p className="text-xs text-gray-500">Partner Portal</p>
                </div>
              </Link>
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
            {navigationSections.filter(section => {
              // Hide Admin section for non-admin users
              if (section.id === 'admin' && !isAdmin(user)) return false;
              return true;
            }).map((section) => {
              const SectionIcon = section.icon;
              const isExpanded = expandedSections[section.id];
              const sectionHasActiveItem = isSectionActive(section);

              return (
                <div key={section.id} className="mb-3">
                  {/* Section Header */}
                  <button
                    onClick={() => toggleSection(section.id)}
                    className={`w-full flex items-center px-3 py-2 rounded-lg transition-colors ${
                      sectionHasActiveItem
                        ? 'bg-blue-50 text-blue-700'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <SectionIcon className={`h-4 w-4 mr-2 ${sectionHasActiveItem ? 'text-blue-700' : 'text-gray-500'}`} />
                    <span className="text-sm font-semibold">{section.label}</span>
                    <motion.div
                      animate={{ rotate: isExpanded ? 90 : 0 }}
                      transition={{ duration: 0.2 }}
                      className="ml-auto"
                    >
                      <ChevronRight className="h-4 w-4" />
                    </motion.div>
                  </button>

                  {/* Section Items */}
                  <motion.div
                    initial={false}
                    animate={{
                      height: isExpanded ? 'auto' : 0,
                      opacity: isExpanded ? 1 : 0
                    }}
                    transition={{
                      duration: 0.3,
                      ease: 'easeInOut'
                    }}
                    className="overflow-hidden"
                  >
                    <div className="pl-6 pt-1 space-y-1">
                      {section.items.map((item) => {
                        const isActive = isItemActive(item.href);
                        const ItemIcon = item.icon;

                        // Check if user has access to this item
                        const hasAccess = isNavItemVisible(user, item.id);
                        if (!hasAccess) return null;
                        
                        return (
                          <Link
                            key={item.id}
                            href={item.href}
                            className={`flex items-center px-3 py-2 rounded-lg transition-colors ${
                              isActive
                                ? 'bg-blue-100 text-blue-700'
                                : 'text-gray-700 hover:bg-gray-100'
                            }`}
                          >
                            <ItemIcon className={`h-4 w-4 mr-3 ${isActive ? 'text-blue-700' : 'text-gray-500'}`} />
                            <span className="text-sm font-medium">{item.label}</span>
                            {item.id === 'messages' && (
                              <span className="ml-auto bg-red-500 text-white text-xs px-2 py-1 rounded-full">3</span>
                            )}
                            {['payouts', 'studio-approval', 'instructor-approvals'].includes(item.id) && (
                              <span className="ml-auto bg-purple-100 text-purple-700 text-xs px-1.5 py-0.5 rounded text-[10px] font-semibold">ADMIN</span>
                            )}
                          </Link>
                        );
                      })}
                    </div>
                  </motion.div>
                </div>
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
              <div className="ml-3 flex-1 min-w-0">
                <p
                  className="text-sm font-medium text-gray-900 truncate"
                  title={userName}
                >
                  {userName}
                </p>
                <p className="text-xs text-gray-500">Admin</p>
              </div>
              <button
                onClick={handleLogout}
                className="text-gray-500 hover:text-gray-700"
                title="Sign Out"
              >
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
                
                {/* Breadcrumb Navigation */}
                <div className="flex items-center space-x-2">
                  <Link href="/dashboard" className="flex items-center text-gray-500 hover:text-gray-700 transition-colors">
                    <Home className="h-4 w-4 mr-1" />
                    <span className="text-sm">Dashboard</span>
                  </Link>
                  
                  {pathname !== '/dashboard' && (
                    <>
                      <ChevronRight className="h-4 w-4 text-gray-400" />
                      <span className="text-sm font-medium text-gray-900">
                        {(() => {
                          for (const section of navigationSections) {
                            const item = section.items.find(item => item.href === pathname);
                            if (item) return item.label;
                          }
                          return 'Page';
                        })()}
                      </span>
                    </>
                  )}
                </div>
                
                {/* Back Button */}
                {pathname !== '/dashboard' && (
                  <button
                    onClick={() => router.back()}
                    className="ml-4 flex items-center px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
                  >
                    <ArrowLeft className="h-4 w-4 mr-1" />
                    Back
                  </button>
                )}
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
          <DashboardErrorBoundary page="dashboard content">
            {children}
          </DashboardErrorBoundary>
        </main>
      </div>
    </div>
  );
}
