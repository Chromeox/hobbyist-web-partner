import Foundation

/// Service for managing API rate limiting and request throttling
final class RateLimitingService {
    static let shared = RateLimitingService()
    
    // Rate limit configurations per endpoint
    private var rateLimits: [String: RateLimit] = [:]
    private let queue = DispatchQueue(label: "com.hobbyist.ratelimiting", attributes: .concurrent)
    
    // Default rate limits
    private let defaultRateLimits: [String: (requests: Int, window: TimeInterval)] = [
        "/auth": (10, 60),           // 10 requests per minute
        "/classes": (30, 60),         // 30 requests per minute
        "/bookings": (20, 60),        // 20 requests per minute
        "/payments": (5, 60),         // 5 requests per minute (sensitive)
        "/search": (60, 60),          // 60 requests per minute
        "/profile": (20, 60),         // 20 requests per minute
        "default": (100, 60)          // 100 requests per minute for others
    ]
    
    private init() {
        setupDefaultRateLimits()
    }
    
    // MARK: - Rate Limit Structure
    
    private class RateLimit {
        let maxRequests: Int
        let windowDuration: TimeInterval
        private var requestTimestamps: [Date] = []
        private let lock = NSLock()
        
        init(maxRequests: Int, windowDuration: TimeInterval) {
            self.maxRequests = maxRequests
            self.windowDuration = windowDuration
        }
        
        func canMakeRequest() -> (allowed: Bool, retryAfter: TimeInterval?) {
            lock.lock()
            defer { lock.unlock() }
            
            let now = Date()
            
            // Remove expired timestamps
            requestTimestamps = requestTimestamps.filter { timestamp in
                now.timeIntervalSince(timestamp) < windowDuration
            }
            
            // Check if under limit
            if requestTimestamps.count < maxRequests {
                requestTimestamps.append(now)
                return (true, nil)
            }
            
            // Calculate retry time
            if let oldestTimestamp = requestTimestamps.first {
                let retryAfter = windowDuration - now.timeIntervalSince(oldestTimestamp)
                return (false, max(0, retryAfter))
            }
            
            return (false, windowDuration)
        }
        
        func reset() {
            lock.lock()
            defer { lock.unlock() }
            requestTimestamps.removeAll()
        }
    }
    
    // MARK: - Setup
    
    private func setupDefaultRateLimits() {
        for (endpoint, limits) in defaultRateLimits {
            rateLimits[endpoint] = RateLimit(
                maxRequests: limits.requests,
                windowDuration: limits.window
            )
        }
    }
    
    // MARK: - Rate Limiting
    
    /// Check if request is allowed for endpoint
    func checkRateLimit(for endpoint: String) -> RateLimitResult {
        let key = normalizeEndpoint(endpoint)
        
        return queue.sync {
            let rateLimit = rateLimits[key] ?? rateLimits["default"]!
            let result = rateLimit.canMakeRequest()
            
            return RateLimitResult(
                allowed: result.allowed,
                retryAfter: result.retryAfter,
                limit: rateLimit.maxRequests,
                remaining: max(0, rateLimit.maxRequests - (result.allowed ? 1 : rateLimit.maxRequests)),
                resetTime: Date().addingTimeInterval(rateLimit.windowDuration)
            )
        }
    }
    
    /// Wait if rate limited (with timeout)
    func waitIfRateLimited(for endpoint: String, timeout: TimeInterval = 10) async throws {
        let result = checkRateLimit(for: endpoint)
        
        if !result.allowed {
            guard let retryAfter = result.retryAfter else {
                throw RateLimitError.rateLimitExceeded
            }
            
            let waitTime = min(retryAfter, timeout)
            
            if waitTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                
                // Try again after waiting
                let retryResult = checkRateLimit(for: endpoint)
                if !retryResult.allowed {
                    throw RateLimitError.rateLimitExceeded
                }
            }
        }
    }
    
    /// Reset rate limits for endpoint
    func resetRateLimit(for endpoint: String) {
        let key = normalizeEndpoint(endpoint)
        
        queue.async(flags: .barrier) {
            self.rateLimits[key]?.reset()
        }
    }
    
    /// Reset all rate limits
    func resetAllRateLimits() {
        queue.async(flags: .barrier) {
            for rateLimit in self.rateLimits.values {
                rateLimit.reset()
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Update rate limit for endpoint
    func updateRateLimit(for endpoint: String, maxRequests: Int, windowDuration: TimeInterval) {
        let key = normalizeEndpoint(endpoint)
        
        queue.async(flags: .barrier) {
            self.rateLimits[key] = RateLimit(
                maxRequests: maxRequests,
                windowDuration: windowDuration
            )
        }
    }
    
    // MARK: - Helpers
    
    private func normalizeEndpoint(_ endpoint: String) -> String {
        // Extract base path from URL
        if let url = URL(string: endpoint) {
            let path = url.path
            
            // Match to known endpoints
            for key in rateLimits.keys where key != "default" {
                if path.contains(key) {
                    return key
                }
            }
        }
        
        // Check if it's already a known key
        if rateLimits[endpoint] != nil {
            return endpoint
        }
        
        return "default"
    }
}

// MARK: - Request Throttling

/// Service for throttling burst requests
final class RequestThrottler {
    private let semaphore: DispatchSemaphore
    private let queue = DispatchQueue(label: "com.hobbyist.throttling")
    private var lastRequestTime: Date?
    private let minInterval: TimeInterval
    
    init(maxConcurrent: Int = 3, minInterval: TimeInterval = 0.1) {
        self.semaphore = DispatchSemaphore(value: maxConcurrent)
        self.minInterval = minInterval
    }
    
    /// Execute request with throttling
    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        // Wait for semaphore
        await withCheckedContinuation { continuation in
            queue.async {
                self.semaphore.wait()
                
                // Enforce minimum interval between requests
                if let lastTime = self.lastRequestTime {
                    let elapsed = Date().timeIntervalSince(lastTime)
                    if elapsed < self.minInterval {
                        Thread.sleep(forTimeInterval: self.minInterval - elapsed)
                    }
                }
                
                self.lastRequestTime = Date()
                continuation.resume()
            }
        }
        
        defer {
            semaphore.signal()
        }
        
        return try await operation()
    }
}

// MARK: - Exponential Backoff

/// Service for implementing exponential backoff retry logic
final class ExponentialBackoff {
    private let baseDelay: TimeInterval
    private let maxDelay: TimeInterval
    private let factor: Double
    private let jitter: Bool
    
    init(
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        factor: Double = 2.0,
        jitter: Bool = true
    ) {
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.factor = factor
        self.jitter = jitter
    }
    
    /// Calculate delay for retry attempt
    func delay(for attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        
        let exponentialDelay = baseDelay * pow(factor, Double(attempt - 1))
        var delay = min(exponentialDelay, maxDelay)
        
        if jitter {
            // Add random jitter (±25%)
            let jitterRange = delay * 0.25
            let randomJitter = Double.random(in: -jitterRange...jitterRange)
            delay += randomJitter
        }
        
        return max(0, delay)
    }
    
    /// Execute with retry and exponential backoff
    func execute<T>(
        maxAttempts: Int = 3,
        retryableErrors: Set<NetworkError> = [.timeout, .connectionLost, .serverError],
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch let error as NetworkError {
                lastError = error
                
                // Check if error is retryable
                guard retryableErrors.contains(error) else {
                    throw error
                }
                
                // Don't retry on last attempt
                if attempt < maxAttempts {
                    let delayTime = delay(for: attempt)
                    print("🔄 Retry attempt \(attempt) after \(String(format: "%.2f", delayTime))s")
                    try await Task.sleep(nanoseconds: UInt64(delayTime * 1_000_000_000))
                }
            } catch {
                // Non-network errors are not retried
                throw error
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
}

// MARK: - Supporting Types

struct RateLimitResult {
    let allowed: Bool
    let retryAfter: TimeInterval?
    let limit: Int
    let remaining: Int
    let resetTime: Date
    
    var headers: [String: String] {
        [
            "X-RateLimit-Limit": "\(limit)",
            "X-RateLimit-Remaining": "\(remaining)",
            "X-RateLimit-Reset": "\(Int(resetTime.timeIntervalSince1970))",
            "Retry-After": retryAfter != nil ? "\(Int(retryAfter!))" : ""
        ]
    }
}

enum RateLimitError: LocalizedError {
    case rateLimitExceeded
    case tooManyRequests(retryAfter: TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .tooManyRequests(let retryAfter):
            return "Too many requests. Please retry after \(Int(retryAfter)) seconds."
        }
    }
}

enum NetworkError: Error, Equatable {
    case timeout
    case connectionLost
    case serverError
    case clientError
    case unknown
}

// MARK: - Rate Limited Network Manager

/// Enhanced network manager with rate limiting and retry logic
final class RateLimitedNetworkManager {
    static let shared = RateLimitedNetworkManager()
    
    private let rateLimiter = RateLimitingService.shared
    private let throttler = RequestThrottler()
    private let backoff = ExponentialBackoff()
    private let session: URLSession
    
    private init() {
        // Use certificate pinned session
        self.session = CertificatePinningService.shared.createPinnedSession()
    }
    
    /// Perform rate-limited request with retry logic
    func request<T: Decodable>(
        _ url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type,
        maxRetries: Int = 3
    ) async throws -> T {
        // Check rate limit
        try await rateLimiter.waitIfRateLimited(for: url.path)
        
        // Execute with throttling and retry
        return try await throttler.execute {
            try await self.backoff.execute(maxAttempts: maxRetries) {
                try await self.performRequest(
                    url,
                    method: method,
                    headers: headers,
                    body: body,
                    responseType: responseType
                )
            }
        }
    }
    
    private func performRequest<T: Decodable>(
        _ url: URL,
        method: String,
        headers: [String: String]?,
        body: Data?,
        responseType: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Add headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        // Check for rate limit headers from server
        if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
           let retrySeconds = TimeInterval(retryAfter) {
            throw RateLimitError.tooManyRequests(retryAfter: retrySeconds)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(responseType, from: data)
        case 429:
            throw RateLimitError.rateLimitExceeded
        case 500...599:
            throw NetworkError.serverError
        case 400...499:
            throw NetworkError.clientError
        default:
            throw NetworkError.unknown
        }
    }
}