import SwiftUI
import WebKit

struct MirrorModeView: View {
    let store: AppStore
    let connectionManager: ConnectionManager?

    @Environment(\.dismiss) private var dismiss
    @State private var refreshTrigger: Int = 0
    @State private var serverReachable: Bool = false
    @State private var checking: Bool = true

    private var displayURL: URL? {
        let base = store.pushTarget.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: base + "/display")
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = displayURL, serverReachable {
                LiveDisplayWebView(url: url, refreshTrigger: refreshTrigger)
                    .ignoresSafeArea()
            } else if checking {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                    Text("Connecting to display...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("Display Not Reachable")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(store.pushTarget.baseUrl)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        checkServer()
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                    .padding(16)
                }
                Spacer()
                HStack {
                    Button {
                        refreshTrigger += 1
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(.capsule)
                    }
                    Spacer()
                    Text("MIRROR")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.3))
                        .clipShape(.capsule)
                }
                .padding(16)
            }
        }
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            checkServer()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func checkServer() {
        checking = true
        let base = store.pushTarget.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/v1/info") else {
            serverReachable = false
            checking = false
            return
        }
        Task {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            request.setValue(store.pushTarget.apiKey, forHTTPHeaderField: "X-API-Key")
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                let http = response as? HTTPURLResponse
                serverReachable = http != nil && (200...299).contains(http!.statusCode)
            } catch {
                serverReachable = false
            }
            checking = false
        }
    }
}
