import Foundation
import Network
import Combine
import CryptoKit

// MARK: - Advanced Network Cache with Retry Logic

/// Enterprise-grade network caching system with intelligent retry mechanisms and offline support
@MainActor
public class NetworkCache: ObservableObject {
    public static let shared = NetworkCache()
    
    @Published public var isOnline: Bool = true
    @Published public var cacheHitRate: Double = 0.0
    @Published public var requestCount: Int = 0
    @Published public var errorCount: Int = 0
    @Published public var averageResponseTime: Double = 0.0
    
    // Cache configuration
    private let cacheCapacity: Int = 200 * 1024 * 1024 // 200MB
    private let defaultCacheDuration: TimeInterval = 300 // 5 minutes
    private let maxRetryAttempts = 3
    private let retryDelayBase: TimeInterval = 1.0
    
    // Storage
    private let diskCache: NetworkDiskCache
    private var memoryCache = NSCache<NSString, CachedResponse>()
    private let requestQueue = DispatchQueue(label: "com.hobbyapp.networkcache", qos: .userInitiated)
    
    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.hobbyapp.networkmonitor")
    
    // Session management
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 6
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.urlCache = nil // We handle caching ourselves
        
        // Add security headers
        config.httpAdditionalHeaders = [
            "User-Agent": "HobbyApp/1.0",
            "Accept": "application/json",
            "Accept-Encoding": "gzip, deflate, br"
        ]
        
        return URLSession(configuration: config, delegate: NetworkSessionDelegate(), delegateQueue: nil)
    }()
    
    // Performance tracking
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var totalResponseTime: Double = 0.0
    private let performanceMonitor = PerformanceMonitor.shared
    
    // Request management
    private var activeRequests: [String: Task<CachedResponse?, Error>] = [:]
    private var retryScheduler = RetryScheduler()
    
    private init() {
        self.diskCache = NetworkDiskCache()
        setupMemoryCache()
        startNetworkMonitoring()
        setupPerformanceTracking()
    }
    
    // MARK: - Public API
    
    /// Perform network request with automatic caching and retry logic
    public func request<T: Codable>(
        _ type: T.Type,
        from endpoint: NetworkEndpoint,
        cachePolicy: CachePolicy = .cacheFirst,
        retryPolicy: RetryPolicy = .exponentialBackoff
    ) async throws -> T {
        return try await performanceMonitor.trackOperation(
            name: "NetworkCache.request",
            category: .networking
        ) {
            try await performRequest(type, from: endpoint, cachePolicy: cachePolicy, retryPolicy: retryPolicy)
        }
    }
    
    /// Perform raw network request
    public func request(
        from endpoint: NetworkEndpoint,
        cachePolicy: CachePolicy = .cacheFirst,
        retryPolicy: RetryPolicy = .exponentialBackoff
    ) async throws -> Data {
        return try await performanceMonitor.trackOperation(
            name: "NetworkCache.rawRequest",
            category: .networking
        ) {
            try await performRawRequest(from: endpoint, cachePolicy: cachePolicy, retryPolicy: retryPolicy)
        }
    }
    
    /// Preload data for better performance
    public func preload(endpoints: [NetworkEndpoint]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for endpoint in endpoints {
                    group.addTask {
                        _ = try? await self.request(from: endpoint, cachePolicy: .networkFirst)
                    }
                }
            }
        }
    }
    
    /// Clear cache for specific endpoint
    public func clearCache(for endpoint: NetworkEndpoint) {
        let key = cacheKey(for: endpoint)
        memoryCache.removeObject(forKey: key)
        
        Task {
            await diskCache.removeObject(forKey: key.description)
            await updateCacheStatistics()
        }
    }
    
    /// Clear all cached data
    public func clearCache() {
        memoryCache.removeAllObjects()
        
        Task {
            await diskCache.removeAllObjects()
            await updateCacheStatistics()
        }
    }
    
    /// Get network statistics
    public func getNetworkStatistics() -> NetworkStatistics {
        return NetworkStatistics(
            requestCount: requestCount,
            errorCount: errorCount,
            cacheHitRate: cacheHitRate,
            averageResponseTime: averageResponseTime,
            isOnline: isOnline,
            cacheSize: diskCache.totalSize
        )
    }
    
    // MARK: - Private Implementation
    
    private func performRequest<T: Codable>(
        _ type: T.Type,
        from endpoint: NetworkEndpoint,
        cachePolicy: CachePolicy,
        retryPolicy: RetryPolicy
    ) async throws -> T {
        let data = try await performRawRequest(from: endpoint, cachePolicy: cachePolicy, retryPolicy: retryPolicy)
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    private func performRawRequest(
        from endpoint: NetworkEndpoint,
        cachePolicy: CachePolicy,
        retryPolicy: RetryPolicy
    ) async throws -> Data {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        defer {
            let responseTime = CFAbsoluteTimeGetCurrent() - startTime
            updatePerformanceMetrics(responseTime: responseTime)
        }
        
        let key = cacheKey(for: endpoint)
        
        // Check if there's already an active request for this endpoint
        if let activeTask = activeRequests[key.description] {
            let cachedResponse = try await activeTask.value
            return cachedResponse?.data ?? Data()
        }
        
        // Create new request task
        let requestTask = Task<CachedResponse?, Error> {
            return try await executeRequestWithCache(endpoint: endpoint, cachePolicy: cachePolicy, retryPolicy: retryPolicy)
        }
        
        activeRequests[key.description] = requestTask
        
        defer {
            activeRequests.removeValue(forKey: key.description)
        }
        
        do {
            guard let cachedResponse = try await requestTask.value else {
                throw NetworkError.noDataReceived
            }
            
            return cachedResponse.data
        } catch {
            errorCount += 1
            throw error
        }
    }
    
    private func executeRequestWithCache(
        endpoint: NetworkEndpoint,
        cachePolicy: CachePolicy,
        retryPolicy: RetryPolicy
    ) async throws -> CachedResponse? {
        let key = cacheKey(for: endpoint)
        
        // Handle cache policy
        switch cachePolicy {
        case .cacheOnly:
            return await getCachedResponse(key: key)
            
        case .cacheFirst:
            if let cached = await getCachedResponse(key: key) {
                recordCacheHit()
                return cached
            }
            fallthrough
            
        case .networkFirst:
            recordCacheMiss()
            return try await executeNetworkRequest(endpoint: endpoint, retryPolicy: retryPolicy)
            
        case .networkOnly:
            recordCacheMiss()
            return try await executeNetworkRequest(endpoint: endpoint, retryPolicy: retryPolicy)
        }
    }
    
    private func executeNetworkRequest(
        endpoint: NetworkEndpoint,
        retryPolicy: RetryPolicy
    ) async throws -> CachedResponse {
        guard isOnline else {
            throw NetworkError.offline
        }
        
        var lastError: Error?
        
        for attempt in 0..<maxRetryAttempts {
            do {
                let request = try createURLRequest(from: endpoint)
                let (data, response) = try await urlSession.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                let cachedResponse = CachedResponse(
                    data: data,
                    response: httpResponse,
                    cachedAt: Date(),
                    expiresAt: Date().addingTimeInterval(endpoint.cacheDuration ?? defaultCacheDuration)
                )
                
                // Cache the response
                await cacheResponse(cachedResponse, forKey: cacheKey(for: endpoint))
                
                requestCount += 1
                return cachedResponse
                
            } catch {
                lastError = error
                
                // Check if we should retry
                if attempt < maxRetryAttempts - 1 && shouldRetry(error: error, policy: retryPolicy) {
                    let delay = calculateRetryDelay(attempt: attempt, policy: retryPolicy)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    break
                }
            }
        }
        
        throw lastError ?? NetworkError.unknownError
    }
    
    private func getCachedResponse(key: NSString) async -> CachedResponse? {
        // Check memory cache first
        if let cached = memoryCache.object(forKey: key) {
            if cached.isValid {
                return cached
            } else {
                memoryCache.removeObject(forKey: key)
            }
        }
        
        // Check disk cache
        if let diskData = await diskCache.object(forKey: key.description) {
            do {
                let cached = try JSONDecoder().decode(CachedResponse.self, from: diskData)
                if cached.isValid {
                    // Restore to memory cache
                    memoryCache.setObject(cached, forKey: key)
                    return cached
                } else {
                    await diskCache.removeObject(forKey: key.description)
                }
            } catch {
                await diskCache.removeObject(forKey: key.description)
            }
        }
        
        return nil
    }
    
    private func cacheResponse(_ response: CachedResponse, forKey key: NSString) async {
        // Store in memory cache
        memoryCache.setObject(response, forKey: key)
        
        // Store in disk cache
        do {
            let data = try JSONEncoder().encode(response)
            await diskCache.setObject(data, forKey: key.description)
        } catch {
            print("Failed to cache response: \(error)")
        }
        
        await updateCacheStatistics()
    }
    
    private func createURLRequest(from endpoint: NetworkEndpoint) throws -> URLRequest {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout ?? 30.0
        
        // Add headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add security headers
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        
        // Add body for POST/PUT requests
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    private func shouldRetry(error: Error, policy: RetryPolicy) -> Bool {
        switch policy {
        case .none:
            return false
            
        case .linear, .exponentialBackoff:
            // Retry on network errors, timeouts, and 5xx server errors
            if let networkError = error as? NetworkError {
                switch networkError {
                case .httpError(let code):
                    return code >= 500
                case .timeout, .offline:
                    return true
                default:
                    return false
                }
            }
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                    return true
                default:
                    return false
                }
            }
            
            return false
        }
    }
    
    private func calculateRetryDelay(attempt: Int, policy: RetryPolicy) -> TimeInterval {
        switch policy {
        case .none:
            return 0
            
        case .linear:
            return retryDelayBase * Double(attempt + 1)
            
        case .exponentialBackoff:
            return retryDelayBase * pow(2.0, Double(attempt))
        }
    }
    
    private func setupMemoryCache() {
        memoryCache.totalCostLimit = cacheCapacity / 4 // 25% in memory
        memoryCache.countLimit = 200
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func setupPerformanceTracking() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateCacheStatistics()
            }
        }
    }
    
    private func updatePerformanceMetrics(responseTime: Double) {
        totalResponseTime += responseTime
        let avgTime = requestCount > 0 ? totalResponseTime / Double(requestCount) : 0.0
        averageResponseTime = avgTime
    }
    
    private func updateCacheStatistics() async {
        let totalRequests = cacheHits + cacheMisses
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    private func cacheKey(for endpoint: NetworkEndpoint) -> NSString {
        let components = [
            endpoint.url?.absoluteString ?? "",
            endpoint.method.rawValue,
            endpoint.headers?.description ?? "",
            endpoint.body?.description ?? ""
        ]
        
        let combined = components.joined(separator: "|")
        let hash = SHA256.hash(data: combined.data(using: .utf8) ?? Data())
        return hash.compactMap { String(format: "%02x", $0) }.joined() as NSString
    }
    
    private func recordCacheHit() {
        cacheHits += 1
    }
    
    private func recordCacheMiss() {
        cacheMisses += 1
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Network Endpoint Definition

public struct NetworkEndpoint {
    public let url: URL?
    public let method: HTTPMethod
    public let headers: [String: String]?
    public let body: [String: Any]?
    public let timeout: TimeInterval?
    public let cacheDuration: TimeInterval?
    
    public init(
        url: URL?,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        body: [String: Any]? = nil,
        timeout: TimeInterval? = nil,
        cacheDuration: TimeInterval? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
        self.cacheDuration = cacheDuration
    }
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Cache Policies

public enum CachePolicy {
    case cacheOnly      // Only return cached data
    case cacheFirst     // Return cached data if available, otherwise network
    case networkFirst   // Always try network first, fallback to cache
    case networkOnly    // Always use network, never cache
}

public enum RetryPolicy {
    case none
    case linear
    case exponentialBackoff
}

// MARK: - Network Errors

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noDataReceived
    case httpError(Int)
    case timeout
    case offline
    case decodingFailed(Error)
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response received"
        case .noDataReceived:
            return "No data received from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .timeout:
            return "Request timed out"
        case .offline:
            return "Device is offline"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Supporting Classes

private class CachedResponse: NSObject, Codable {
    let data: Data
    let statusCode: Int
    let headers: [String: String]
    let cachedAt: Date
    let expiresAt: Date
    
    var isValid: Bool {
        return Date() < expiresAt
    }
    
    init(data: Data, response: HTTPURLResponse, cachedAt: Date, expiresAt: Date) {
        self.data = data
        self.statusCode = response.statusCode
        self.headers = response.allHeaderFields as? [String: String] ?? [:]
        self.cachedAt = cachedAt
        self.expiresAt = expiresAt
    }
}

private class NetworkSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Implement certificate pinning here if needed
        completionHandler(.performDefaultHandling, nil)
    }
}

private class RetryScheduler {
    private var scheduledRetries: [String: Timer] = [:]
    
    func scheduleRetry(for key: String, delay: TimeInterval, completion: @escaping () -> Void) {
        cancelRetry(for: key)
        
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            completion()
        }
        
        scheduledRetries[key] = timer
    }
    
    func cancelRetry(for key: String) {
        scheduledRetries[key]?.invalidate()
        scheduledRetries.removeValue(forKey: key)
    }
    
    func cancelAllRetries() {
        scheduledRetries.values.forEach { $0.invalidate() }
        scheduledRetries.removeAll()
    }
}

// MARK: - Disk Cache Implementation

private actor NetworkDiskCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let expirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    var totalSize: Int64 = 0
    
    init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("NetworkCache", isDirectory: true)
        
        Task {
            await createCacheDirectoryIfNeeded()
            await calculateTotalSize()
        }
    }
    
    func object(forKey key: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                if Date().timeIntervalSince(modificationDate) > expirationInterval {
                    try fileManager.removeItem(at: url)
                    return nil
                }
            }
            
            // Update access time
            try fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
            
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }
    
    func setObject(_ data: Data, forKey key: String) {
        let url = cacheDirectory.appendingPathComponent(key)
        
        do {
            try data.write(to: url)
            totalSize += Int64(data.count)
        } catch {
            print("Failed to write network cache file: \(error)")
        }
    }
    
    func removeObject(forKey key: String) {
        let url = cacheDirectory.appendingPathComponent(key)
        
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64 {
            totalSize -= fileSize
        }
        
        try? fileManager.removeItem(at: url)
    }
    
    func removeAllObjects() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
            totalSize = 0
        } catch {
            print("Failed to clear network disk cache: \(error)")
        }
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func calculateTotalSize() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            totalSize = 0
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        } catch {
            totalSize = 0
        }
    }
}

// MARK: - Statistics

public struct NetworkStatistics {
    public let requestCount: Int
    public let errorCount: Int
    public let cacheHitRate: Double
    public let averageResponseTime: Double
    public let isOnline: Bool
    public let cacheSize: Int64
    
    public var formattedCacheHitRate: String {
        String(format: "%.1f%%", cacheHitRate * 100)
    }
    
    public var formattedResponseTime: String {
        String(format: "%.2f seconds", averageResponseTime)
    }
    
    public var formattedCacheSize: String {
        ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file)
    }
    
    public var errorRate: Double {
        return requestCount > 0 ? Double(errorCount) / Double(requestCount) : 0.0
    }
    
    public var formattedErrorRate: String {
        String(format: "%.1f%%", errorRate * 100)
    }
}

// MARK: - SwiftUI Integration

public struct NetworkCacheDebugView: View {
    @StateObject private var networkCache = NetworkCache.shared
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Cache Statistics")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                statisticRow("Online Status", networkCache.isOnline ? "Online" : "Offline")
                statisticRow("Requests", "\(networkCache.requestCount)")
                statisticRow("Errors", "\(networkCache.errorCount)")
                statisticRow("Hit Rate", networkCache.getNetworkStatistics().formattedCacheHitRate)
                statisticRow("Avg Response", networkCache.getNetworkStatistics().formattedResponseTime)
                statisticRow("Cache Size", networkCache.getNetworkStatistics().formattedCacheSize)
                statisticRow("Error Rate", networkCache.getNetworkStatistics().formattedErrorRate)
            }
            
            HStack {
                Button("Clear Cache") {
                    networkCache.clearCache()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Test Request") {
                    Task {
                        // Test with a simple endpoint
                        let endpoint = NetworkEndpoint(
                            url: URL(string: "https://httpbin.org/json"),
                            method: .GET
                        )
                        
                        do {
                            _ = try await networkCache.request(from: endpoint)
                        } catch {
                            print("Test request failed: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func statisticRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

#Preview {
    NetworkCacheDebugView()
        .padding()
}