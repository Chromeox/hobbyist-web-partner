import React from 'react'

/**
 * Performance Monitoring Utility for V8 Runtime Optimization
 * 
 * Tracks and reports on:
 * - JSON parse/stringify performance
 * - Object shape stability
 * - Memory usage patterns
 * - API response times
 * - React render performance
 */

interface PerformanceMetric {
  name: string
  duration: number
  timestamp: number
  metadata?: Record<string, any>
}

interface MemorySnapshot {
  timestamp: number
  used: number
  total: number
  external: number
  arrayBuffers: number
}

class PerformanceMonitor {
  private metrics: PerformanceMetric[] = []
  private memorySnapshots: MemorySnapshot[] = []
  private observerEntries: PerformanceObserverEntryList | null = null
  private observer: PerformanceObserver | null = null
  
  constructor() {
    if (typeof window !== 'undefined' && 'PerformanceObserver' in window) {
      this.initializeObserver()
    }
  }
  
  private initializeObserver(): void {
    try {
      this.observer = new PerformanceObserver((list) => {
        this.observerEntries = list
        const entries = list.getEntries()
        
        entries.forEach(entry => {
          if (entry.entryType === 'measure') {
            this.metrics.push({
              name: entry.name,
              duration: entry.duration,
              timestamp: entry.startTime,
              metadata: { entryType: entry.entryType }
            })
          }
        })
      })
      
      this.observer.observe({ 
        entryTypes: ['measure', 'navigation', 'resource'] 
      })
    } catch (error) {
      console.warn('PerformanceObserver not available:', error)
    }
  }
  
  // Measure JSON serialization performance
  measureJSONPerformance(data: any, label: string = 'json'): {
    stringifyTime: number
    parseTime: number
    size: number
  } {
    const start = performance.now()
    const serialized = JSON.stringify(data)
    const stringifyTime = performance.now() - start
    
    const parseStart = performance.now()
    JSON.parse(serialized)
    const parseTime = performance.now() - parseStart
    
    this.metrics.push({
      name: `${label}_stringify`,
      duration: stringifyTime,
      timestamp: Date.now(),
      metadata: { size: serialized.length }
    })
    
    this.metrics.push({
      name: `${label}_parse`,
      duration: parseTime,
      timestamp: Date.now(),
      metadata: { size: serialized.length }
    })
    
    return {
      stringifyTime,
      parseTime,
      size: serialized.length
    }
  }
  
  // Track API call performance
  async measureAPICall<T>(
    apiCall: () => Promise<T>,
    label: string
  ): Promise<T> {
    const start = performance.now()
    
    try {
      const result = await apiCall()
      const duration = performance.now() - start
      
      this.metrics.push({
        name: `api_${label}`,
        duration,
        timestamp: Date.now(),
        metadata: { 
          success: true,
          responseSize: JSON.stringify(result).length 
        }
      })
      
      return result
    } catch (error) {
      const duration = performance.now() - start
      
      this.metrics.push({
        name: `api_${label}`,
        duration,
        timestamp: Date.now(),
        metadata: { 
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error'
        }
      })
      
      throw error
    }
  }
  
  // Check object shape stability (V8 hidden class optimization)
  checkObjectShapeStability(objects: any[]): {
    stable: boolean
    shapes: string[]
    recommendation?: string
  } {
    if (objects.length === 0) {
      return { stable: true, shapes: [] }
    }
    
    const shapes = objects.map(obj => {
      const keys = Object.keys(obj).sort()
      return keys.join(',')
    })
    
    const uniqueShapes = [...new Set(shapes)]
    const stable = uniqueShapes.length === 1
    
    return {
      stable,
      shapes: uniqueShapes,
      recommendation: !stable 
        ? 'Objects have different shapes. Consider normalizing to a consistent structure for V8 optimization.'
        : undefined
    }
  }
  
  // Memory usage tracking
  captureMemorySnapshot(): MemorySnapshot | null {
    if (typeof window === 'undefined' || !('performance' in window)) {
      return null
    }
    
    const memory = (performance as any).memory
    if (!memory) {
      return null
    }
    
    const snapshot: MemorySnapshot = {
      timestamp: Date.now(),
      used: memory.usedJSHeapSize,
      total: memory.totalJSHeapSize,
      external: memory.externalSize || 0,
      arrayBuffers: memory.arrayBuffers || 0
    }
    
    this.memorySnapshots.push(snapshot)
    
    // Keep only last 100 snapshots
    if (this.memorySnapshots.length > 100) {
      this.memorySnapshots.shift()
    }
    
    return snapshot
  }
  
  // React component render tracking
  measureComponentRender(componentName: string, renderFn: () => void): number {
    const start = performance.now()
    renderFn()
    const duration = performance.now() - start
    
    this.metrics.push({
      name: `render_${componentName}`,
      duration,
      timestamp: Date.now()
    })
    
    return duration
  }
  
  // Get performance report
  getReport(): {
    metrics: PerformanceMetric[]
    averages: Record<string, number>
    memory: {
      current: MemorySnapshot | null
      trend: 'increasing' | 'decreasing' | 'stable'
    }
    recommendations: string[]
  } {
    // Calculate averages by metric name
    const averages: Record<string, number> = {}
    const metricGroups: Record<string, number[]> = {}
    
    this.metrics.forEach(metric => {
      if (!metricGroups[metric.name]) {
        metricGroups[metric.name] = []
      }
      metricGroups[metric.name].push(metric.duration)
    })
    
    for (const [name, durations] of Object.entries(metricGroups)) {
      averages[name] = durations.reduce((a, b) => a + b, 0) / durations.length
    }
    
    // Analyze memory trend
    let memoryTrend: 'increasing' | 'decreasing' | 'stable' = 'stable'
    if (this.memorySnapshots.length > 10) {
      const recent = this.memorySnapshots.slice(-10)
      const firstUsed = recent[0].used
      const lastUsed = recent[recent.length - 1].used
      const change = ((lastUsed - firstUsed) / firstUsed) * 100
      
      if (change > 10) memoryTrend = 'increasing'
      else if (change < -10) memoryTrend = 'decreasing'
    }
    
    // Generate recommendations
    const recommendations: string[] = []
    
    // Check for slow JSON operations
    const jsonMetrics = Object.entries(averages).filter(([key]) => 
      key.includes('stringify') || key.includes('parse')
    )
    
    jsonMetrics.forEach(([name, avg]) => {
      if (avg > 10) {
        recommendations.push(
          `${name} is slow (${avg.toFixed(2)}ms avg). Consider using smaller payloads or streaming.`
        )
      }
    })
    
    // Check for slow API calls
    const apiMetrics = Object.entries(averages).filter(([key]) => 
      key.startsWith('api_')
    )
    
    apiMetrics.forEach(([name, avg]) => {
      if (avg > 1000) {
        recommendations.push(
          `${name} is slow (${avg.toFixed(0)}ms avg). Consider implementing caching or pagination.`
        )
      }
    })
    
    // Check memory trend
    if (memoryTrend === 'increasing') {
      recommendations.push(
        'Memory usage is increasing. Check for memory leaks or implement cleanup in useEffect hooks.'
      )
    }
    
    return {
      metrics: this.metrics.slice(-100), // Last 100 metrics
      averages,
      memory: {
        current: this.memorySnapshots[this.memorySnapshots.length - 1] || null,
        trend: memoryTrend
      },
      recommendations
    }
  }
  
  // Clear metrics
  clear(): void {
    this.metrics = []
    this.memorySnapshots = []
  }
  
  // Export metrics for analysis
  exportMetrics(): string {
    return JSON.stringify({
      metrics: this.metrics,
      memorySnapshots: this.memorySnapshots,
      timestamp: Date.now()
    }, null, 2)
  }
}

// Singleton instance
export const performanceMonitor = new PerformanceMonitor()

// React hook for performance monitoring
export function usePerformanceMonitor() {
  return performanceMonitor
}

// HOC for component performance tracking
export function withPerformanceTracking<P extends object>(
  Component: React.ComponentType<P>,
  componentName: string
) {
  return (props: P) => {
    const monitor = usePerformanceMonitor()
    
    React.useEffect(() => {
      const renderTime = monitor.measureComponentRender(componentName, () => {
        // Component has already rendered by this point
      })
      
      if (renderTime > 16) { // More than one frame (60fps)
        console.warn(`${componentName} render took ${renderTime.toFixed(2)}ms`)
      }
    })
    
    return <Component {...props} />
  }
}
