/**
 * Icon utilities for optimized loading
 * This helps reduce bundle size by importing only used icons
 */

import React, { lazy } from 'react';
import type { LucideIcon } from 'lucide-react';

// Core icons that are used throughout the app (always loaded)
export {
  // Navigation
  LayoutDashboard,
  Calendar,
  Users,
  BookOpen,
  Settings,
  
  // Actions
  Search,
  Filter,
  Plus,
  Edit3,
  Trash2,
  RefreshCw,
  
  // Status
  CheckCircle,
  XCircle,
  AlertCircle,
  AlertTriangle,
  Loader2,
  
  // UI
  ChevronRight,
  ChevronDown,
  ChevronLeft,
  ArrowLeft,
  Home,
  Menu,
  X,
  
  // Communication
  Mail,
  Phone,
  MessageSquare,
} from 'lucide-react';

// Lazy-loaded icons for specific features
export const LazyIcons = {
  // Financial icons
  DollarSign: lazy(() => import('lucide-react').then(mod => ({ default: mod.DollarSign }))),
  CreditCard: lazy(() => import('lucide-react').then(mod => ({ default: mod.CreditCard }))),
  TrendingUp: lazy(() => import('lucide-react').then(mod => ({ default: mod.TrendingUp }))),
  TrendingDown: lazy(() => import('lucide-react').then(mod => ({ default: mod.TrendingDown }))),
  Wallet: lazy(() => import('lucide-react').then(mod => ({ default: mod.Wallet }))),
  
  // Analytics icons
  BarChart3: lazy(() => import('lucide-react').then(mod => ({ default: mod.BarChart3 }))),
  Activity: lazy(() => import('lucide-react').then(mod => ({ default: mod.Activity }))),
  Target: lazy(() => import('lucide-react').then(mod => ({ default: mod.Target }))),
  
  // Admin icons
  Crown: lazy(() => import('lucide-react').then(mod => ({ default: mod.Crown }))),
  Shield: lazy(() => import('lucide-react').then(mod => ({ default: mod.Shield }))),
  
  // Social icons
  Star: lazy(() => import('lucide-react').then(mod => ({ default: mod.Star }))),
  Heart: lazy(() => import('lucide-react').then(mod => ({ default: mod.Heart }))),
  Share: lazy(() => import('lucide-react').then(mod => ({ default: mod.Share }))),
  
  // Media icons
  Image: lazy(() => import('lucide-react').then(mod => ({ default: mod.Image }))),
  Video: lazy(() => import('lucide-react').then(mod => ({ default: mod.Video }))),
  Upload: lazy(() => import('lucide-react').then(mod => ({ default: mod.Upload }))),
  Download: lazy(() => import('lucide-react').then(mod => ({ default: mod.Download }))),
};

/**
 * Utility to create icon components with fallbacks
 */
export function createIconComponent(IconComponent: any, fallbackName: string) {
  return function Icon({ className, ...props }: { className?: string; [key: string]: any }) {
    return React.createElement(IconComponent, {
      className,
      'aria-label': fallbackName,
      ...props
    });
  };
}

/**
 * Bundle size optimization: Only load icons when they're actually used
 */
export const OptimizedIcons = {
  // Create optimized versions of common icon combinations
  EditButton: () => lazy(() => import('lucide-react').then(mod => ({ default: mod.Edit3 }))),
  DeleteButton: () => lazy(() => import('lucide-react').then(mod => ({ default: mod.Trash2 }))),
  ViewButton: () => lazy(() => import('lucide-react').then(mod => ({ default: mod.Eye }))),
};

/**
 * Icon preloader for critical icons
 */
export function preloadCriticalIcons() {
  // This can be called in the root layout to preload essential icons
  return Promise.all([
    import('lucide-react'),
  ]);
}

/**
 * Get icon size classes for consistent sizing
 */
export function getIconSizeClass(size: 'xs' | 'sm' | 'md' | 'lg' | 'xl' = 'md') {
  const sizeMap = {
    xs: 'h-3 w-3',
    sm: 'h-4 w-4',
    md: 'h-5 w-5',
    lg: 'h-6 w-6',
    xl: 'h-8 w-8',
  };
  
  return sizeMap[size];
}