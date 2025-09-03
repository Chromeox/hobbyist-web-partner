'use client';

import React, { useState, useCallback, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Star } from 'lucide-react';

export interface RatingStarsProps {
  rating?: number;
  maxRating?: number;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  interactive?: boolean;
  showHalfStars?: boolean;
  showLabel?: boolean;
  showCount?: boolean;
  reviewCount?: number;
  onRatingChange?: (rating: number) => void;
  className?: string;
  disabled?: boolean;
  precision?: number; // 0.5 for half stars, 1 for full stars
}

const RatingStars: React.FC<RatingStarsProps> = ({
  rating = 0,
  maxRating = 5,
  size = 'md',
  interactive = false,
  showHalfStars = true,
  showLabel = false,
  showCount = false,
  reviewCount = 0,
  onRatingChange,
  className = '',
  disabled = false,
  precision = 0.5,
}) => {
  const [hoverRating, setHoverRating] = useState<number>(0);

  // Size configurations
  const sizeConfig = useMemo(() => ({
    sm: { star: 'w-4 h-4', text: 'text-sm' },
    md: { star: 'w-5 h-5', text: 'text-base' },
    lg: { star: 'w-6 h-6', text: 'text-lg' },
    xl: { star: 'w-8 h-8', text: 'text-xl' }
  }), []);

  const { star: starSize, text: textSize } = sizeConfig[size];

  // Calculate display rating (use hover rating if hovering, otherwise actual rating)
  const displayRating = interactive && hoverRating > 0 ? hoverRating : rating;

  // Handle mouse events for interactive mode
  const handleMouseEnter = useCallback((index: number, event: React.MouseEvent) => {
    if (!interactive || disabled) return;

    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const width = rect.width;
    const percentage = x / width;

    let newRating;
    if (showHalfStars && precision === 0.5) {
      newRating = percentage > 0.5 ? index + 1 : index + 0.5;
    } else {
      newRating = index + 1;
    }

    setHoverRating(newRating);
  }, [interactive, disabled, showHalfStars, precision]);

  const handleMouseLeave = useCallback(() => {
    if (!interactive || disabled) return;
    setHoverRating(0);
  }, [interactive, disabled]);

  const handleClick = useCallback((index: number, event: React.MouseEvent) => {
    if (!interactive || disabled || !onRatingChange) return;

    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const width = rect.width;
    const percentage = x / width;

    let newRating;
    if (showHalfStars && precision === 0.5) {
      newRating = percentage > 0.5 ? index + 1 : index + 0.5;
    } else {
      newRating = index + 1;
    }

    onRatingChange(newRating);
  }, [interactive, disabled, onRatingChange, showHalfStars, precision]);

  // Handle keyboard navigation
  const handleKeyDown = useCallback((event: React.KeyboardEvent) => {
    if (!interactive || disabled || !onRatingChange) return;

    let newRating = rating;
    switch (event.key) {
      case 'ArrowRight':
      case 'ArrowUp':
        event.preventDefault();
        newRating = Math.min(rating + precision, maxRating);
        break;
      case 'ArrowLeft':
      case 'ArrowDown':
        event.preventDefault();
        newRating = Math.max(rating - precision, 0);
        break;
      case 'Home':
        event.preventDefault();
        newRating = precision;
        break;
      case 'End':
        event.preventDefault();
        newRating = maxRating;
        break;
      case 'Delete':
      case 'Backspace':
        event.preventDefault();
        newRating = 0;
        break;
      default:
        return;
    }

    onRatingChange(newRating);
  }, [interactive, disabled, onRatingChange, rating, precision, maxRating]);

  // Get star fill percentage
  const getStarFill = useCallback((starIndex: number): number => {
    const starValue = starIndex + 1;
    if (displayRating >= starValue) {
      return 100;
    } else if (displayRating > starIndex) {
      return (displayRating - starIndex) * 100;
    }
    return 0;
  }, [displayRating]);

  // Get star color based on rating
  const getStarColor = useCallback((fillPercentage: number): string => {
    if (fillPercentage > 0) {
      return 'text-yellow-400';
    }
    return interactive && !disabled ? 'text-gray-300 hover:text-yellow-200' : 'text-gray-300';
  }, [interactive, disabled]);

  // Format rating label
  const formatRatingLabel = useCallback((value: number): string => {
    if (value === 0) return 'No rating';
    if (value === 1) return 'Poor';
    if (value <= 2) return 'Fair';
    if (value <= 3) return 'Good';
    if (value <= 4) return 'Very Good';
    return 'Excellent';
  }, []);

  return (
    <div className={`flex items-center gap-2 ${className}`}>
      {/* Stars Container */}
      <div
        className={`flex items-center gap-0.5 ${
          interactive && !disabled 
            ? 'cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded' 
            : ''
        }`}
        onMouseLeave={handleMouseLeave}
        onKeyDown={handleKeyDown}
        tabIndex={interactive && !disabled ? 0 : -1}
        role={interactive ? 'slider' : 'img'}
        aria-label={interactive ? `Rating: ${displayRating} out of ${maxRating} stars` : `Rated ${rating} out of ${maxRating} stars`}
        aria-valuemin={0}
        aria-valuemax={maxRating}
        aria-valuenow={rating}
      >
        {Array.from({ length: maxRating }, (_, index) => {
          const fillPercentage = getStarFill(index);
          const starColor = getStarColor(fillPercentage);

          return (
            <motion.div
              key={index}
              className="relative"
              whileHover={interactive && !disabled ? { scale: 1.1 } : undefined}
              whileTap={interactive && !disabled ? { scale: 0.95 } : undefined}
            >
              <Star
                className={`${starSize} ${starColor} transition-colors duration-200`}
                onMouseEnter={(e) => handleMouseEnter(index, e)}
                onMouseMove={(e) => handleMouseEnter(index, e)}
                onClick={(e) => handleClick(index, e)}
                fill={fillPercentage > 0 ? 'currentColor' : 'none'}
                style={{
                  filter: fillPercentage > 0 && fillPercentage < 100 
                    ? `url(#star-gradient-${index})` 
                    : undefined
                }}
              />
              
              {/* Gradient definition for half stars */}
              {fillPercentage > 0 && fillPercentage < 100 && (
                <svg className="absolute inset-0 w-0 h-0">
                  <defs>
                    <linearGradient id={`star-gradient-${index}`} x1="0%" y1="0%" x2="100%" y2="0%">
                      <stop
                        offset={`${fillPercentage}%`}
                        stopColor="currentColor"
                        className="text-yellow-400"
                      />
                      <stop
                        offset={`${fillPercentage}%`}
                        stopColor="transparent"
                      />
                    </linearGradient>
                  </defs>
                </svg>
              )}
            </motion.div>
          );
        })}
      </div>

      {/* Rating Display */}
      {(showLabel || showCount) && (
        <div className={`flex items-center gap-2 ${textSize} text-gray-600 dark:text-gray-400`}>
          {/* Numeric Rating */}
          <span className="font-medium">
            {displayRating.toFixed(precision === 0.5 ? 1 : 0)}
          </span>

          {/* Rating Label */}
          {showLabel && (
            <span className="text-sm text-gray-500 dark:text-gray-500">
              {formatRatingLabel(displayRating)}
            </span>
          )}

          {/* Review Count */}
          {showCount && reviewCount > 0 && (
            <span className="text-sm text-gray-500 dark:text-gray-500">
              ({reviewCount} {reviewCount === 1 ? 'review' : 'reviews'})
            </span>
          )}
        </div>
      )}

      {/* Screen Reader Only Current Value */}
      <span className="sr-only">
        {interactive && hoverRating > 0 
          ? `Hover rating: ${hoverRating} out of ${maxRating} stars`
          : `Current rating: ${rating} out of ${maxRating} stars`
        }
      </span>
    </div>
  );
};

export default RatingStars;