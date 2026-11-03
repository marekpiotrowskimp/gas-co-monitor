import SwiftUI
import GasCoKit

struct SummaryPage: View {
    let model: MonitorModel
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var level: DangerLevel { model.reading?.worstLevel ?? .safe }
    private var isStale: Bool { model.reading?.isStale() ?? true }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(SensorKind.allCases) { kind in
                    SensorGaugeView(kind: kind, reading: model.reading, lineWidth: 6, showsStatus: false)
                        .font(.caption2)
                }
            }
            .dynamicTypeSize(.xSmall)

            Label(isStale ? String(localized: "Brak aktualnych danych") : level.title,
                  systemImage: isStale ? "clock.badge.exclamationmark" : level.symbolName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isStale ? Color.staleLevel : level.color)
                .symbolEffect(.pulse, isActive: level == .danger && !isLuminanceReduced)

            ConnectionStatusView(state: model.state, isRelayed: model.state == .idle && model.isRelayFresh(),
                                 timestamp: model.reading?.timestamp)
        }
        .padding(.horizontal, 4)
        .containerBackground(backgroundGradient, for: .tabView)
        .navigationTitle("Gaz / CO")
    }

    private var backgroundGradient: LinearGradient {
        let tint = isStale ? Color.staleLevel : level.color
        return LinearGradient(colors: [tint.opacity(isLuminanceReduced ? 0.15 : 0.45), .black],
                              startPoint: .top, endPoint: .bottom)
    }
}

struct ConnectionStatusView: View {
    let state: SensorConnectionState
    let isRelayed: Bool
    let timestamp: Date?

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if isRelayed {
                    Label("Przez iPhone", systemImage: "iphone.radiowaves.left.and.right")
                } else {
                    Label(state.title, systemImage: state.symbolName)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            if let timestamp {
                Text(timestamp, style: .relative)
                    .monospacedDigit()
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}
