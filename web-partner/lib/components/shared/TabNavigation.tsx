import React from 'react';
import { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface Tab {
  id: string;
  label: string;
  icon?: LucideIcon;
}

interface TabNavigationProps {
  tabs: Tab[];
  activeTab: string;
  onTabChange: (tabId: string) => void;
  variant?: 'pills' | 'underline' | 'bordered';
  className?: string;
}

export function TabNavigation({ 
  tabs, 
  activeTab, 
  onTabChange, 
  variant = 'pills',
  className 
}: TabNavigationProps) {
  const getTabClasses = (isActive: boolean) => {
    const baseClasses = 'flex items-center gap-2 px-4 py-2 transition-colors whitespace-nowrap';
    
    switch (variant) {
      case 'underline':
        return cn(
          baseClasses,
          'border-b-2',
          isActive 
            ? 'text-purple-400 border-purple-400' 
            : 'text-gray-400 border-transparent hover:text-white'
        );
      case 'bordered':
        return cn(
          baseClasses,
          'border rounded-lg',
          isActive 
            ? 'bg-purple-600 text-white border-purple-600' 
            : 'bg-transparent text-gray-400 border-gray-700 hover:border-gray-500'
        );
      case 'pills':
      default:
        return cn(
          baseClasses,
          'rounded-lg',
          isActive 
            ? 'bg-purple-600 text-white' 
            : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
        );
    }
  };

  return (
    <div className={cn('flex gap-2 overflow-x-auto', className)}>
      {tabs.map(tab => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;
        
        return (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={getTabClasses(isActive)}
          >
            {Icon && <Icon className="w-4 h-4" />}
            {tab.label}
          </button>
        );
      })}
    </div>
  );
}