import Foundation
import CryptoKit

struct HMACHelper {
    static func generateHeaders(
        method: String,
        path: String,
        body: Data,
        apiKey: String,
        secret: String
    ) -> [String: String] {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString

        let bodyHash = SHA256.hash(data: body)
        let bodyHashHex = bodyHash.map { String(format: "%02x", $0) }.joined()

        let canonical = "\(method)\n\(path)\n\(timestamp)\n\(nonce)\n\(bodyHashHex)"
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(canonical.utf8), using: key)
        let signatureHex = signature.map { String(format: "%02x", $0) }.joined()

        return [
            "X-API-Key": apiKey,
            "X-Timestamp": timestamp,
            "X-Nonce": nonce,
            "X-Signature": signatureHex,
        ]
    }
}
