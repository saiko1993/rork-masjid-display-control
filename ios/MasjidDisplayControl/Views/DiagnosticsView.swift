import SwiftUI
import SwiftUIX

struct DiagnosticsView: View {
    let store: AppStore
    let connectionManager: ConnectionManager

    @State private var results: [DiagnosticResult] = []
    @State private var isRunning: Bool = false
    @State private var hasRun: Bool = false
    @State private var copiedReport: Bool = false
    @State private var copiedContract: Bool = false
    @State private var exportedContract: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                serverInfoCard
                connectionHealthCard
                runButton
                if hasRun {
                    serverNeedsUpdateBanner
                    resultsSection
                    copyReportButton
                }
                apiContractSection
                serverLogsHint
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(DepthStack(accentColor: DSTokens.Palette.deepBlue) { Color.clear })
        .navigationTitle("API Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var serverInfoCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Server Info", icon: "server.rack", color: DSTokens.Palette.deepBlue)

            VStack(spacing: DS.Spacing.xs) {
                infoRow("Base URL", value: store.pushTarget.baseUrl)
                infoRow("API Key", value: String(store.pushTarget.apiKey.prefix(4)) + "••••")
                infoRow("Transport", value: store.pushTarget.transportMode.displayName)
                infoRow("Connection", value: connectionManager.connectionState.rawValue.capitalized)
                infoRow("Paired", value: connectionManager.isPaired ? "Yes" : "No")
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: DSTokens.Palette.deepBlue.opacity(0.3))
        .elevation(.level2)
    }

    private var connectionHealthCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Connection Health", icon: "heart.text.square", color: DSTokens.Palette.warmAmber)

            VStack(spacing: DS.Spacing.xs) {
                infoRow("Auto-Sync", value: connectionManager.isAutoSyncEnabled ? "Enabled" : "Disabled")
                infoRow("Network", value: connectionManager.networkAvailable ? "Available" : "Unavailable")
                infoRow("Pending Queue", value: "\(connectionManager.pendingCount)")
                infoRow("Response Time", value: "\(connectionManager.serverResponseTimeMs)ms")
                if let ping = connectionManager.lastPingDate {
                    infoRow("Last Ping", value: ping.formatted(.relative(presentation: .named)))
                }
                if let sync = connectionManager.lastSyncDate {
                    infoRow("Last Sync", value: sync.formatted(.relative(presentation: .named)))
                }
                infoRow("Failures", value: "\(connectionManager.consecutiveFailures)")
                if let error = connectionManager.lastError {
                    HStack(alignment: .top) {
                        Text("Last Error")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(error)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(3)
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: DSTokens.Palette.warmAmber.opacity(0.3))
        .elevation(.level2)
    }

    private var runButton: some View {
        Button {
            runDiagnostics()
        } label: {
            HStack(spacing: 10) {
                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 18))
                }
                Text(isRunning ? "Running Diagnostics..." : "Run All Diagnostics")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.borderedProminent)
        .tint(DSTokens.Palette.accent)
        .disabled(isRunning)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: hasRun)
    }

    private var serverNeedsUpdateBanner: some View {
        let has404 = results.contains { $0.statusCode == 404 }
        return Group {
            if has404 {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Server Needs Update")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            Text("Some endpoints returned 404. Update your Raspberry Pi server to the latest version.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("cd ~/Mosque-clock && git pull && sudo systemctl restart masjid-api")
                        .font(.system(size: 11, design: .monospaced))
                        .padding(DS.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.06))
                        .clipShape(.rect(cornerRadius: DS.Radius.sm))

                    Button {
                        UIPasteboard.general.string = "cd ~/Mosque-clock && git pull && sudo systemctl restart masjid-api"
                    } label: {
                        Label("Copy Update Command", systemImage: "doc.on.doc")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(DS.Spacing.md)
                .glassLayer(.card, glow: .orange)
                .elevation(.level2)
                .errorFocus(isError: true)
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                SectionHeader(title: "Results", icon: "list.clipboard", color: .green)
                Spacer()
                let successCount = results.filter(\.isSuccess).count
                Text("\(successCount)/\(results.count) passed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(successCount == results.count ? .green : .orange)
            }

            ForEach(results) { result in
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: resultIcon(result))
                        .font(.title3)
                        .foregroundStyle(resultColor(result))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(result.name)
                            .font(.subheadline.weight(.medium))

                        HStack(spacing: 8) {
                            if result.statusCode > 0 {
                                Text("HTTP \(result.statusCode)")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(statusCodeColor(result.statusCode).opacity(0.15))
                                    .foregroundStyle(statusCodeColor(result.statusCode))
                                    .clipShape(.capsule)
                            }

                            Text(result.statusLabel)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(resultColor(result))

                            Text(String(format: "%.0fms", result.responseTime * 1000))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        if let error = result.error {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
                .padding(DS.Spacing.sm)
                .background(Color.white.opacity(0.06))
                .clipShape(.rect(cornerRadius: DS.Radius.md))
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: DSTokens.Palette.accent.opacity(0.3))
        .elevation(.level2)
    }

    private var copyReportButton: some View {
        Button {
            let report = connectionManager.generateDebugReport(store: store, results: results)
            UIPasteboard.general.string = report
            copiedReport = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                copiedReport = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: copiedReport ? "checkmark.circle.fill" : "doc.on.doc")
                Text(copiedReport ? "Copied!" : "Copy Debug Report")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.bordered)
        .tint(copiedReport ? .green : DSTokens.Palette.accent)
        .sensoryFeedback(.success, trigger: copiedReport)
    }

    private var apiContractSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "API Contract", icon: "doc.text.magnifyingglass", color: DSTokens.Palette.deepBlue)

            Text("The app communicates with the Raspberry Pi server using these endpoints:")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(contractEndpoints, id: \.path) { ep in
                    HStack(spacing: 8) {
                        Text(ep.method)
                            .font(.caption2.weight(.bold).monospaced())
                            .frame(width: 38)
                            .foregroundStyle(ep.method == "GET" ? .cyan : .orange)
                        Text(ep.path)
                            .font(.caption.monospaced())
                        Spacer()
                        Text(ep.phase)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(ep.phase == "MVP" ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                            .foregroundStyle(ep.phase == "MVP" ? .green : .secondary)
                            .clipShape(.capsule)
                    }
                }
            }
            .padding(DS.Spacing.sm)
            .background(Color.white.opacity(0.04))
            .clipShape(.rect(cornerRadius: DS.Radius.sm))

            HStack(spacing: DS.Spacing.sm) {
                Button {
                    copyAPIContract()
                } label: {
                    Label(copiedContract ? "Copied!" : "Copy Contract", systemImage: copiedContract ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(copiedContract ? .green : DSTokens.Palette.accent)
                .controlSize(.small)

                Button {
                    exportContractJSON()
                } label: {
                    Label(exportedContract ? "Saved!" : "Export JSON", systemImage: exportedContract ? "checkmark.circle.fill" : "square.and.arrow.up")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(exportedContract ? .green : .blue)
                .controlSize(.small)
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: DSTokens.Palette.deepBlue.opacity(0.2))
        .elevation(.level2)
    }

    private var serverLogsHint: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Server Logs", icon: "terminal", color: .gray)

            Text("To view live server logs on your Raspberry Pi, run:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("journalctl -u masjid-api -f")
                .font(.system(size: 13, design: .monospaced))
                .padding(DS.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06))
                .clipShape(.rect(cornerRadius: DS.Radius.sm))

            Button {
                UIPasteboard.general.string = "journalctl -u masjid-api -f"
            } label: {
                Label("Copy Command", systemImage: "doc.on.doc")
                    .font(.caption.weight(.medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level1)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
    }

    private func statusCodeColor(_ code: Int) -> Color {
        switch code {
        case 200...299: return .green
        case 300...399: return .blue
        case 400...499: return .orange
        default: return .red
        }
    }

    private func resultIcon(_ result: DiagnosticResult) -> String {
        if result.isSuccess { return "checkmark.circle.fill" }
        if result.isNotImplemented { return "questionmark.circle.fill" }
        return "xmark.circle.fill"
    }

    private func resultColor(_ result: DiagnosticResult) -> Color {
        if result.isSuccess { return .green }
        if result.isNotImplemented { return .orange }
        return .red
    }

    private struct ContractEndpoint {
        let method: String
        let path: String
        let phase: String
    }

    private var contractEndpoints: [ContractEndpoint] {
        [
            ContractEndpoint(method: "GET", path: "/v1/info", phase: "MVP"),
            ContractEndpoint(method: "POST", path: "/v1/theme", phase: "MVP"),
            ContractEndpoint(method: "POST", path: "/v1/sync", phase: "MVP"),
            ContractEndpoint(method: "POST", path: "/v1/ticker", phase: "MVP"),
            ContractEndpoint(method: "POST", path: "/v1/upload-background", phase: "MVP"),
            ContractEndpoint(method: "GET", path: "/display", phase: "MVP"),
            ContractEndpoint(method: "GET", path: "/v1/state", phase: "P2"),
            ContractEndpoint(method: "POST", path: "/v1/audio", phase: "P2"),
            ContractEndpoint(method: "POST", path: "/v1/power", phase: "P2"),
            ContractEndpoint(method: "POST", path: "/v1/ramadan", phase: "P2"),
            ContractEndpoint(method: "POST", path: "/v1/quran-program", phase: "P2"),
        ]
    }

    private func copyAPIContract() {
        let base = store.pushTarget.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var text = "=== Masjid Display API Contract ===\n"
        text += "Base URL: \(base)\n"
        text += "API Key: \(String(store.pushTarget.apiKey.prefix(4)))••••\n"
        text += "HMAC: \(store.pushTarget.useHMAC ? "Enabled" : "Disabled")\n\n"
        text += "--- Endpoints ---\n"
        for ep in contractEndpoints {
            text += "[\(ep.phase)] \(ep.method) \(ep.path)\n"
        }
        if hasRun {
            text += "\n--- Last Diagnostic Results ---\n"
            for r in results {
                let status = r.isSuccess ? "PASS" : (r.isNotImplemented ? "N/A" : "FAIL")
                text += "[\(status)] \(r.name) — HTTP \(r.statusCode) — \(Int(r.responseTime * 1000))ms"
                if let err = r.error { text += " — \(err)" }
                text += "\n"
            }
        }
        UIPasteboard.general.string = text
        copiedContract = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copiedContract = false
        }
    }

    private func exportContractJSON() {
        let contractJSON = buildContractJSON()
        guard let data = contractJSON.data(using: .utf8) else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("api-contract.json")
        try? data.write(to: tempURL)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
        }
        root.present(activityVC, animated: true)
        exportedContract = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            exportedContract = false
        }
    }

    private func buildContractJSON() -> String {
        let base = store.pushTarget.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var endpoints: [[String: String]] = []
        for ep in contractEndpoints {
            var entry: [String: String] = [
                "method": ep.method,
                "path": ep.path,
                "url": base + ep.path,
                "phase": ep.phase,
            ]
            if hasRun, let r = results.first(where: { $0.name.contains(ep.path) }) {
                entry["lastStatusCode"] = "\(r.statusCode)"
                entry["lastResponseMs"] = "\(Int(r.responseTime * 1000))"
                entry["lastResult"] = r.statusLabel
            }
            endpoints.append(entry)
        }

        let contract: [String: Any] = [
            "baseUrl": base,
            "apiKey": String(store.pushTarget.apiKey.prefix(4)) + "••••",
            "hmacEnabled": store.pushTarget.useHMAC,
            "transport": store.pushTarget.transportMode.rawValue,
            "endpoints": endpoints,
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: contract, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return "{}" }
        return json
    }

    private func runDiagnostics() {
        isRunning = true
        Task {
            results = await connectionManager.runDiagnostics(store: store)
            isRunning = false
            hasRun = true
        }
    }
}
