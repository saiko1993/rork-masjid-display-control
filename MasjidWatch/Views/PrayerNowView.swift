import SwiftUI

struct PrayerNowView: View {
    let watchState: WatchState
    let isReachable: Bool

    private var phase: WatchPrayerPhase {
        watchState.prayerPhase
    }

    private var phaseColor: Color {
        switch phase {
        case .normal: return .green
        case .adhanActive: return .orange
        case .iqamaCountdown: return .yellow
        case .prayerInProgress: return .cyan
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                headerSection
                countdownSection
                prayerListSection
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 2) {
            if !watchState.city.isEmpty {
                Text(watchState.city)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if phase != .normal {
                Text(phase.labelAr)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(phaseColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(phaseColor.opacity(0.2), in: Capsule())
            }
        }
    }

    @ViewBuilder
    private var countdownSection: some View {
        VStack(spacing: 4) {
            if let nextPrayer = watchState.nextPrayer {
                Label {
                    Text(nextPrayer.displayNameAr)
                        .font(.headline)
                } icon: {
                    Image(systemName: nextPrayer.iconName)
                        .foregroundStyle(phaseColor)
                }

                Text(nextPrayer.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if watchState.countdownSeconds > 0 {
                Text(timerInterval: Date()...watchState.countdownDate, countsDown: true)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(phaseColor)
                    .contentTransition(.numericText())
            } else {
                Text("--:--")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var prayerListSection: some View {
        if !watchState.prayers.isEmpty {
            VStack(spacing: 0) {
                ForEach(watchState.prayers) { entry in
                    let isNext = entry.prayerKey == watchState.nextPrayerKey
                    HStack {
                        Image(systemName: entry.icon)
                            .font(.caption2)
                            .foregroundStyle(isNext ? phaseColor : .secondary)
                            .frame(width: 16)

                        Text(entry.nameAr)
                            .font(.caption2)
                            .fontWeight(isNext ? .bold : .regular)

                        Spacer()

                        Text(entry.time, format: .dateTime.hour().minute())
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(isNext ? .primary : .secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background {
                        if isNext {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(phaseColor.opacity(0.15))
                        }
                    }
                }
            }
        }
    }
}
