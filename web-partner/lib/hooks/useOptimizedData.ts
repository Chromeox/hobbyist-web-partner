/**
 * Optimized React hooks for V8-friendly state management
 * 
 * Key optimizations:
 * 1. Stable reference preservation to prevent unnecessary re-renders
 * 2. Shallow comparison for state updates
 * 3. Request deduplication
 * 4. Optimistic updates with rollback
 * 5. Suspense-ready data fetching
 */

import { useEffect, useRef, useState, useCallback, useMemo } from 'react'
import { OptimizedDataService } from '../services/optimized-data'

// Stable empty arrays/objects to prevent re-renders
const EMPTY_ARRAY = Object.freeze([])
const EMPTY_OBJECT = Object.freeze({})

// Shallow compare utility for V8 optimization
function shallowEqual(a: any, b: any): boolean {
  if (a === b) return true
  if (!a || !b) return false
  
  const keysA = Object.keys(a)
  const keysB = Object.keys(b)
  
  if (keysA.length !== keysB.length) return false
  
  for (const key of keysA) {
    if (a[key] !== b[key]) return false
  }
  
  return true
}

// Request deduplication map
const pendingRequests = new Map<string, Promise<any>>()

// Generic data fetching hook with optimizations
export function useOptimizedData<T>(
  fetcher: () => Promise<T>,
  deps: any[] = [],
  options: {
    cacheKey?: string
    suspense?: boolean
    optimisticUpdate?: (current: T | null) => T
    fallback?: T
  } = {}
) {
  const [data, setData] = useState<T | null>(options.fallback || null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  
  // Stable refs to prevent closure issues
  const dataRef = useRef(data)
  const mountedRef = useRef(true)
  const requestIdRef = useRef(0)
  
  // Memoized fetcher to prevent recreation
  const stableFetcher = useCallback(async () => {
    const requestId = ++requestIdRef.current
    const cacheKey = options.cacheKey || `${fetcher.toString()}:${deps.join(',')}`
    
    // Check for pending request
    if (pendingRequests.has(cacheKey)) {
      return pendingRequests.get(cacheKey)
    }
    
    const request = (async () => {
      try {
        setIsLoading(true)
        setError(null)
        
        // Apply optimistic update if provided
        if (options.optimisticUpdate && dataRef.current) {
          const optimistic = options.optimisticUpdate(dataRef.current)
          setData(optimistic)
        }
        
        const result = await fetcher()
        
        // Only update if this is the latest request and component is mounted
        if (requestId === requestIdRef.current && mountedRef.current) {
          // Use shallow comparison to prevent unnecessary updates
          if (!shallowEqual(dataRef.current, result)) {
            dataRef.current = result
            setData(result)
          }
        }
        
        return result
      } catch (err) {
        if (requestId === requestIdRef.current && mountedRef.current) {
          setError(err as Error)
          // Rollback optimistic update on error
          if (options.optimisticUpdate) {
            setData(dataRef.current)
          }
        }
        throw err
      } finally {
        if (requestId === requestIdRef.current && mountedRef.current) {
          setIsLoading(false)
        }
        pendingRequests.delete(cacheKey)
      }
    })()
    
    pendingRequests.set(cacheKey, request)
    return request
  }, deps) // eslint-disable-line react-hooks/exhaustive-deps
  
  useEffect(() => {
    stableFetcher()
    
    return () => {
      mountedRef.current = false
    }
  }, [stableFetcher])
  
  const refetch = useCallback(() => {
    return stableFetcher()
  }, [stableFetcher])
  
  return {
    data: data || options.fallback || null,
    error,
    isLoading,
    refetch
  }
}

// Specialized hook for dashboard stats
export function useDashboardStats() {
  return useOptimizedData(
    () => OptimizedDataService.getDashboardStats(),
    [],
    {
      cacheKey: 'dashboard:stats',
      fallback: {
        totalBookings: 0,
        totalInstructors: 0,
        totalClasses: 0,
        totalUsers: 0,
        totalRevenue: 0
      }
    }
  )
}

// Specialized hook for instructors with pagination
export function useInstructors(limit = 50) {
  const [page, setPage] = useState(0)
  
  const { data, error, isLoading, refetch } = useOptimizedData(
    () => OptimizedDataService.getInstructors(limit),
    [limit],
    {
      cacheKey: `instructors:${limit}`,
      fallback: EMPTY_ARRAY as any
    }
  )
  
  return {
    instructors: data || EMPTY_ARRAY,
    error,
    isLoading,
    refetch,
    page,
    setPage
  }
}

// Specialized hook for classes with filters
export function useClasses(instructorId?: string, limit = 50) {
  const { data, error, isLoading, refetch } = useOptimizedData(
    () => OptimizedDataService.getClasses(instructorId, limit),
    [instructorId, limit],
    {
      cacheKey: `classes:${instructorId || 'all'}:${limit}`,
      fallback: EMPTY_ARRAY as any
    }
  )
  
  return {
    classes: data || EMPTY_ARRAY,
    error,
    isLoading,
    refetch
  }
}

// Batch data fetching hook
export function useBatchData<T extends Record<string, () => Promise<any>>>(
  fetchers: T
): {
  [K in keyof T]: {
    data: Awaited<ReturnType<T[K]>> | null
    error: Error | null
    isLoading: boolean
  }
} {
  const [results, setResults] = useState<any>(() => {
    const initial: any = {}
    for (const key in fetchers) {
      initial[key] = { data: null, error: null, isLoading: true }
    }
    return initial
  })
  
  useEffect(() => {
    const fetchAll = async () => {
      const entries = Object.entries(fetchers)
      const promises = entries.map(([key, fetcher]) => 
        fetcher()
          .then(data => ({ key, data, error: null }))
          .catch(error => ({ key, data: null, error }))
      )
      
      const batchResults = await Promise.all(promises)
      
      setResults((prev: any) => {
        const next = { ...prev }
        for (const { key, data, error } of batchResults) {
          next[key] = { data, error, isLoading: false }
        }
        return next
      })
    }
    
    fetchAll()
  }, []) // Run once on mount
  
  return results
}

// Prefetch hook for better perceived performance
export function usePrefetch() {
  useEffect(() => {
    // Prefetch common dashboard data in the background
    OptimizedDataService.prefetchDashboardData()
  }, [])
}

// Real-time subscription hook with cleanup
export function useRealtimeSubscription(
  table: 'bookings' | 'payments',
  callback: (payload: any) => void
) {
  useEffect(() => {
    let subscription: any
    
    if (table === 'bookings') {
      subscription = OptimizedDataService.subscribeToBookings(callback)
    }
    // Add more tables as needed
    
    return () => {
      if (subscription) {
        subscription.unsubscribe()
      }
    }
  }, [table, callback])
}

// Cache management hook
export function useCacheManager() {
  const clearCache = useCallback(() => {
    OptimizedDataService.clearCache()
  }, [])
  
  const getCacheStats = useCallback(() => {
    return OptimizedDataService.getCacheStats()
  }, [])
  
  return { clearCache, getCacheStats }
}