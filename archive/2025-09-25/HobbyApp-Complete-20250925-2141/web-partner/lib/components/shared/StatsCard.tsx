import React from 'react';
import { LucideIcon, TrendingUp, TrendingDown } from 'lucide-react';
import { cn } from '@/lib/utils';

interface StatsCardProps {
  label: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  icon?: LucideIcon;
  iconColor?: string;
  trend?: 'up' | 'down' | 'neutral';
  sparkline?: number[];
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

export function StatsCard({
  label,
  value,
  change,
  changeLabel = 'vs last period',
  icon: Icon,
  iconColor = 'text-purple-400',
  trend,
  sparkline,
  className,
  size = 'md'
}: StatsCardProps) {
  // Determine trend from change if not provided
  const displayTrend = trend || (change ? (change > 0 ? 'up' : 'down') : 'neutral');
  
  const sizeClasses = {
    sm: 'p-4',
    md: 'p-6',
    lg: 'p-8'
  };

  const valueSizeClasses = {
    sm: 'text-xl',
    md: 'text-2xl',
    lg: 'text-3xl'
  };

  return (
    <div className={cn('glass-morphism rounded-xl', sizeClasses[size], className)}>
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <p className="text-sm text-gray-400">{label}</p>
          <p className={cn('font-bold text-white mt-1', valueSizeClasses[size])}>
            {value}
          </p>
        </div>
        {Icon && (
          <div className={cn('p-2 rounded-lg bg-white/10')}>
            <Icon className={cn('w-5 h-5', iconColor)} />
          </div>
        )}
      </div>

      {change !== undefined && (
        <div className="flex items-center gap-2 mb-3">
          <div className="flex items-center gap-1">
            {displayTrend === 'up' && <TrendingUp className="w-4 h-4 text-green-400" />}
            {displayTrend === 'down' && <TrendingDown className="w-4 h-4 text-red-400" />}
            <span className={cn(
              'text-sm font-medium',
              displayTrend === 'up' ? 'text-green-400' : 
              displayTrend === 'down' ? 'text-red-400' : 
              'text-gray-400'
            )}>
              {change > 0 ? '+' : ''}{change}%
            </span>
          </div>
          <span className="text-xs text-gray-500">{changeLabel}</span>
        </div>
      )}

      {sparkline && sparkline.length > 0 && (
        <div className="flex items-end gap-1 h-8">
          {sparkline.map((value, i) => (
            <div
              key={i}
              className="flex-1 bg-purple-500/50 rounded-t"
              style={{ height: `${(value / Math.max(...sparkline)) * 100}%` }}
            />
          ))}
        </div>
      )}
    </div>
  );
}