import SwiftUI

public struct SensorGaugeView: View {
    let kind: SensorKind
    let reading: SensorReading?
    var lineWidth: CGFloat
    var showsStatus: Bool

    public init(kind: SensorKind, reading: SensorReading?, lineWidth: CGFloat = 16, showsStatus: Bool = true) {
        self.kind = kind
        self.reading = reading
        self.lineWidth = lineWidth
        self.showsStatus = showsStatus
    }

    private var value: Int { reading?.value(for: kind) ?? 0 }
    private var level: DangerLevel { reading?.level(for: kind) ?? .safe }
    private var isStale: Bool { reading?.isStale() ?? true }
    private var tint: Color { isStale ? .staleLevel : level.color }
    private var progress: Double { min(Double(value) / 100, 1) }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(gradient: .dangerScale, center: .center, startAngle: .degrees(-12), endAngle: .degrees(348)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(isStale ? 0.3 : 1)
                .animation(.smooth, value: progress)
            VStack(spacing: 2) {
                Label(kind.title, systemImage: kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(kind.accent)
                Text(reading == nil ? "--" : "\(value)%")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(value)))
                    .minimumScaleFactor(0.5)
                if showsStatus {
                    Label(level.shortTitle, systemImage: level.symbolName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(tint)
                        .symbolEffect(.pulse, isActive: level == .danger && !isStale)
                }
            }
            .padding(lineWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.title)
        .accessibilityValue("\(value)%, \(level.title)")
    }
}

#Preview {
    SensorGaugeView(kind: .gas, reading: .preview)
        .padding()
        .background(.black)
}
