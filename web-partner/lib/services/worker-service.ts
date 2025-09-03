/**
 * Worker Service for Managing Web Workers
 * Provides easy-to-use interface for offloading heavy computations
 */

interface WorkerMessage {
  type: string;
  data?: any;
  error?: { message: string; stack?: string };
}

interface WorkerTask<T> {
  type: string;
  data: any;
  resolve: (value: T) => void;
  reject: (error: Error) => void;
  timeout?: NodeJS.Timeout;
}

export class WorkerService {
  private static workers: Map<string, Worker> = new Map();
  private static tasks: Map<string, WorkerTask<any>> = new Map();
  private static taskCounter = 0;
  
  /**
   * Initialize workers
   */
  static initialize() {
    // Only initialize in browser environment
    if (typeof window === 'undefined' || typeof Worker === 'undefined') {
      console.warn('[WorkerService] Web Workers not supported in this environment');
      return;
    }
    
    // Create analytics worker
    this.createWorker('analytics', '/workers/analytics.worker.js');
    
    // Create data processing worker
    this.createWorker('dataProcessor', '/workers/data-processor.worker.js');
    
    // Register service worker
    this.registerServiceWorker();
  }
  
  /**
   * Create and register a worker
   */
  private static createWorker(name: string, path: string) {
    try {
      const worker = new Worker(path);
      
      // Set up message handler
      worker.addEventListener('message', (event: MessageEvent<WorkerMessage>) => {
        this.handleWorkerMessage(name, event.data);
      });
      
      // Set up error handler
      worker.addEventListener('error', (error) => {
        console.error(`[WorkerService] Error in ${name} worker:`, error);
        this.handleWorkerError(name, error);
      });
      
      this.workers.set(name, worker);
      console.log(`[WorkerService] ${name} worker initialized`);
    } catch (error) {
      console.error(`[WorkerService] Failed to create ${name} worker:`, error);
    }
  }
  
  /**
   * Handle messages from workers
   */
  private static handleWorkerMessage(workerName: string, message: WorkerMessage) {
    // Find matching task
    const taskId = this.findTaskId(message.type);
    
    if (!taskId) {
      console.warn(`[WorkerService] No task found for message type: ${message.type}`);
      return;
    }
    
    const task = this.tasks.get(taskId);
    if (!task) return;
    
    // Clear timeout
    if (task.timeout) {
      clearTimeout(task.timeout);
    }
    
    // Handle response
    if (message.error) {
      task.reject(new Error(message.error.message));
    } else {
      task.resolve(message.data);
    }
    
    // Clean up
    this.tasks.delete(taskId);
  }
  
  /**
   * Handle worker errors
   */
  private static handleWorkerError(workerName: string, error: ErrorEvent) {
    // Reject all pending tasks for this worker
    this.tasks.forEach((task, taskId) => {
      if (task.type.includes(workerName)) {
        task.reject(new Error(`Worker error: ${error.message}`));
        this.tasks.delete(taskId);
      }
    });
  }
  
  /**
   * Find task ID by response type
   */
  private static findTaskId(responseType: string): string | undefined {
    // Map response types to request types
    const typeMapping: Record<string, string> = {
      'REVENUE_ANALYTICS_COMPLETE': 'CALCULATE_REVENUE_ANALYTICS',
      'BOOKING_PREDICTIONS_COMPLETE': 'PREDICT_BOOKING_TRENDS',
      'INSTRUCTOR_ANALYSIS_COMPLETE': 'ANALYZE_INSTRUCTOR_PERFORMANCE',
      'COHORT_RETENTION_COMPLETE': 'CALCULATE_COHORT_RETENTION',
      'SCHEDULE_OPTIMIZATION_COMPLETE': 'OPTIMIZE_CLASS_SCHEDULE',
      'REPORT_GENERATED': 'GENERATE_REPORT',
      'ERROR': '*' // Matches any task
    };
    
    const requestType = typeMapping[responseType] || responseType;
    
    for (const [taskId, task] of this.tasks.entries()) {
      if (requestType === '*' || task.type === requestType) {
        return taskId;
      }
    }
    
    return undefined;
  }
  
  /**
   * Send task to worker
   */
  private static sendToWorker<T>(
    workerName: string,
    type: string,
    data: any,
    timeout = 30000
  ): Promise<T> {
    return new Promise((resolve, reject) => {
      const worker = this.workers.get(workerName);
      
      if (!worker) {
        reject(new Error(`Worker ${workerName} not found`));
        return;
      }
      
      const taskId = `${workerName}_${type}_${++this.taskCounter}`;
      
      // Set up timeout
      const timeoutHandle = setTimeout(() => {
        this.tasks.delete(taskId);
        reject(new Error(`Worker task timeout: ${type}`));
      }, timeout);
      
      // Store task
      this.tasks.set(taskId, {
        type,
        data,
        resolve,
        reject,
        timeout: timeoutHandle
      });
      
      // Send message to worker
      worker.postMessage({ type, data });
    });
  }
  
  // Public API Methods
  
  /**
   * Calculate revenue analytics in background
   */
  static async calculateRevenueAnalytics(
    bookings: any[],
    timeRange: { start: Date; end: Date },
    granularity: 'daily' | 'weekly' | 'monthly' = 'daily'
  ) {
    return this.sendToWorker<any>(
      'analytics',
      'CALCULATE_REVENUE_ANALYTICS',
      { bookings, timeRange, granularity }
    );
  }
  
  /**
   * Predict booking trends
   */
  static async predictBookingTrends(
    historicalData: any[],
    horizonDays = 30
  ) {
    return this.sendToWorker<any>(
      'analytics',
      'PREDICT_BOOKING_TRENDS',
      { historicalData, horizonDays }
    );
  }
  
  /**
   * Analyze instructor performance
   */
  static async analyzeInstructorPerformance(
    instructors: any[],
    bookings: any[],
    reviews: any[]
  ) {
    return this.sendToWorker<any>(
      'analytics',
      'ANALYZE_INSTRUCTOR_PERFORMANCE',
      { instructors, bookings, reviews }
    );
  }
  
  /**
   * Calculate cohort retention
   */
  static async calculateCohortRetention(
    users: any[],
    bookings: any[],
    cohortSize: 'daily' | 'weekly' | 'monthly' = 'monthly'
  ) {
    return this.sendToWorker<any>(
      'analytics',
      'CALCULATE_COHORT_RETENTION',
      { users, bookings, cohortSize }
    );
  }
  
  /**
   * Optimize class schedule
   */
  static async optimizeClassSchedule(
    currentSchedule: any[],
    historicalBookings: any[],
    constraints?: any
  ) {
    return this.sendToWorker<any>(
      'analytics',
      'OPTIMIZE_CLASS_SCHEDULE',
      { currentSchedule, historicalBookings, constraints }
    );
  }
  
  /**
   * Generate comprehensive report
   */
  static async generateReport(data: any) {
    return this.sendToWorker<any>(
      'analytics',
      'GENERATE_REPORT',
      data,
      60000 // 60 second timeout for reports
    );
  }
  
  /**
   * Register service worker
   */
  private static async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.register('/service-worker.js');
        
        console.log('[WorkerService] Service Worker registered:', registration);
        
        // Check for updates
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          
          if (newWorker) {
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                // New service worker available
                console.log('[WorkerService] New Service Worker available');
                
                // Optionally prompt user to refresh
                if (window.confirm('New version available! Refresh to update?')) {
                  newWorker.postMessage({ type: 'SKIP_WAITING' });
                  window.location.reload();
                }
              }
            });
          }
        });
        
        // Handle controller change
        navigator.serviceWorker.addEventListener('controllerchange', () => {
          console.log('[WorkerService] Service Worker controller changed');
        });
        
      } catch (error) {
        console.error('[WorkerService] Service Worker registration failed:', error);
      }
    }
  }
  
  /**
   * Terminate all workers
   */
  static terminate() {
    this.workers.forEach((worker, name) => {
      worker.terminate();
      console.log(`[WorkerService] ${name} worker terminated`);
    });
    
    this.workers.clear();
    this.tasks.clear();
  }
  
  /**
   * Get worker status
   */
  static getStatus() {
    return {
      workers: Array.from(this.workers.keys()),
      pendingTasks: this.tasks.size,
      serviceWorker: 'serviceWorker' in navigator ? 'available' : 'not supported'
    };
  }
}

// Auto-initialize on import
if (typeof window !== 'undefined') {
  WorkerService.initialize();
}