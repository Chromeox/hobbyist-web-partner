// Centralized Error Handling System
// Custom error classes and error management utilities

export class HobbyistError extends Error {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly context?: Record<string, any>;
  public readonly timestamp: string;
  public readonly requestId?: string;

  constructor(
    message: string,
    code: string,
    statusCode = 500,
    context?: Record<string, any>,
    requestId?: string
  ) {
    super(message);
    this.name = 'HobbyistError';
    this.code = code;
    this.statusCode = statusCode;
    this.context = context;
    this.timestamp = new Date().toISOString();
    this.requestId = requestId;
  }

  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      statusCode: this.statusCode,
      context: this.context,
      timestamp: this.timestamp,
      requestId: this.requestId,
    };
  }
}

// Domain-specific error classes
export class ValidationError extends HobbyistError {
  constructor(message: string, field?: string, context?: Record<string, any>, requestId?: string) {
    super(message, 'VALIDATION_ERROR', 400, { field, ...context }, requestId);
    this.name = 'ValidationError';
  }
}

export class AuthenticationError extends HobbyistError {
  constructor(message: string, context?: Record<string, any>, requestId?: string) {
    super(message, 'AUTHENTICATION_ERROR', 401, context, requestId);
    this.name = 'AuthenticationError';
  }
}

export class AuthorizationError extends HobbyistError {
  constructor(message: string, resource?: string, action?: string, context?: Record<string, any>, requestId?: string) {
    super(message, 'AUTHORIZATION_ERROR', 403, { resource, action, ...context }, requestId);
    this.name = 'AuthorizationError';
  }
}

export class NotFoundError extends HobbyistError {
  constructor(resource: string, id?: string, context?: Record<string, any>, requestId?: string) {
    super(`${resource} not found`, 'NOT_FOUND', 404, { resource, id, ...context }, requestId);
    this.name = 'NotFoundError';
  }
}

export class ConflictError extends HobbyistError {
  constructor(message: string, resource?: string, context?: Record<string, any>, requestId?: string) {
    super(message, 'CONFLICT_ERROR', 409, { resource, ...context }, requestId);
    this.name = 'ConflictError';
  }
}

export class BusinessLogicError extends HobbyistError {
  constructor(message: string, rule: string, context?: Record<string, any>, requestId?: string) {
    super(message, 'BUSINESS_LOGIC_ERROR', 422, { rule, ...context }, requestId);
    this.name = 'BusinessLogicError';
  }
}

export class ExternalServiceError extends HobbyistError {
  constructor(service: string, message: string, originalError?: any, context?: Record<string, any>, requestId?: string) {
    super(`${service} error: ${message}`, 'EXTERNAL_SERVICE_ERROR', 502, { 
      service, 
      original_error: originalError?.message || originalError,
      ...context 
    }, requestId);
    this.name = 'ExternalServiceError';
  }
}

export class RateLimitError extends HobbyistError {
  constructor(limit: number, window: number, context?: Record<string, any>, requestId?: string) {
    super(`Rate limit exceeded: ${limit} requests per ${window}ms`, 'RATE_LIMIT_ERROR', 429, { 
      limit, 
      window,
      ...context 
    }, requestId);
    this.name = 'RateLimitError';
  }
}

export class MaintenanceError extends HobbyistError {
  constructor(message = 'Service temporarily unavailable for maintenance', estimatedRestore?: string, context?: Record<string, any>, requestId?: string) {
    super(message, 'MAINTENANCE_ERROR', 503, { estimated_restore: estimatedRestore, ...context }, requestId);
    this.name = 'MaintenanceError';
  }
}

// Error handling utilities
export class ErrorHandler {
  private static errorCounts = new Map<string, number>();
  private static errorHistory: Array<{ error: HobbyistError; timestamp: Date }> = [];
  private static maxHistorySize = 1000;

  static handle(error: Error | HobbyistError, requestId?: string): HobbyistError {
    let hobbyistError: HobbyistError;

    if (error instanceof HobbyistError) {
      hobbyistError = error;
    } else {
      // Convert generic errors to HobbyistError
      hobbyistError = this.convertError(error, requestId);
    }

    // Log and track error
    this.logError(hobbyistError);
    this.trackError(hobbyistError);

    return hobbyistError;
  }

  private static convertError(error: Error, requestId?: string): HobbyistError {
    const message = error.message || 'An unexpected error occurred';
    let code = 'INTERNAL_ERROR';
    let statusCode = 500;
    let context: Record<string, any> = {};

    // Handle specific error types
    if (error.name === 'SupabaseError' || error.message.includes('supabase')) {
      code = 'DATABASE_ERROR';
      context.database = 'supabase';
    } else if (error.name === 'StripeError' || error.message.includes('stripe')) {
      code = 'PAYMENT_ERROR';
      context.payment_provider = 'stripe';
    } else if (error.name === 'TypeError') {
      code = 'TYPE_ERROR';
      statusCode = 400;
    } else if (error.name === 'ReferenceError') {
      code = 'REFERENCE_ERROR';
      statusCode = 500;
    } else if (error.message.includes('timeout')) {
      code = 'TIMEOUT_ERROR';
      statusCode = 408;
    } else if (error.message.includes('network')) {
      code = 'NETWORK_ERROR';
      statusCode = 502;
    }

    // Add stack trace for internal errors
    if (statusCode >= 500) {
      context.stack = error.stack;
      context.original_error = error.name;
    }

    return new HobbyistError(message, code, statusCode, context, requestId);
  }

  private static logError(error: HobbyistError): void {
    const logLevel = error.statusCode >= 500 ? 'ERROR' : 'WARN';
    const logData = {
      level: logLevel,
      error: error.toJSON(),
      user_agent: 'hobbyist-api',
      timestamp: new Date().toISOString(),
    };

    console.log(JSON.stringify(logData));

    // In production, you might send this to a logging service
    // await sendToLoggingService(logData);
  }

  private static trackError(error: HobbyistError): void {
    // Track error counts for monitoring
    const errorKey = `${error.code}_${error.statusCode}`;
    const currentCount = this.errorCounts.get(errorKey) || 0;
    this.errorCounts.set(errorKey, currentCount + 1);

    // Add to error history
    this.errorHistory.push({
      error,
      timestamp: new Date(),
    });

    // Trim history if it gets too large
    if (this.errorHistory.length > this.maxHistorySize) {
      this.errorHistory = this.errorHistory.slice(-this.maxHistorySize);
    }

    // Check for error patterns that might indicate issues
    this.checkErrorPatterns();
  }

  private static checkErrorPatterns(): void {
    const recentErrors = this.errorHistory.filter(
      entry => Date.now() - entry.timestamp.getTime() < 5 * 60 * 1000 // Last 5 minutes
    );

    // Alert if too many errors in a short time period
    if (recentErrors.length > 50) {
      console.warn(`High error rate detected: ${recentErrors.length} errors in the last 5 minutes`);
      // In production, you might trigger alerts here
    }

    // Check for specific error patterns
    const authErrors = recentErrors.filter(e => e.error.statusCode === 401 || e.error.statusCode === 403);
    if (authErrors.length > 20) {
      console.warn(`High authentication/authorization error rate: ${authErrors.length} auth errors`);
    }

    const serverErrors = recentErrors.filter(e => e.error.statusCode >= 500);
    if (serverErrors.length > 10) {
      console.warn(`High server error rate: ${serverErrors.length} server errors`);
    }
  }

  static getErrorStats(): {
    errorCounts: Record<string, number>;
    recentErrorCount: number;
    topErrors: Array<{ code: string; count: number }>;
  } {
    const recentErrors = this.errorHistory.filter(
      entry => Date.now() - entry.timestamp.getTime() < 60 * 60 * 1000 // Last hour
    );

    const topErrors = Array.from(this.errorCounts.entries())
      .map(([code, count]) => ({ code, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    return {
      errorCounts: Object.fromEntries(this.errorCounts),
      recentErrorCount: recentErrors.length,
      topErrors,
    };
  }

  static clearStats(): void {
    this.errorCounts.clear();
    this.errorHistory = [];
  }
}

// Retry mechanism for handling transient errors
export class RetryHandler {
  static async withRetry<T>(
    operation: () => Promise<T>,
    options: {
      maxRetries?: number;
      baseDelay?: number;
      maxDelay?: number;
      retryableErrors?: string[];
      onRetry?: (error: Error, attempt: number) => void;
    } = {}
  ): Promise<T> {
    const {
      maxRetries = 3,
      baseDelay = 1000,
      maxDelay = 30000,
      retryableErrors = [
        'TIMEOUT_ERROR',
        'NETWORK_ERROR',
        'DATABASE_ERROR',
        'EXTERNAL_SERVICE_ERROR',
        'RATE_LIMIT_ERROR',
      ],
      onRetry,
    } = options;

    let lastError: Error;
    
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error as Error;
        
        // Don't retry on the last attempt
        if (attempt === maxRetries) {
          break;
        }

        // Check if error is retryable
        const hobbyistError = error instanceof HobbyistError ? error : ErrorHandler.handle(error);
        const isRetryable = retryableErrors.includes(hobbyistError.code) || hobbyistError.statusCode >= 500;
        
        if (!isRetryable) {
          throw hobbyistError;
        }

        // Call onRetry callback
        if (onRetry) {
          onRetry(hobbyistError, attempt + 1);
        }

        // Calculate delay with exponential backoff
        const delay = Math.min(baseDelay * Math.pow(2, attempt), maxDelay);
        const jitter = Math.random() * 0.1 * delay; // Add up to 10% jitter
        
        await new Promise(resolve => setTimeout(resolve, delay + jitter));
      }
    }

    throw ErrorHandler.handle(lastError!);
  }
}

// Circuit breaker pattern for external service calls
export class CircuitBreaker {
  private failureCount = 0;
  private lastFailureTime?: Date;
  private state: 'closed' | 'open' | 'half-open' = 'closed';

  constructor(
    private readonly name: string,
    private readonly options: {
      failureThreshold?: number;
      recoveryTimeout?: number;
      monitoringPeriod?: number;
    } = {}
  ) {
    const {
      failureThreshold = 5,
      recoveryTimeout = 60000, // 1 minute
      monitoringPeriod = 120000, // 2 minutes
    } = options;

    this.options = { failureThreshold, recoveryTimeout, monitoringPeriod };
  }

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (this.shouldAttemptReset()) {
        this.state = 'half-open';
        console.log(`Circuit breaker ${this.name}: Attempting reset (half-open)`);
      } else {
        throw new ExternalServiceError(
          this.name,
          'Circuit breaker is open - service temporarily unavailable',
          undefined,
          {
            circuit_breaker_state: this.state,
            failure_count: this.failureCount,
            last_failure: this.lastFailureTime?.toISOString(),
          }
        );
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private shouldAttemptReset(): boolean {
    if (!this.lastFailureTime) return false;
    
    const timeSinceLastFailure = Date.now() - this.lastFailureTime.getTime();
    return timeSinceLastFailure >= (this.options.recoveryTimeout || 60000);
  }

  private onSuccess(): void {
    this.failureCount = 0;
    this.state = 'closed';
    if (this.state === 'half-open') {
      console.log(`Circuit breaker ${this.name}: Reset successful (closed)`);
    }
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = new Date();

    if (this.failureCount >= (this.options.failureThreshold || 5)) {
      this.state = 'open';
      console.warn(`Circuit breaker ${this.name}: Opened due to ${this.failureCount} failures`);
    }
  }

  getStatus(): {
    state: string;
    failureCount: number;
    lastFailureTime?: string;
  } {
    return {
      state: this.state,
      failureCount: this.failureCount,
      lastFailureTime: this.lastFailureTime?.toISOString(),
    };
  }
}

// Global error boundaries for uncaught errors
export function setupGlobalErrorHandling(): void {
  // Handle uncaught exceptions
  globalThis.addEventListener?.('error', (event) => {
    const error = ErrorHandler.handle(event.error || new Error('Uncaught exception'));
    console.error('Uncaught exception:', error.toJSON());
  });

  // Handle unhandled promise rejections
  globalThis.addEventListener?.('unhandledrejection', (event) => {
    const error = ErrorHandler.handle(event.reason || new Error('Unhandled promise rejection'));
    console.error('Unhandled promise rejection:', error.toJSON());
    event.preventDefault();
  });
}

// Error reporting utilities
export async function reportError(
  error: HobbyistError,
  additionalContext?: Record<string, any>
): Promise<void> {
  const errorReport = {
    ...error.toJSON(),
    additional_context: additionalContext,
    environment: Deno.env.get('ENVIRONMENT') || 'development',
    version: Deno.env.get('APP_VERSION') || 'unknown',
  };

  // In production, you would send this to an error tracking service
  // like Sentry, Bugsnag, or a custom error tracking endpoint
  console.log('Error report:', JSON.stringify(errorReport, null, 2));

  // Example: Send to Sentry
  // await sendToSentry(errorReport);

  // Example: Send to custom error tracking endpoint
  // await sendToErrorTracker(errorReport);
}

// Health check utilities that work with error patterns
export function getServiceHealth(): {
  status: 'healthy' | 'degraded' | 'unhealthy';
  errors: Array<{ service: string; status: string; lastError?: string }>;
  statistics: ReturnType<typeof ErrorHandler.getErrorStats>;
} {
  const stats = ErrorHandler.getErrorStats();
  const recentErrorRate = stats.recentErrorCount;
  
  let status: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
  
  if (recentErrorRate > 100) {
    status = 'unhealthy';
  } else if (recentErrorRate > 50) {
    status = 'degraded';
  }

  // Mock service statuses - in production, these would check actual services
  const services = [
    { service: 'database', status: 'healthy' },
    { service: 'stripe', status: 'healthy' },
    { service: 'sendgrid', status: 'healthy' },
    { service: 'storage', status: 'healthy' },
  ];

  return {
    status,
    errors: services,
    statistics: stats,
  };
}