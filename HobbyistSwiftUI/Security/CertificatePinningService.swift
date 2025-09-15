import Foundation
import CryptoKit
import Security

/// Service for implementing certificate pinning to prevent man-in-the-middle attacks
final class CertificatePinningService: NSObject {
    static let shared = CertificatePinningService()
    
    // Certificate hashes for pinning (SHA256 of the certificate's public key)
    // These should be updated when certificates are rotated
    private var pinnedCertificates: Set<String> = []
    
    private override init() {
        super.init()
        loadPinnedCertificates()
    }
    
    private func loadPinnedCertificates() {
        // Load certificate pins from secure configuration
        if let pins = AppConfiguration.shared.getCertificatePins() {
            pinnedCertificates = Set(pins)
        } else {
            // Default pins for Supabase (these are examples - replace with actual values)
            pinnedCertificates = [
                // Add your actual certificate SHA256 hashes here
                // You can get these by running: openssl s_client -connect your-domain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
            ]
        }
    }
    
    /// Create a pinned URLSession
    func createPinnedSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        let session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
        
        return session
    }
    
    /// Validate a server trust against pinned certificates
    func validateServerTrust(_ serverTrust: SecTrust, for domain: String) -> Bool {
        // Skip pinning in development mode
        #if DEBUG
        if AppConfiguration.shared.current?.environment == .development {
            return true
        }
        #endif
        
        // Evaluate the server trust
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        guard isValid else {
            print("❌ Server trust evaluation failed: \(error?.localizedDescription ?? "Unknown error")")
            return false
        }
        
        // Get the certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              !certificateChain.isEmpty else {
            print("❌ No certificate chain found")
            return false
        }
        
        // Check each certificate in the chain
        for certificate in certificateChain {
            if validateCertificate(certificate) {
                return true
            }
        }
        
        print("❌ No pinned certificate matched")
        return false
    }
    
    private func validateCertificate(_ certificate: SecCertificate) -> Bool {
        // Get the public key from the certificate
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return false
        }
        
        // Get the public key data
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return false
        }
        
        // Calculate SHA256 hash of the public key
        let hash = SHA256.hash(data: publicKeyData)
        let hashString = Data(hash).base64EncodedString()
        
        // Check if this hash matches any of our pinned certificates
        let isPinned = pinnedCertificates.contains(hashString)
        
        if isPinned {
            print("✅ Certificate pinning validated successfully")
        }
        
        return isPinned
    }
    
    /// Add a new certificate pin at runtime (useful for certificate rotation)
    func addCertificatePin(_ pin: String) {
        pinnedCertificates.insert(pin)
    }
    
    /// Remove a certificate pin (useful for certificate rotation)
    func removeCertificatePin(_ pin: String) {
        pinnedCertificates.remove(pin)
    }
    
    /// Update all certificate pins
    func updateCertificatePins(_ pins: [String]) {
        pinnedCertificates = Set(pins)
    }
}

// MARK: - URLSessionDelegate

extension CertificatePinningService: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        if validateServerTrust(serverTrust, for: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Network Security Configuration

/// Enhanced network security manager with certificate pinning
final class SecureNetworkManager {
    static let shared = SecureNetworkManager()
    
    private let session: URLSession
    private let certificatePinner = CertificatePinningService.shared
    
    private init() {
        self.session = certificatePinner.createPinnedSession()
    }
    
    /// Perform a secure request with certificate pinning
    func secureRequest<T: Decodable>(
        _ url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Add security headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add request signature for additional security
        if let signature = generateRequestSignature(for: request) {
            request.setValue(signature, forHTTPHeaderField: "X-Request-Signature")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(responseType, from: data)
    }
    
    /// Generate HMAC signature for request integrity
    private func generateRequestSignature(for request: URLRequest) -> String? {
        guard let url = request.url?.absoluteString,
              let method = request.httpMethod else {
            return nil
        }
        
        // Create signature payload
        let timestamp = Int(Date().timeIntervalSince1970)
        let nonce = UUID().uuidString
        let payload = "\(method):\(url):\(timestamp):\(nonce)"
        
        // Get signing key from Keychain
        guard let signingKey = try? KeychainService.shared.getString(for: .encryptionKey) else {
            // Generate and store a new signing key if not exists
            let newKey = generateSigningKey()
            try? KeychainService.shared.save(newKey, for: .encryptionKey)
            return nil
        }
        
        // Create HMAC signature
        let key = SymmetricKey(data: Data(signingKey.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key)
        
        // Return base64 encoded signature with metadata
        return "\(timestamp):\(nonce):\(Data(signature).base64EncodedString())"
    }
    
    private func generateSigningKey() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0) }.base64EncodedString()
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case certificatePinningFailed
    case requestSignatureFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .certificatePinningFailed:
            return "Certificate validation failed - possible security threat"
        case .requestSignatureFailed:
            return "Request signature validation failed"
        }
    }
}