#!/usr/bin/swift

import Foundation

// Simple JWT creation for Apple Sign In without external dependencies
// This creates the client secret that Supabase expects

let teamID = "594BDWKT53"  // Your Team ID from Apple Developer Console
let keyID = "C95BV259A4"   // Your Key ID from the filename
let serviceID = "com.hobbyist.bookingapp"  // Your Service ID (or App ID)

let privateKeyPEM = """
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgdFgVDE2FPs8WXC3/
8RwSZiui9z7sWm2iLODd+ZEo3iigCgYIKoZIzj0DAQehRANCAASobR/C23Vsj6Rg
0JYsSdV/fR1ixssjavbFgJ1hlL23RRHU3/FEuuhZbWTRqaDDdIOAlQMzTN/FATBu
RbXsjNxM
-----END PRIVATE KEY-----
"""

// JWT Header
let header = """
{
  "alg": "ES256",
  "kid": "\(keyID)",
  "typ": "JWT"
}
"""

// JWT Payload
let now = Int(Date().timeIntervalSince1970)
let exp = now + 3600 // 1 hour from now

let payload = """
{
  "iss": "\(teamID)",
  "iat": \(now),
  "exp": \(exp),
  "aud": "https://appleid.apple.com",
  "sub": "\(serviceID)"
}
"""

// Base64URL encoding functions
func base64URLEncode(_ data: Data) -> String {
    return data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

// Encode header and payload
let headerData = header.data(using: .utf8)!
let payloadData = payload.data(using: .utf8)!

let encodedHeader = base64URLEncode(headerData)
let encodedPayload = base64URLEncode(payloadData)

let signingInput = "\(encodedHeader).\(encodedPayload)"

print("=== Apple Sign In JWT Client Secret ===")
print("")
print("Team ID: \(teamID)")
print("Key ID: \(keyID)")
print("Service ID: \(serviceID)")
print("")
print("Header: \(encodedHeader)")
print("Payload: \(encodedPayload)")
print("")
print("⚠️  NOTE: This script shows the JWT structure but cannot create the signature without crypto libraries.")
print("⚠️  For the actual signing, you'll need to use vapor/jwt-kit or another crypto library.")
print("")
print("Use this structure with vapor/jwt-kit to create the final JWT for Supabase.")