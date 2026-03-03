import SwiftUI
import SwiftUIX

struct DiagnosticsView: View {
    let store: AppStore
    let connectionManager: ConnectionManager

    @State private var results: [DiagnosticResult] = []
    @State private var isRunning: Bool = false
    @State private var hasRun: Bool = false
    @State private var copiedReport: Bool = false

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
                serverLogsHint
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(DepthStack(accentColor: .indigo) { Color.clear })
        .navigationTitle("API Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var serverInfoCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Server Info", icon: "server.rack", color: .blue)

            VStack(spacing: DS.Spacing.xs) {
                infoRow("Base URL", value: store.pushTarget.baseUrl)
                infoRow("API Key", value: String(store.pushTarget.apiKey.prefix(4)) + "••••")
                infoRow("Transport", value: store.pushTarget.transportMode.displayName)
                infoRow("Connection", value: connectionManager.connectionState.rawValue.capitalized)
                infoRow("Paired", value: connectionManager.isPaired ? "Yes" : "No")
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: .blue)
        .elevation(.level2)
    }

    private var connectionHealthCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Connection Health", icon: "heart.text.square", color: .pink)

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
        .glassLayer(.card, glow: .pink)
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
        .tint(.cyan)
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
                    Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(result.isSuccess ? .green : .red)

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
        .glassLayer(.card, glow: .green)
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
        .tint(copiedReport ? .green : .cyan)
        .sensoryFeedback(.success, trigger: copiedReport)
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

    private func runDiagnostics() {
        isRunning = true
        Task {
            results = await connectionManager.runDiagnostics(store: store)
            isRunning = false
            hasRun = true
        }
    }
}
