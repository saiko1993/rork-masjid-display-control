import Foundation
import Security

struct SecureStorageService {
    private static let serviceName = "com.masjid.controller"

    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var newQuery = query
        newQuery[kSecValueData as String] = data
        SecItemAdd(newQuery as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveCredentials(baseUrl: String, apiKey: String, hmacSecret: String) {
        save(key: "baseUrl", value: baseUrl)
        save(key: "apiKey", value: apiKey)
        save(key: "hmacSecret", value: hmacSecret)
    }

    static func loadCredentials() -> (baseUrl: String?, apiKey: String?, hmacSecret: String?) {
        (load(key: "baseUrl"), load(key: "apiKey"), load(key: "hmacSecret"))
    }

    static func savePairingState(isPaired: Bool, deviceId: String?, lastServerIP: String?) {
        save(key: "isPaired", value: isPaired ? "1" : "0")
        if let deviceId { save(key: "pairedDeviceId", value: deviceId) }
        if let ip = lastServerIP { save(key: "lastServerIP", value: ip) }
    }

    static func loadPairingState() -> (isPaired: Bool, deviceId: String?, lastServerIP: String?) {
        let paired = load(key: "isPaired") == "1"
        return (paired, load(key: "pairedDeviceId"), load(key: "lastServerIP"))
    }
}
