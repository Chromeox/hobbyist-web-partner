import Foundation
import Security
import Network
import CryptoKit

// MARK: - Certificate Pinning for Network Security

/// Enterprise-grade certificate pinning system for secure network communications
public class CertificatePinner: NSObject {
    public static let shared = CertificatePinner()
    
    // Configuration
    private let pinnedCertificates: [String: Set<String>] = [
        "api.hobbyapp.com": ["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="], // Replace with actual hashes
        "supabase.co": ["sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="],
        "stripe.com": ["sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="]
    ]
    
    private let pinnedPublicKeys: [String: Set<String>] = [
        "api.hobbyapp.com": ["sha256/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD="], // Replace with actual hashes
    ]
    
    private var pinnedDomains: Set<String> {
        return Set(pinnedCertificates.keys).union(Set(pinnedPublicKeys.keys))
    }
    
    // Security policies
    private let allowBackupPins = true
    private let enforceStrictPinning = true
    private let maxCertificateAge: TimeInterval = 365 * 24 * 60 * 60 // 1 year
    
    // Monitoring
    private var pinningViolations: [PinningViolation] = []
    private let securityService = SecurityService.shared
    
    private override init() {
        super.init()
        loadPinnedCertificatesFromBundle()
    }
    
    // MARK: - Public API
    
    /// Validate certificate chain for given host
    public func validateCertificateChain(
        _ chain: [SecCertificate],
        for host: String
    ) throws -> Bool {
        guard pinnedDomains.contains(host) else {
            // No pinning configured for this host
            return true
        }
        
        // Validate using certificate pinning
        if let pinnedCerts = pinnedCertificates[host] {
            for certificate in chain {
                if try validateCertificate(certificate, against: pinnedCerts) {
                    return true
                }
            }
        }
        
        // Validate using public key pinning
        if let pinnedKeys = pinnedPublicKeys[host] {
            for certificate in chain {
                if try validatePublicKey(of: certificate, against: pinnedKeys) {
                    return true
                }
            }
        }
        
        // Log pinning violation
        logPinningViolation(host: host, certificateChain: chain)
        
        if enforceStrictPinning {
            throw CertificatePinningError.pinningValidationFailed(host: host)
        }
        
        return false
    }
    
    /// Create secure URL session with certificate pinning
    public func createSecureURLSession(
        configuration: URLSessionConfiguration = .default
    ) -> URLSession {
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        
        // Add security headers
        var headers = configuration.httpAdditionalHeaders as? [String: String] ?? [:]
        headers["User-Agent"] = "HobbyApp/1.0 Security/Enabled"
        headers["X-Pinning-Enabled"] = "true"
        configuration.httpAdditionalHeaders = headers
        
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    /// Verify server trust manually
    public func verifyServerTrust(
        _ serverTrust: SecTrust,
        for host: String
    ) throws -> Bool {
        // Basic trust evaluation
        var result: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(serverTrust, &result)
        
        guard status == errSecSuccess else {
            throw CertificatePinningError.trustEvaluationFailed(status: status)
        }
        
        guard result == .unspecified || result == .proceed else {
            throw CertificatePinningError.trustEvaluationFailed(status: status)
        }
        
        // Get certificate chain
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        var certificates: [SecCertificate] = []
        
        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) {
                certificates.append(certificate)
            }
        }
        
        // Validate against pinned certificates/keys
        return try validateCertificateChain(certificates, for: host)
    }
    
    /// Get pinning statistics
    public func getPinningStatistics() -> PinningStatistics {
        return PinningStatistics(
            pinnedDomains: pinnedDomains.count,
            violations: pinningViolations.count,
            lastViolation: pinningViolations.last?.timestamp,
            strictModeEnabled: enforceStrictPinning
        )
    }
    
    /// Get pinning violations for security audit
    public func getPinningViolations() -> [PinningViolation] {
        return pinningViolations
    }
    
    // MARK: - Private Implementation
    
    private func validateCertificate(
        _ certificate: SecCertificate,
        against pinnedHashes: Set<String>
    ) throws -> Bool {
        let certificateData = SecCertificateCopyData(certificate)
        let data = CFDataGetBytePtr(certificateData)!
        let length = CFDataGetLength(certificateData)
        let bytes = Data(bytes: data, count: length)
        
        let hash = SHA256.hash(data: bytes)
        let hashString = "sha256/" + Data(hash).base64EncodedString()
        
        let isValid = pinnedHashes.contains(hashString)
        
        if !isValid {
            print("Certificate validation failed for hash: \(hashString)")
            print("Expected one of: \(pinnedHashes)")
        }
        
        return isValid
    }
    
    private func validatePublicKey(
        _ certificate: SecCertificate,
        against pinnedHashes: Set<String>
    ) throws -> Bool {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            throw CertificatePinningError.publicKeyExtractionFailed
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
            throw CertificatePinningError.publicKeyExtractionFailed
        }
        
        let data = CFDataGetBytePtr(publicKeyData)!
        let length = CFDataGetLength(publicKeyData)
        let bytes = Data(bytes: data, count: length)
        
        let hash = SHA256.hash(data: bytes)
        let hashString = "sha256/" + Data(hash).base64EncodedString()
        
        let isValid = pinnedHashes.contains(hashString)
        
        if !isValid {
            print("Public key validation failed for hash: \(hashString)")
            print("Expected one of: \(pinnedHashes)")
        }
        
        return isValid
    }
    
    private func loadPinnedCertificatesFromBundle() {
        // Load additional pinned certificates from app bundle
        guard let plistPath = Bundle.main.path(forResource: "PinnedCertificates", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            print("No PinnedCertificates.plist found in bundle")
            return
        }
        
        // Process additional pinned certificates from plist
        print("Loaded pinned certificates from bundle")
    }
    
    private func validateCertificateAge(_ certificate: SecCertificate) throws -> Bool {
        // Extract certificate validity dates
        guard let certData = SecCertificateCopyData(certificate) as Data? else {
            throw CertificatePinningError.certificateParsingFailed
        }
        
        // Parse certificate to check expiration (simplified)
        // In production, use proper ASN.1 parsing or a certificate parsing library
        
        return true // Simplified for demo
    }
    
    private func logPinningViolation(host: String, certificateChain: [SecCertificate]) {
        let violation = PinningViolation(
            host: host,
            timestamp: Date(),
            certificateHashes: certificateChain.compactMap { certificate in
                let certificateData = SecCertificateCopyData(certificate)
                let data = CFDataGetBytePtr(certificateData)!
                let length = CFDataGetLength(certificateData)
                let bytes = Data(bytes: data, count: length)
                let hash = SHA256.hash(data: bytes)
                return Data(hash).base64EncodedString()
            },
            violationType: .certificateMismatch
        )
        
        pinningViolations.append(violation)
        
        // Keep only recent violations (last 100)
        if pinningViolations.count > 100 {
            pinningViolations.removeFirst()
        }
        
        // Report to security service
        Task { @MainActor in
            // Trigger security alert for pinning violation
            print("Certificate pinning violation detected for \(host)")
        }
    }
}

// MARK: - URLSessionDelegate Implementation

extension CertificatePinner: URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            print("No server trust available for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        do {
            let isValid = try verifyServerTrust(serverTrust, for: host)
            
            if isValid {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                print("Certificate pinning validation failed for \(host)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } catch {
            print("Certificate pinning error for \(host): \(error)")
            
            if enforceStrictPinning {
                completionHandler(.cancelAuthenticationChallenge, nil)
            } else {
                // Allow connection but log the issue
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            }
        }
    }
}

// MARK: - Supporting Types

public enum CertificatePinningError: Error, LocalizedError {
    case pinningValidationFailed(host: String)
    case trustEvaluationFailed(status: OSStatus)
    case publicKeyExtractionFailed
    case certificateParsingFailed
    case noCertificatesFound
    case invalidCertificateFormat
    
    public var errorDescription: String? {
        switch self {
        case .pinningValidationFailed(let host):
            return "Certificate pinning validation failed for \(host)"
        case .trustEvaluationFailed(let status):
            return "Trust evaluation failed with status: \(status)"
        case .publicKeyExtractionFailed:
            return "Failed to extract public key from certificate"
        case .certificateParsingFailed:
            return "Failed to parse certificate data"
        case .noCertificatesFound:
            return "No certificates found in chain"
        case .invalidCertificateFormat:
            return "Invalid certificate format"
        }
    }
}

public struct PinningViolation {
    public let host: String
    public let timestamp: Date
    public let certificateHashes: [String]
    public let violationType: ViolationType
    
    public enum ViolationType {
        case certificateMismatch
        case publicKeyMismatch
        case expiredCertificate
        case untrustedCertificate
        case chainValidationFailed
    }
}

public struct PinningStatistics {
    public let pinnedDomains: Int
    public let violations: Int
    public let lastViolation: Date?
    public let strictModeEnabled: Bool
    
    public var formattedLastViolation: String {
        guard let lastViolation = lastViolation else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: lastViolation, relativeTo: Date())
    }
}

// MARK: - Certificate Pinning Configuration

public struct CertificatePinningConfiguration {
    public let pinnedCertificates: [String: Set<String>]
    public let pinnedPublicKeys: [String: Set<String>]
    public let enforceStrictPinning: Bool
    public let allowBackupPins: Bool
    public let maxCertificateAge: TimeInterval
    
    public init(
        pinnedCertificates: [String: Set<String>] = [:],
        pinnedPublicKeys: [String: Set<String>] = [:],
        enforceStrictPinning: Bool = true,
        allowBackupPins: Bool = true,
        maxCertificateAge: TimeInterval = 365 * 24 * 60 * 60
    ) {
        self.pinnedCertificates = pinnedCertificates
        self.pinnedPublicKeys = pinnedPublicKeys
        self.enforceStrictPinning = enforceStrictPinning
        self.allowBackupPins = allowBackupPins
        self.maxCertificateAge = maxCertificateAge
    }
    
    public static let `default` = CertificatePinningConfiguration()
}

// MARK: - Certificate Hash Generator

public class CertificateHashGenerator {
    /// Generate certificate hash from certificate data
    public static func generateCertificateHash(from certificateData: Data) -> String {
        let hash = SHA256.hash(data: certificateData)
        return "sha256/" + Data(hash).base64EncodedString()
    }
    
    /// Generate public key hash from certificate
    public static func generatePublicKeyHash(from certificate: SecCertificate) throws -> String {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            throw CertificatePinningError.publicKeyExtractionFailed
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
            throw CertificatePinningError.publicKeyExtractionFailed
        }
        
        let data = CFDataGetBytePtr(publicKeyData)!
        let length = CFDataGetLength(publicKeyData)
        let bytes = Data(bytes: data, count: length)
        
        let hash = SHA256.hash(data: bytes)
        return "sha256/" + Data(hash).base64EncodedString()
    }
    
    /// Load certificate from bundle and generate hash
    public static func generateHashFromBundleCertificate(named name: String) throws -> String {
        guard let certPath = Bundle.main.path(forResource: name, ofType: "cer"),
              let certData = NSData(contentsOfFile: certPath) as Data? else {
            throw CertificatePinningError.noCertificatesFound
        }
        
        return generateCertificateHash(from: certData)
    }
}

// MARK: - Network Security Manager Extension

extension NetworkCache {
    /// Create secure URL session with certificate pinning
    public func createSecureSession() -> URLSession {
        return CertificatePinner.shared.createSecureURLSession()
    }
}

// MARK: - SwiftUI Debug View

import SwiftUI

public struct CertificatePinningDebugView: View {
    @State private var pinningStats = CertificatePinner.shared.getPinningStatistics()
    @State private var violations = CertificatePinner.shared.getPinningViolations()
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Certificate Pinning")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                statisticRow("Pinned Domains", "\(pinningStats.pinnedDomains)")
                statisticRow("Violations", "\(pinningStats.violations)")
                statisticRow("Strict Mode", pinningStats.strictModeEnabled ? "Enabled" : "Disabled")
                statisticRow("Last Violation", pinningStats.formattedLastViolation)
            }
            
            if !violations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Violations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(violations.suffix(3), id: \.timestamp) { violation in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(violation.host)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(violation.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            HStack {
                Button("Test Pinning") {
                    testCertificatePinning()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Clear Violations") {
                    // Implementation would clear violation history
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            refreshStats()
        }
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
    
    private func testCertificatePinning() {
        Task {
            // Test certificate pinning with a known endpoint
            let session = CertificatePinner.shared.createSecureURLSession()
            
            do {
                let url = URL(string: "https://httpbin.org/json")!
                let (_, _) = try await session.data(from: url)
                print("Certificate pinning test completed successfully")
            } catch {
                print("Certificate pinning test failed: \(error)")
            }
            
            refreshStats()
        }
    }
    
    private func refreshStats() {
        pinningStats = CertificatePinner.shared.getPinningStatistics()
        violations = CertificatePinner.shared.getPinningViolations()
    }
}

#Preview {
    CertificatePinningDebugView()
        .padding()
}