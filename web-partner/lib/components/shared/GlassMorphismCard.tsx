import React from 'react';
import { motion, HTMLMotionProps } from 'framer-motion';
import { cn } from '@/lib/utils';

interface GlassMorphismCardProps extends HTMLMotionProps<"div"> {
  children: React.ReactNode;
  className?: string;
  hover?: boolean;
  padding?: 'sm' | 'md' | 'lg' | 'xl';
}

export function GlassMorphismCard({ 
  children, 
  className, 
  hover = false,
  padding = 'md',
  ...motionProps 
}: GlassMorphismCardProps) {
  const paddingClasses = {
    sm: 'p-4',
    md: 'p-6',
    lg: 'p-8',
    xl: 'p-10'
  };

  const baseClasses = cn(
    'glass-morphism rounded-xl',
    paddingClasses[padding],
    hover && 'hover:scale-[1.02] transition-transform cursor-pointer',
    className
  );

  return (
    <motion.div
      className={baseClasses}
      whileHover={hover ? { y: -4 } : undefined}
      {...motionProps}
    >
      {children}
    </motion.div>
  );
}