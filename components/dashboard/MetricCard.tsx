/**
 * Metric Card Component
 *
 * Reusable card component for displaying dashboard metrics
 * Follows CARD_DESIGN_SYSTEM.md specifications
 *
 * Features:
 * - Gradient backgrounds based on color theme
 * - Icon badges with matching colors
 * - Uppercase labels with proper typography
 * - Optional change indicators (trending up/down)
 * - Hover effects and transitions
 * - Fully accessible with ARIA labels
 */

'use client';

import React from 'react';
import { TrendingUp, TrendingDown, LucideIcon } from 'lucide-react';

export interface MetricCardProps {
  /** Display label (will be uppercased) */
  label: string;

  /** Metric value (number or formatted string like "$1,234") */
  value: string | number;

  /** Icon component from lucide-react */
  icon: LucideIcon;

  /** Color theme (determines gradient and icon colors) */
  color: 'green' | 'blue' | 'purple' | 'yellow' | 'orange' | 'red';

  /** Optional change percentage (positive or negative) */
  change?: number;

  /** Label for the change indicator (default: "vs last week") */
  changeLabel?: string;

  /** Optional click handler */
  onClick?: () => void;

  /** Optional className for additional styling */
  className?: string;
}

/**
 * Color configuration matching design system
 */
const colorConfig = {
  green: {
    gradient: 'from-green-50 to-green-100',
    border: 'border-green-200',
    iconBg: 'bg-green-100',
    iconText: 'text-green-600',
    changeBg: 'bg-green-100',
    changeText: 'text-green-700',
  },
  blue: {
    gradient: 'from-blue-50 to-blue-100',
    border: 'border-blue-200',
    iconBg: 'bg-blue-100',
    iconText: 'text-blue-600',
    changeBg: 'bg-blue-100',
    changeText: 'text-blue-700',
  },
  purple: {
    gradient: 'from-purple-50 to-purple-100',
    border: 'border-purple-200',
    iconBg: 'bg-purple-100',
    iconText: 'text-purple-600',
    changeBg: 'bg-purple-100',
    changeText: 'text-purple-700',
  },
  yellow: {
    gradient: 'from-yellow-50 to-yellow-100',
    border: 'border-yellow-200',
    iconBg: 'bg-yellow-100',
    iconText: 'text-yellow-600',
    changeBg: 'bg-yellow-100',
    changeText: 'text-yellow-700',
  },
  orange: {
    gradient: 'from-orange-50 to-orange-100',
    border: 'border-orange-200',
    iconBg: 'bg-orange-100',
    iconText: 'text-orange-600',
    changeBg: 'bg-orange-100',
    changeText: 'text-orange-700',
  },
  red: {
    gradient: 'from-red-50 to-red-100',
    border: 'border-red-200',
    iconBg: 'bg-red-100',
    iconText: 'text-red-600',
    changeBg: 'bg-red-100',
    changeText: 'text-red-700',
  },
};

/**
 * MetricCard Component
 *
 * @example
 * ```tsx
 * <MetricCard
 *   label="Total Revenue"
 *   value="$12,345"
 *   icon={DollarSign}
 *   color="green"
 *   change={12.5}
 *   changeLabel="vs last month"
 * />
 * ```
 */
export function MetricCard({
  label,
  value,
  icon: Icon,
  color,
  change,
  changeLabel = 'vs last week',
  onClick,
  className = '',
}: MetricCardProps) {
  const colors = colorConfig[color];
  const isPositiveChange = change !== undefined && change > 0;
  const isNegativeChange = change !== undefined && change < 0;

  return (
    <div
      className={`
        bg-gradient-to-br ${colors.gradient}
        border ${colors.border}
        rounded-xl p-4
        hover:shadow-lg
        transition-all duration-300
        ${onClick ? 'cursor-pointer' : ''}
        ${className}
      `}
      onClick={onClick}
      role={onClick ? 'button' : 'article'}
      tabIndex={onClick ? 0 : undefined}
      aria-label={`${label}: ${value}${change ? `, ${Math.abs(change)}% ${isPositiveChange ? 'increase' : 'decrease'}` : ''}`}
    >
      {/* Icon Badge */}
      <div className={`inline-flex p-2 rounded-lg ${colors.iconBg}`}>
        <Icon className={`h-4 w-4 ${colors.iconText}`} aria-hidden="true" />
      </div>

      {/* Label */}
      <h3 className="text-xs font-medium text-gray-600 uppercase tracking-wider mt-2">
        {label}
      </h3>

      {/* Value */}
      <p className="text-2xl font-bold text-gray-900 mt-1">
        {value}
      </p>

      {/* Change Indicator */}
      {change !== undefined && (
        <>
          <div
            className={`
              flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold mt-2 inline-flex
              ${isPositiveChange ? 'bg-green-100 text-green-700' : ''}
              ${isNegativeChange ? 'bg-red-100 text-red-700' : ''}
              ${change === 0 ? colors.changeBg + ' ' + colors.changeText : ''}
            `}
          >
            {isPositiveChange && <TrendingUp className="h-3 w-3" aria-hidden="true" />}
            {isNegativeChange && <TrendingDown className="h-3 w-3" aria-hidden="true" />}
            <span>{isPositiveChange ? '+' : ''}{change}%</span>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            {changeLabel}
          </p>
        </>
      )}
    </div>
  );
}

/**
 * Compact version of MetricCard for smaller spaces
 */
export function MetricCardCompact({
  label,
  value,
  icon: Icon,
  color,
  className = '',
}: Omit<MetricCardProps, 'change' | 'changeLabel' | 'onClick'>) {
  const colors = colorConfig[color];

  return (
    <div
      className={`
        bg-gradient-to-br ${colors.gradient}
        border ${colors.border}
        rounded-xl p-3
        hover:shadow-lg
        transition-all duration-300
        ${className}
      `}
      role="article"
      aria-label={`${label}: ${value}`}
    >
      <div className="flex items-center gap-2">
        <div className={`p-1.5 rounded-lg ${colors.iconBg}`}>
          <Icon className={`h-3 w-3 ${colors.iconText}`} aria-hidden="true" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-xs font-medium text-gray-600 uppercase tracking-wider truncate">
            {label}
          </p>
          <p className="text-lg font-bold text-gray-900">
            {value}
          </p>
        </div>
      </div>
    </div>
  );
}

export default MetricCard;
