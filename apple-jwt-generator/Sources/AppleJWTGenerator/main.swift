import Foundation
import JWTKit

// Apple Sign In JWT Generator for Supabase
// This creates the client secret that Supabase expects

struct AppleSignInPayload: JWTPayload {
    let iss: String  // Team ID
    let iat: Date    // Issued at
    let exp: Date    // Expires at
    let aud: String  // Audience (always Apple)
    let sub: String  // Subject (your Service ID)
    let kid: String? // Key ID (optional in payload, but required in header)

    func verify(using signer: JWTSigner) throws {
        // Basic validation
        if Date() > exp {
            throw JWTError.claimVerificationFailure(name: "exp", reason: "Token expired")
        }
    }
}

// Your Apple Developer information
let teamID = "594BDWKT53"
let keyID = "C95BV259A4"
let serviceID = "com.hobbyist.bookingapp.service"

let privateKeyPEM = """
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgdFgVDE2FPs8WXC3/
8RwSZiui9z7sWm2iLODd+ZEo3iigCgYIKoZIzj0DAQehRANCAASobR/C23Vsj6Rg
0JYsSdV/fR1ixssjavbFgJ1hlL23RRHU3/FEuuhZbWTRqaDDdIOAlQMzTN/FATBu
RbXsjNxM
-----END PRIVATE KEY-----
"""

do {
    // Create the signer with your private key
    let signer = try JWTSigner.es256(key: .private(pem: privateKeyPEM))

    // Create the payload
    let payload = AppleSignInPayload(
        iss: teamID,
        iat: Date(),
        exp: Date().addingTimeInterval(3600), // 1 hour from now
        aud: "https://appleid.apple.com",
        sub: serviceID,
        kid: keyID
    )

    // Sign the JWT
    let jwt = try signer.sign(payload, kid: JWKIdentifier(string: keyID))

    print("🔑 Apple Sign In JWT Client Secret Generated!")
    print("📋 Copy this JWT and paste it as the Client Secret in Supabase:")
    print("")
    print(jwt)
    print("")
    print("Configuration for Supabase:")
    print("- Client ID: \(serviceID)")
    print("- Client Secret: [paste the JWT above]")
    print("- Team ID: \(teamID)")
    print("- Key ID: \(keyID)")

} catch {
    print("❌ Error generating JWT: \(error)")
}