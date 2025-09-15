import Foundation
import CryptoKit

/// Validates Stripe webhook signatures to prevent payment fraud
final class StripeWebhookValidator {
    
    private let webhookSecret: String
    private let toleranceSeconds: TimeInterval = 300 // 5 minutes
    
    enum WebhookError: Error {
        case invalidSignature
        case missingHeaders
        case timestampTooOld
        case invalidPayload
        case parsingError
        
        var localizedDescription: String {
            switch self {
            case .invalidSignature:
                return "Invalid webhook signature - possible tampering detected"
            case .missingHeaders:
                return "Missing required Stripe headers"
            case .timestampTooOld:
                return "Webhook timestamp is too old - possible replay attack"
            case .invalidPayload:
                return "Invalid webhook payload format"
            case .parsingError:
                return "Failed to parse webhook data"
            }
        }
    }
    
    init(webhookSecret: String) {
        self.webhookSecret = webhookSecret
    }
    
    /// Validates a Stripe webhook request
    /// - Parameters:
    ///   - payload: Raw request body data
    ///   - signature: Stripe-Signature header value
    /// - Returns: Validated and parsed webhook event
    func validateWebhook(payload: Data, signature: String) throws -> StripeWebhookEvent {
        // Parse the signature header
        let signatureComponents = try parseSignatureHeader(signature)
        
        // Verify timestamp to prevent replay attacks
        try verifyTimestamp(signatureComponents.timestamp)
        
        // Compute expected signature
        let expectedSignature = try computeSignature(
            payload: payload,
            timestamp: signatureComponents.timestamp
        )
        
        // Verify at least one signature matches
        var signatureValid = false
        for providedSignature in signatureComponents.signatures {
            if secureCompare(providedSignature, expectedSignature) {
                signatureValid = true
                break
            }
        }
        
        guard signatureValid else {
            // Log security event
            logSecurityEvent(
                type: .webhookValidationFailed,
                metadata: ["reason": "signature_mismatch"]
            )
            throw WebhookError.invalidSignature
        }
        
        // Parse and return the validated event
        return try parseWebhookEvent(from: payload)
    }
    
    // MARK: - Signature Components
    
    private struct SignatureComponents {
        let timestamp: String
        let signatures: [String]
    }
    
    private func parseSignatureHeader(_ header: String) throws -> SignatureComponents {
        var timestamp: String?
        var signatures: [String] = []
        
        // Parse format: "t=timestamp,v1=signature,v1=signature2"
        let parts = header.split(separator: ",")
        
        for part in parts {
            let keyValue = part.split(separator: "=", maxSplits: 1)
            guard keyValue.count == 2 else { continue }
            
            let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
            let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)
            
            switch key {
            case "t":
                timestamp = value
            case "v1":
                signatures.append(value)
            default:
                // Ignore unknown schemes
                break
            }
        }
        
        guard let ts = timestamp, !signatures.isEmpty else {
            throw WebhookError.missingHeaders
        }
        
        return SignatureComponents(timestamp: ts, signatures: signatures)
    }
    
    // MARK: - Timestamp Verification
    
    private func verifyTimestamp(_ timestamp: String) throws {
        guard let timestampInt = TimeInterval(timestamp) else {
            throw WebhookError.parsingError
        }
        
        let currentTime = Date().timeIntervalSince1970
        let difference = currentTime - timestampInt
        
        // Reject if timestamp is too old (replay attack protection)
        guard difference <= toleranceSeconds else {
            logSecurityEvent(
                type: .webhookReplayAttempt,
                metadata: [
                    "timestamp": timestamp,
                    "difference_seconds": String(difference)
                ]
            )
            throw WebhookError.timestampTooOld
        }
        
        // Also reject if timestamp is in the future (clock skew protection)
        guard difference >= -toleranceSeconds else {
            throw WebhookError.timestampTooOld
        }
    }
    
    // MARK: - Signature Computation
    
    private func computeSignature(payload: Data, timestamp: String) throws -> String {
        // Construct signed payload: timestamp.payload
        guard let timestampData = timestamp.data(using: .utf8) else {
            throw WebhookError.parsingError
        }
        
        var signedPayload = Data()
        signedPayload.append(timestampData)
        signedPayload.append(".".data(using: .utf8)!)
        signedPayload.append(payload)
        
        // Compute HMAC-SHA256
        guard let secretData = webhookSecret.data(using: .utf8) else {
            throw WebhookError.parsingError
        }
        
        let key = SymmetricKey(data: secretData)
        let signature = HMAC<SHA256>.authenticationCode(for: signedPayload, using: key)
        
        // Convert to hex string
        return signature.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Secure Comparison
    
    private func secureCompare(_ a: String, _ b: String) -> Bool {
        // Constant-time comparison to prevent timing attacks
        guard a.count == b.count else { return false }
        
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        
        var result = 0
        for i in 0..<aBytes.count {
            result |= Int(aBytes[i] ^ bBytes[i])
        }
        
        return result == 0
    }
    
    // MARK: - Event Parsing
    
    private func parseWebhookEvent(from data: Data) throws -> StripeWebhookEvent {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            return try decoder.decode(StripeWebhookEvent.self, from: data)
        } catch {
            throw WebhookError.parsingError
        }
    }
    
    // MARK: - Security Logging
    
    private func logSecurityEvent(type: SecurityEventType, metadata: [String: String] = [:]) {
        // In production, this would log to your security monitoring system
        #if DEBUG
        print("🔐 Security Event: \(type)")
        print("   Metadata: \(metadata)")
        #endif
        
        // Send to monitoring service
        SecurityMonitor.shared.logEvent(
            type: type,
            severity: .high,
            metadata: metadata
        )
    }
}

// MARK: - Webhook Event Model

struct StripeWebhookEvent: Codable {
    let id: String
    let object: String
    let apiVersion: String?
    let created: Date
    let data: EventData
    let livemode: Bool
    let pendingWebhooks: Int
    let request: RequestInfo?
    let type: String
    
    struct EventData: Codable {
        let object: Data
        let previousAttributes: Data?
    }
    
    struct RequestInfo: Codable {
        let id: String?
        let idempotencyKey: String?
    }
    
    // Helper to get specific event types
    var eventType: EventType? {
        return EventType(rawValue: type)
    }
    
    enum EventType: String {
        case paymentIntentSucceeded = "payment_intent.succeeded"
        case paymentIntentFailed = "payment_intent.payment_failed"
        case chargeSucceeded = "charge.succeeded"
        case chargeFailed = "charge.failed"
        case customerSubscriptionCreated = "customer.subscription.created"
        case customerSubscriptionUpdated = "customer.subscription.updated"
        case customerSubscriptionDeleted = "customer.subscription.deleted"
        case invoicePaymentSucceeded = "invoice.payment_succeeded"
        case invoicePaymentFailed = "invoice.payment_failed"
    }
}

// MARK: - Security Event Types

enum SecurityEventType {
    case webhookValidationFailed
    case webhookReplayAttempt
    case suspiciousPaymentPattern
    case fraudulentChargeAttempt
}

// MARK: - Webhook Handler

class StripeWebhookHandler {
    
    private let validator: StripeWebhookValidator
    private let securityMonitor = SecurityMonitor.shared
    
    init(webhookSecret: String) {
        self.validator = StripeWebhookValidator(webhookSecret: webhookSecret)
    }
    
    /// Process a webhook from Stripe
    func handleWebhook(payload: Data, signature: String) async throws {
        // Validate the webhook
        let event = try validator.validateWebhook(
            payload: payload,
            signature: signature
        )
        
        // Log successful validation
        securityMonitor.logEvent(
            type: .webhookValidationFailed,
            severity: .info,
            metadata: [
                "event_id": event.id,
                "event_type": event.type
            ]
        )
        
        // Process based on event type
        switch event.eventType {
        case .paymentIntentSucceeded:
            try await handlePaymentSuccess(event)
            
        case .paymentIntentFailed:
            try await handlePaymentFailure(event)
            
        case .customerSubscriptionCreated,
             .customerSubscriptionUpdated:
            try await handleSubscriptionChange(event)
            
        case .customerSubscriptionDeleted:
            try await handleSubscriptionCancellation(event)
            
        default:
            print("Unhandled webhook event type: \(event.type)")
        }
    }
    
    private func handlePaymentSuccess(_ event: StripeWebhookEvent) async throws {
        // Process successful payment
        // Update user credits, send confirmation, etc.
        print("Processing successful payment: \(event.id)")
    }
    
    private func handlePaymentFailure(_ event: StripeWebhookEvent) async throws {
        // Handle failed payment
        // Notify user, retry logic, etc.
        print("Processing failed payment: \(event.id)")
    }
    
    private func handleSubscriptionChange(_ event: StripeWebhookEvent) async throws {
        // Update subscription status
        print("Processing subscription change: \(event.id)")
    }
    
    private func handleSubscriptionCancellation(_ event: StripeWebhookEvent) async throws {
        // Handle subscription cancellation
        print("Processing subscription cancellation: \(event.id)")
    }
}