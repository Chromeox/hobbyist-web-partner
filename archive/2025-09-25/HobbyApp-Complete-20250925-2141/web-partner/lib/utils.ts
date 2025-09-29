import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Format currency for studio revenue displays
 */
export function formatCurrency(amount: number, currency = 'CAD'): string {
  return new Intl.NumberFormat('en-CA', {
    style: 'currency',
    currency,
  }).format(amount)
}

/**
 * Format workshop duration in minutes to readable format
 */
export function formatDuration(minutes: number): string {
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60

  if (hours === 0) return `${minutes}min`
  if (remainingMinutes === 0) return `${hours}h`
  return `${hours}h ${remainingMinutes}min`
}

/**
 * Calculate workshop capacity utilization percentage
 */
export function calculateCapacity(booked: number, total: number): number {
  if (total === 0) return 0
  return Math.round((booked / total) * 100)
}

/**
 * Get workshop category color for UI theming
 */
export function getCategoryColor(category: string): string {
  const colors: Record<string, string> = {
    pottery: 'bg-amber-100 text-amber-800',
    painting: 'bg-blue-100 text-blue-800',
    woodworking: 'bg-orange-100 text-orange-800',
    jewelry: 'bg-purple-100 text-purple-800',
    cooking: 'bg-green-100 text-green-800',
    music: 'bg-pink-100 text-pink-800',
    default: 'bg-gray-100 text-gray-800'
  }

  return colors[category.toLowerCase()] || colors.default
}

/**
 * Determine if a workshop time slot conflicts with another
 */
export function hasTimeConflict(
  start1: Date,
  end1: Date,
  start2: Date,
  end2: Date
): boolean {
  return start1 < end2 && start2 < end1
}

/**
 * Calculate material cost per student for workshops
 */
export function calculateMaterialCostPerStudent(
  materials: Array<{ quantity: number; costPerUnit: number; participantRatio?: number }>,
  maxParticipants: number
): number {
  return materials.reduce((total, material) => {
    const ratio = material.participantRatio || 1 // Default: 1 unit per participant
    const totalCost = material.quantity * material.costPerUnit
    const costPerParticipant = (totalCost * ratio) / maxParticipants
    return total + costPerParticipant
  }, 0)
}