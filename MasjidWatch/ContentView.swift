import SwiftUI

struct ContentView: View {
    @State private var sessionManager = WatchSessionManager()

    var body: some View {
        NavigationStack {
            PrayerNowView(
                watchState: sessionManager.watchState,
                isReachable: sessionManager.isReachable
            )
            .navigationTitle("المسجد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sessionManager.requestUpdate()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                    }
                }
            }
        }
    }
}
