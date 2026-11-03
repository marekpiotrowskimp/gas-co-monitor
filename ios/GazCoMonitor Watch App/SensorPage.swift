import SwiftUI
import GasCoKit

struct SensorPage: View {
    let kind: SensorKind
    let reading: SensorReading?
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var level: DangerLevel { reading?.level(for: kind) ?? .safe }
    private var isStale: Bool { reading?.isStale() ?? true }

    var body: some View {
        SensorGaugeView(kind: kind, reading: reading, lineWidth: isLuminanceReduced ? 8 : 12)
            .padding(4)
            .opacity(isLuminanceReduced ? 0.7 : 1)
            .containerBackground(backgroundGradient, for: .tabView)
            .navigationTitle(kind.title)
    }

    private var backgroundGradient: RadialGradient {
        let tint = isStale ? Color.staleLevel : level.color
        return RadialGradient(colors: [tint.opacity(isLuminanceReduced ? 0.1 : 0.35), .black],
                              center: .center, startRadius: 10, endRadius: 140)
    }
}

#Preview {
    TabView {
        SensorPage(kind: .co, reading: .previewAlarm)
    }
    .tabViewStyle(.verticalPage)
}
