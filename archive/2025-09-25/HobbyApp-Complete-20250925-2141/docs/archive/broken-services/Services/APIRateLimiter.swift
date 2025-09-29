import Foundation

/// API Rate Limiter using Token Bucket algorithm
/// Prevents API abuse and provides client-side throttling
final class APIRateLimiter {
    
    static let shared = APIRateLimiter()
    
    // MARK: - Rate Limit Configuration
    
    struct RateLimitConfig {
        let endpoint: String
        let maxRequests: Int
        let windowSeconds: TimeInterval
        let burstCapacity: Int
        
        static let defaults: [RateLimitConfig] = [
            // Authentication endpoints - strict limits
            RateLimitConfig(endpoint: "/auth/login", maxRequests: 5, windowSeconds: 300, burstCapacity: 2),
            RateLimitConfig(endpoint: "/auth/signup", maxRequests: 3, windowSeconds: 3600, burstCapacity: 1),
            RateLimitConfig(endpoint: "/auth/reset", maxRequests: 3, windowSeconds: 900, burstCapacity: 1),
            
            // Booking endpoints - moderate limits
            RateLimitConfig(endpoint: "/bookings/create", maxRequests: 10, windowSeconds: 60, burstCapacity: 3),
            RateLimitConfig(endpoint: "/bookings/cancel", maxRequests: 5, windowSeconds: 60, burstCapacity: 2),
            
            // Read endpoints - relaxed limits
            RateLimitConfig(endpoint: "/classes", maxRequests: 60, windowSeconds: 60, burstCapacity: 10),
            RateLimitConfig(endpoint: "/schedules", maxRequests: 60, windowSeconds: 60, burstCapacity: 10),
            
            // Payment endpoints - strict limits
            RateLimitConfig(endpoint: "/payments", maxRequests: 5, windowSeconds: 60, burstCapacity: 1),
            RateLimitConfig(endpoint: "/subscriptions", maxRequests: 5, windowSeconds: 60, burstCapacity: 1),
            
            // Default for unspecified endpoints
            RateLimitConfig(endpoint: "*", maxRequests: 30, windowSeconds: 60, burstCapacity: 5)
        ]
    }
    
    // MARK: - Token Bucket Implementation
    
    private class TokenBucket {
        private let capacity: Int
        private let refillRate: Double // tokens per second
        private var tokens: Double
        private var lastRefill: Date
        private let queue = DispatchQueue(label: "com.hobbyist.ratelimit", attributes: .concurrent)
        
        init(capacity: Int, refillRate: Double) {
            self.capacity = capacity
            self.refillRate = refillRate
            self.tokens = Double(capacity)
            self.lastRefill = Date()
        }
        
        func tryConsume(tokens: Int = 1) -> Bool {
            queue.sync(flags: .barrier) {
                refill()
                
                if self.tokens >= Double(tokens) {
                    self.tokens -= Double(tokens)
                    return true
                }
                
                return false
            }
        }
        
        func availableTokens() -> Int {
            queue.sync {
                refill()
                return Int(tokens)
            }
        }
        
        func timeUntilNextToken() -> TimeInterval? {
            queue.sync {
                refill()
                
                if tokens >= 1 {
                    return nil
                }
                
                let tokensNeeded = 1 - tokens
                return tokensNeeded / refillRate
            }
        }
        
        private func refill() {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastRefill)
            let tokensToAdd = elapsed * refillRate
            
            tokens = min(Double(capacity), tokens + tokensToAdd)
            lastRefill = now
        }
    }
    
    // MARK: - Rate Limiter State
    
    private var buckets: [String: TokenBucket] = [:]
    private let bucketsQueue = DispatchQueue(label: "com.hobbyist.ratelimit.buckets", attributes: .concurrent)
    
    private init() {
        setupDefaultBuckets()
    }
    
    private func setupDefaultBuckets() {
        for config in RateLimitConfig.defaults {
            let refillRate = Double(config.maxRequests) / config.windowSeconds
            let bucket = TokenBucket(
                capacity: config.burstCapacity,
                refillRate: refillRate
            )
            
            bucketsQueue.async(flags: .barrier) {
                self.buckets[config.endpoint] = bucket
            }
        }
    }
    
    // MARK: - Public API
    
    /// Check if a request to the endpoint is allowed
    func shouldAllowRequest(to endpoint: String) -> Bool {
        let bucket = getBucket(for: endpoint)
        return bucket.tryConsume()
    }
    
    /// Wait for rate limit if needed
    func waitForRateLimit(endpoint: String) async throws {
        let bucket = getBucket(for: endpoint)
        
        while !bucket.tryConsume() {
            if let waitTime = bucket.timeUntilNextToken() {
                // Add small buffer to avoid race conditions
                let sleepTime = waitTime + 0.1
                
                // Log rate limit hit
                logRateLimitHit(endpoint: endpoint, waitTime: sleepTime)
                
                // Wait for token to be available
                try await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
            } else {
                // Token should be available now
                break
            }
        }
    }
    
    /// Get current rate limit status for endpoint
    func getRateLimitStatus(for endpoint: String) -> RateLimitStatus {
        let bucket = getBucket(for: endpoint)
        let config = getConfig(for: endpoint)
        
        return RateLimitStatus(
            endpoint: endpoint,
            availableTokens: bucket.availableTokens(),
            maxTokens: config.burstCapacity,
            resetsIn: bucket.timeUntilNextToken()
        )
    }
    
    /// Reset rate limit for endpoint (admin use)
    func resetRateLimit(for endpoint: String) {
        bucketsQueue.async(flags: .barrier) {
            if let config = RateLimitConfig.defaults.first(where: { $0.endpoint == endpoint }) {
                let refillRate = Double(config.maxRequests) / config.windowSeconds
                self.buckets[endpoint] = TokenBucket(
                    capacity: config.burstCapacity,
                    refillRate: refillRate
                )
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getBucket(for endpoint: String) -> TokenBucket {
        bucketsQueue.sync {
            // Try exact match first
            if let bucket = buckets[endpoint] {
                return bucket
            }
            
            // Fall back to wildcard
            if let defaultBucket = buckets["*"] {
                return defaultBucket
            }
            
            // This shouldn't happen, but create default if needed
            let config = RateLimitConfig.defaults.last!
            let refillRate = Double(config.maxRequests) / config.windowSeconds
            return TokenBucket(
                capacity: config.burstCapacity,
                refillRate: refillRate
            )
        }
    }
    
    private func getConfig(for endpoint: String) -> RateLimitConfig {
        if let config = RateLimitConfig.defaults.first(where: { $0.endpoint == endpoint }) {
            return config
        }
        return RateLimitConfig.defaults.last! // Default config
    }
    
    private func logRateLimitHit(endpoint: String, waitTime: TimeInterval) {
        #if DEBUG
        print("⏱️ Rate limit hit for \(endpoint). Waiting \(String(format: "%.2f", waitTime))s")
        #endif
        
        // Log to security monitor
        SecurityMonitor.shared.logEvent(
            type: .rateLimitExceeded,
            severity: .medium,
            metadata: [
                "endpoint": endpoint,
                "wait_time": String(waitTime)
            ]
        )
    }
}

// MARK: - Rate Limit Status

struct RateLimitStatus {
    let endpoint: String
    let availableTokens: Int
    let maxTokens: Int
    let resetsIn: TimeInterval?
    
    var isLimited: Bool {
        availableTokens == 0
    }
    
    var percentageAvailable: Double {
        guard maxTokens > 0 else { return 0 }
        return Double(availableTokens) / Double(maxTokens)
    }
}

// MARK: - Network Extension with Rate Limiting

extension SupabaseService {
    
    /// Make a rate-limited request
    func rateLimitedRequest<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: Data? = nil
    ) async throws -> T {
        // Check rate limit
        let rateLimiter = APIRateLimiter.shared
        
        // Wait if rate limited
        try await rateLimiter.waitForRateLimit(endpoint: endpoint)
        
        // Make the actual request
        return try await request(endpoint, method: method, body: body)
    }
    
    /// Check if request would be rate limited
    func wouldBeRateLimited(endpoint: String) -> Bool {
        let status = APIRateLimiter.shared.getRateLimitStatus(for: endpoint)
        return status.isLimited
    }
}

// MARK: - Rate Limit Middleware

protocol RateLimitMiddleware {
    func shouldProceed(with request: URLRequest) async -> Bool
    func didComplete(request: URLRequest, response: HTTPURLResponse?)
}

class AdaptiveRateLimiter: RateLimitMiddleware {
    
    private let rateLimiter = APIRateLimiter.shared
    private var serverRateLimits: [String: ServerRateLimit] = [:]
    private let queue = DispatchQueue(label: "com.hobbyist.adaptive.ratelimit")
    
    struct ServerRateLimit {
        let remaining: Int
        let reset: Date
        let limit: Int
    }
    
    func shouldProceed(with request: URLRequest) async -> Bool {
        guard let url = request.url,
              let endpoint = extractEndpoint(from: url) else {
            return true
        }
        
        // Check server-reported limits first
        if let serverLimit = getServerLimit(for: endpoint) {
            if serverLimit.remaining <= 0 && serverLimit.reset > Date() {
                // Wait until reset time
                let waitTime = serverLimit.reset.timeIntervalSinceNow
                if waitTime > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                }
            }
        }
        
        // Check local rate limits
        return rateLimiter.shouldAllowRequest(to: endpoint)
    }
    
    func didComplete(request: URLRequest, response: HTTPURLResponse?) {
        guard let response = response,
              let url = request.url,
              let endpoint = extractEndpoint(from: url) else {
            return
        }
        
        // Parse rate limit headers from server
        if let limitStr = response.value(forHTTPHeaderField: "X-RateLimit-Limit"),
           let limit = Int(limitStr),
           let remainingStr = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let remaining = Int(remainingStr),
           let resetStr = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let resetTimestamp = TimeInterval(resetStr) {
            
            let serverLimit = ServerRateLimit(
                remaining: remaining,
                reset: Date(timeIntervalSince1970: resetTimestamp),
                limit: limit
            )
            
            queue.async {
                self.serverRateLimits[endpoint] = serverLimit
            }
            
            // Adapt local limits if server is more restrictive
            if remaining < 5 {
                print("⚠️ Low rate limit for \(endpoint): \(remaining) remaining")
            }
        }
        
        // Check for rate limit errors
        if response.statusCode == 429 {
            handleRateLimitError(for: endpoint, response: response)
        }
    }
    
    private func extractEndpoint(from url: URL) -> String? {
        return url.path
    }
    
    private func getServerLimit(for endpoint: String) -> ServerRateLimit? {
        queue.sync {
            return serverRateLimits[endpoint]
        }
    }
    
    private func handleRateLimitError(for endpoint: String, response: HTTPURLResponse) {
        // Parse retry-after header
        let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
            .flatMap { Int($0) } ?? 60
        
        print("🛑 Rate limit exceeded for \(endpoint). Retry after \(retryAfter)s")
        
        // Update local tracking
        queue.async {
            self.serverRateLimits[endpoint] = ServerRateLimit(
                remaining: 0,
                reset: Date().addingTimeInterval(TimeInterval(retryAfter)),
                limit: 0
            )
        }
        
        // Log security event
        SecurityMonitor.shared.logEvent(
            type: .rateLimitExceeded,
            severity: .high,
            metadata: [
                "endpoint": endpoint,
                "retry_after": String(retryAfter),
                "status": "429"
            ]
        )
    }
}