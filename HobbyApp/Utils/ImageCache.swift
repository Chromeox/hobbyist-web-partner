import Foundation
import SwiftUI
import Combine
import CryptoKit

// MARK: - Advanced Image Cache with Compression and Lazy Loading

/// Enterprise-grade image caching system with memory management and performance optimization
@MainActor
public class ImageCache: ObservableObject {
    public static let shared = ImageCache()
    
    @Published public var cacheHitRate: Double = 0.0
    @Published public var memoryUsage: Int64 = 0
    @Published public var diskUsage: Int64 = 0
    
    // Cache configuration
    private let memoryCapacity: Int = 100 * 1024 * 1024 // 100MB
    private let diskCapacity: Int = 500 * 1024 * 1024   // 500MB
    private let maxConcurrentDownloads = 6
    
    // Storage
    private var memoryCache = NSCache<NSString, CachedImage>()
    private let diskCache: DiskCache
    private let downloadQueue = DispatchQueue(label: "com.hobbyapp.imagecache", qos: .userInitiated)
    private let compressionQueue = DispatchQueue(label: "com.hobbyapp.imagecompression", qos: .utility)
    
    // Download management
    private var activeDownloads = Set<URL>()
    private var downloadTasks: [URL: URLSessionDataTask] = [:]
    private let downloadSemaphore: DispatchSemaphore
    
    // Performance tracking
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private let performanceMonitor = PerformanceMonitor.shared
    
    // Session configuration
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.urlCache = nil // We handle caching ourselves
        return URLSession(configuration: config)
    }()
    
    private init() {
        self.downloadSemaphore = DispatchSemaphore(value: maxConcurrentDownloads)
        self.diskCache = DiskCache()
        
        setupMemoryCache()
        setupMemoryWarningHandling()
        startCacheMaintenanceTimer()
        
        Task {
            await updateCacheStatistics()
        }
    }
    
    // MARK: - Public API
    
    /// Load image with automatic caching and optimization
    public func loadImage(from url: URL, quality: ImageQuality = .balanced) async -> UIImage? {
        return await performanceMonitor.trackOperation(
            name: "ImageCache.loadImage",
            category: .imageProcessing
        ) {
            await loadImageInternal(from: url, quality: quality)
        }
    }
    
    /// Preload images for better performance
    public func preloadImages(_ urls: [URL], quality: ImageQuality = .balanced) {
        Task {
            await performanceMonitor.trackOperation(
                name: "ImageCache.preloadImages",
                category: .imageProcessing
            ) {
                await withTaskGroup(of: Void.self) { group in
                    for url in urls {
                        group.addTask {
                            _ = await self.loadImageInternal(from: url, quality: quality)
                        }
                    }
                }
            }
        }
    }
    
    /// Clear specific image from cache
    public func removeImage(for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.removeObject(forKey: key)
        
        Task {
            await diskCache.removeObject(forKey: key.description)
            await updateCacheStatistics()
        }
    }
    
    /// Clear all cached images
    public func clearCache() {
        memoryCache.removeAllObjects()
        
        Task {
            await diskCache.removeAllObjects()
            await updateCacheStatistics()
        }
    }
    
    /// Clear expired cache entries
    public func clearExpiredCache() {
        Task {
            await diskCache.removeExpiredObjects()
            await updateCacheStatistics()
        }
    }
    
    /// Get cache statistics
    public func getCacheStatistics() -> CacheStatistics {
        return CacheStatistics(
            memoryUsage: memoryUsage,
            diskUsage: diskUsage,
            hitRate: cacheHitRate,
            totalHits: cacheHits,
            totalMisses: cacheMisses,
            memoryCapacity: Int64(memoryCapacity),
            diskCapacity: Int64(diskCapacity)
        )
    }
    
    // MARK: - Private Implementation
    
    private func loadImageInternal(from url: URL, quality: ImageQuality) async -> UIImage? {
        let key = cacheKey(for: url)
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            recordCacheHit()
            return await processImageForQuality(cachedImage.image, quality: quality)
        }
        
        // Check disk cache
        if let diskData = await diskCache.object(forKey: key.description),
           let image = UIImage(data: diskData) {
            
            // Store in memory cache for faster access
            let cachedImage = CachedImage(image: image, cost: diskData.count)
            memoryCache.setObject(cachedImage, forKey: key)
            
            recordCacheHit()
            return await processImageForQuality(image, quality: quality)
        }
        
        // Download from network
        recordCacheMiss()
        return await downloadImage(from: url, quality: quality)
    }
    
    private func downloadImage(from url: URL, quality: ImageQuality) async -> UIImage? {
        // Prevent duplicate downloads
        if activeDownloads.contains(url) {
            // Wait for existing download to complete
            return await waitForExistingDownload(url: url, quality: quality)
        }
        
        activeDownloads.insert(url)
        defer { activeDownloads.remove(url) }
        
        // Acquire download semaphore
        await downloadSemaphore.wait()
        defer { downloadSemaphore.signal() }
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            // Compress and cache the image
            await cacheImage(image, for: url, originalData: data)
            
            return await processImageForQuality(image, quality: quality)
            
        } catch {
            print("Failed to download image from \(url): \(error)")
            return nil
        }
    }
    
    private func waitForExistingDownload(url: URL, quality: ImageQuality) async -> UIImage? {
        // Poll for completion of existing download
        for _ in 0..<30 { // Wait up to 30 seconds
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            if !activeDownloads.contains(url) {
                // Download completed, try loading from cache
                return await loadImageInternal(from: url, quality: quality)
            }
        }
        
        return nil
    }
    
    private func cacheImage(_ image: UIImage, for url: URL, originalData: Data) async {
        let key = cacheKey(for: url)
        
        // Compress image for different quality levels
        let compressedData = await compressImage(image, originalData: originalData)
        
        // Store in memory cache
        let cachedImage = CachedImage(image: image, cost: compressedData.count)
        memoryCache.setObject(cachedImage, forKey: key)
        
        // Store in disk cache
        await diskCache.setObject(compressedData, forKey: key.description)
        
        await updateCacheStatistics()
    }
    
    private func compressImage(_ image: UIImage, originalData: Data) async -> Data {
        return await withCheckedContinuation { continuation in
            compressionQueue.async {
                // Try to use original data if it's already compressed efficiently
                if originalData.count < 1024 * 1024 { // Less than 1MB
                    continuation.resume(returning: originalData)
                    return
                }
                
                // Compress the image
                var compressionQuality: CGFloat = 0.8
                var compressedData = image.jpegData(compressionQuality: compressionQuality) ?? originalData
                
                // Reduce quality until we reach a reasonable size
                while compressedData.count > 512 * 1024 && compressionQuality > 0.1 {
                    compressionQuality -= 0.1
                    if let newData = image.jpegData(compressionQuality: compressionQuality) {
                        compressedData = newData
                    }
                }
                
                continuation.resume(returning: compressedData)
            }
        }
    }
    
    private func processImageForQuality(_ image: UIImage, quality: ImageQuality) async -> UIImage {
        switch quality {
        case .thumbnail:
            return await resizeImage(image, maxDimension: 150)
        case .low:
            return await resizeImage(image, maxDimension: 300)
        case .balanced:
            return await resizeImage(image, maxDimension: 600)
        case .high:
            return await resizeImage(image, maxDimension: 1200)
        case .original:
            return image
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) async -> UIImage {
        return await withCheckedContinuation { continuation in
            compressionQueue.async {
                let size = image.size
                let aspectRatio = size.width / size.height
                
                var newSize: CGSize
                if size.width > size.height {
                    newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                } else {
                    newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                }
                
                // Don't upscale images
                if newSize.width >= size.width && newSize.height >= size.height {
                    continuation.resume(returning: image)
                    return
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
                
                continuation.resume(returning: resizedImage)
            }
        }
    }
    
    private func setupMemoryCache() {
        memoryCache.totalCostLimit = memoryCapacity
        memoryCache.countLimit = 100 // Maximum number of images
        memoryCache.evictsObjectsWithDiscardedContent = true
    }
    
    private func setupMemoryWarningHandling() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        NotificationCenter.default.addObserver(
            forName: .memoryPressureDetected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryPressure()
        }
    }
    
    private func startCacheMaintenanceTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performCacheMaintenance()
            }
        }
    }
    
    private func performCacheMaintenance() async {
        await clearExpiredCache()
        await updateCacheStatistics()
        
        // Trim disk cache if it exceeds capacity
        if diskUsage > diskCapacity {
            await diskCache.trimToSize(Int64(diskCapacity * 8 / 10)) // Trim to 80% of capacity
        }
    }
    
    private func updateCacheStatistics() async {
        memoryUsage = Int64(memoryCache.totalCostLimit)
        diskUsage = await diskCache.totalSize()
        
        let totalRequests = cacheHits + cacheMisses
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    private func cacheKey(for url: URL) -> NSString {
        let hash = SHA256.hash(data: url.absoluteString.data(using: .utf8) ?? Data())
        return hash.compactMap { String(format: "%02x", $0) }.joined() as NSString
    }
    
    private func recordCacheHit() {
        cacheHits += 1
    }
    
    private func recordCacheMiss() {
        cacheMisses += 1
    }
    
    private func handleMemoryWarning() {
        // Clear half of the memory cache
        let currentCount = memoryCache.countLimit
        memoryCache.countLimit = currentCount / 2
        memoryCache.countLimit = currentCount
    }
    
    private func handleMemoryPressure() {
        // More aggressive memory cleanup
        memoryCache.removeAllObjects()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Disk Cache Implementation

private actor DiskCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        Task {
            await createCacheDirectoryIfNeeded()
        }
    }
    
    func object(forKey key: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        // Check if file has expired
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                if Date().timeIntervalSince(modificationDate) > expirationInterval {
                    try fileManager.removeItem(at: url)
                    return nil
                }
            }
            
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }
    
    func setObject(_ data: Data, forKey key: String) {
        let url = cacheDirectory.appendingPathComponent(key)
        
        do {
            try data.write(to: url)
        } catch {
            print("Failed to write cache file: \(error)")
        }
    }
    
    func removeObject(forKey key: String) {
        let url = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: url)
    }
    
    func removeAllObjects() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("Failed to clear disk cache: \(error)")
        }
    }
    
    func removeExpiredObjects() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey])
                if let modificationDate = resourceValues.contentModificationDate {
                    if Date().timeIntervalSince(modificationDate) > expirationInterval {
                        try fileManager.removeItem(at: url)
                    }
                }
            }
        } catch {
            print("Failed to remove expired cache objects: \(error)")
        }
    }
    
    func totalSize() -> Int64 {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            var totalSize: Int64 = 0
            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
    
    func trimToSize(_ targetSize: Int64) {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentAccessDateKey]
            )
            
            // Sort by access date (oldest first)
            let sortedContents = contents.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? Date.distantPast
                return date1 < date2
            }
            
            var currentSize = totalSize()
            
            for url in sortedContents {
                if currentSize <= targetSize {
                    break
                }
                
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = Int64(resourceValues.fileSize ?? 0)
                
                try fileManager.removeItem(at: url)
                currentSize -= fileSize
            }
        } catch {
            print("Failed to trim disk cache: \(error)")
        }
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Supporting Types

private class CachedImage {
    let image: UIImage
    let cost: Int
    let timestamp: Date
    
    init(image: UIImage, cost: Int) {
        self.image = image
        self.cost = cost
        self.timestamp = Date()
    }
}

public enum ImageQuality: String, CaseIterable {
    case thumbnail = "Thumbnail"
    case low = "Low"
    case balanced = "Balanced"
    case high = "High"
    case original = "Original"
    
    public var description: String {
        switch self {
        case .thumbnail:
            return "Thumbnail (150px)"
        case .low:
            return "Low Quality (300px)"
        case .balanced:
            return "Balanced (600px)"
        case .high:
            return "High Quality (1200px)"
        case .original:
            return "Original Size"
        }
    }
    
    public var maxDimension: CGFloat {
        switch self {
        case .thumbnail:
            return 150
        case .low:
            return 300
        case .balanced:
            return 600
        case .high:
            return 1200
        case .original:
            return .greatestFiniteMagnitude
        }
    }
}

public struct CacheStatistics {
    public let memoryUsage: Int64
    public let diskUsage: Int64
    public let hitRate: Double
    public let totalHits: Int
    public let totalMisses: Int
    public let memoryCapacity: Int64
    public let diskCapacity: Int64
    
    public var formattedMemoryUsage: String {
        ByteCountFormatter.string(fromByteCount: memoryUsage, countStyle: .memory)
    }
    
    public var formattedDiskUsage: String {
        ByteCountFormatter.string(fromByteCount: diskUsage, countStyle: .file)
    }
    
    public var formattedHitRate: String {
        String(format: "%.1f%%", hitRate * 100)
    }
}

// MARK: - SwiftUI Integration

public struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let quality: ImageQuality
    private let content: (AsyncImagePhase) -> Content
    
    @StateObject private var imageCache = ImageCache.shared
    @State private var phase: AsyncImagePhase = .empty
    
    public init(
        url: URL?,
        quality: ImageQuality = .balanced,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.quality = quality
        self.content = content
    }
    
    public var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
            .onChange(of: url) { _ in
                loadImage()
            }
    }
    
    private func loadImage() {
        guard let url = url else {
            phase = .empty
            return
        }
        
        phase = .empty
        
        Task {
            if let image = await imageCache.loadImage(from: url, quality: quality) {
                await MainActor.run {
                    phase = .success(Image(uiImage: image))
                }
            } else {
                await MainActor.run {
                    phase = .failure(ImageCacheError.downloadFailed)
                }
            }
        }
    }
}

// Convenience initializer for simple use cases
public extension CachedAsyncImage where Content == _ConditionalContent<_ConditionalContent<Image, ProgressView<EmptyView, EmptyView>>, Image> {
    init(url: URL?, quality: ImageQuality = .balanced) {
        self.init(url: url, quality: quality) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure(_):
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
}

public enum ImageCacheError: Error, LocalizedError {
    case downloadFailed
    case invalidImageData
    case diskWriteError
    
    public var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download image"
        case .invalidImageData:
            return "Invalid image data"
        case .diskWriteError:
            return "Failed to write image to disk"
        }
    }
}

// MARK: - Cache Debug View

public struct ImageCacheDebugView: View {
    @StateObject private var imageCache = ImageCache.shared
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Image Cache Statistics")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                statisticRow("Hit Rate", imageCache.getCacheStatistics().formattedHitRate)
                statisticRow("Memory Usage", imageCache.getCacheStatistics().formattedMemoryUsage)
                statisticRow("Disk Usage", imageCache.getCacheStatistics().formattedDiskUsage)
                statisticRow("Total Hits", "\(imageCache.getCacheStatistics().totalHits)")
                statisticRow("Total Misses", "\(imageCache.getCacheStatistics().totalMisses)")
            }
            
            HStack {
                Button("Clear Cache") {
                    imageCache.clearCache()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Clear Expired") {
                    imageCache.clearExpiredCache()
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
    VStack {
        ImageCacheDebugView()
        
        Spacer()
        
        // Example usage
        CachedAsyncImage(
            url: URL(string: "https://picsum.photos/400/300"),
            quality: .balanced
        )
        .frame(width: 200, height: 150)
        .cornerRadius(8)
    }
    .padding()
}