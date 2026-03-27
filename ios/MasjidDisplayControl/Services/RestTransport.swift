import Foundation

struct RestTransport: SyncTransport {
    let transportName = "WiFi"

    func sendThemePack(data: Data, config: TransportConfig) async throws {
        try await send(path: "/v1/theme", data: data, config: config)
    }

    func sendLightSync(data: Data, config: TransportConfig) async throws {
        try await send(path: "/v1/sync", data: data, config: config)
    }

    func testConnection(config: TransportConfig) async throws -> String {
        let urlString = config.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/info"
        guard let url = URL(string: urlString) else {
            throw TransportError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw TransportError.httpError(code)
        }
        return "Connected via WiFi"
    }

    func sendCustom(path: String, data: Data, config: TransportConfig) async throws {
        try await send(path: path, data: data, config: config)
    }

    private func send(path: String, data: Data, config: TransportConfig) async throws {
        let urlString = config.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + path
        guard let url = URL(string: urlString) else {
            throw TransportError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        if config.useHMAC && !config.hmacSecret.isEmpty {
            let headers = HMACHelper.generateHeaders(
                method: "POST",
                path: path,
                body: data,
                apiKey: config.apiKey,
                secret: config.hmacSecret
            )
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        } else {
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        }

        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw TransportError.httpError(code)
        }
    }
}
