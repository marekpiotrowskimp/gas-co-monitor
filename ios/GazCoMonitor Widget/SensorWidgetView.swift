import SwiftUI
import WidgetKit
import GasCoKit

struct SensorWidgetView: View {
    let entry: SensorEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: CircularView(entry: entry)
            #if os(watchOS)
            case .accessoryCorner: CornerView(entry: entry)
            #else
            case .systemSmall: SmallView(entry: entry)
            case .systemMedium: MediumView(entry: entry)
            case .systemLarge: LargeView(entry: entry)
            #endif
            case .accessoryRectangular: RectangularView(entry: entry)
            default: InlineView(entry: entry)
            }
        }
        .environment(\.colorScheme, .dark)
        .containerBackground(for: .widget) { Color.black }
    }
}

extension SensorEntry {
    var primaryKind: SensorKind {
        switch selection {
        case .co: return .co
        case .gas: return .gas
        case .both:
            guard let reading else { return .co }
            return reading.level(for: .gas) > reading.level(for: .co) ? SensorKind.gas : SensorKind.co
        }
    }

    func tint(for kind: SensorKind) -> Color {
        guard let reading, !isStale else { return .staleLevel }
        return reading.level(for: kind).color
    }

    func valueText(for kind: SensorKind) -> String {
        guard let reading else { return "--" }
        return "\(reading.value(for: kind))"
    }

    func progress(for kind: SensorKind) -> Double {
        min(Double(reading?.value(for: kind) ?? 0), 100)
    }

    var kinds: [SensorKind] {
        switch selection {
        case .co: [.co]
        case .gas: [.gas]
        case .both: SensorKind.allCases
        }
    }
}

private struct CircularView: View {
    let entry: SensorEntry

    var body: some View {
        let kind = entry.primaryKind
        Gauge(value: entry.progress(for: kind), in: 0...100) {
            Image(systemName: kind.symbolName)
        } currentValueLabel: {
            Text(entry.valueText(for: kind))
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.isStale ? Gradient(colors: [.staleLevel]) : .dangerScale)
        .widgetAccentable()
    }
}

#if os(watchOS)
private struct CornerView: View {
    let entry: SensorEntry

    var body: some View {
        let kind = entry.primaryKind
        Image(systemName: entry.isStale ? "clock.badge.exclamationmark" : kind.symbolName)
            .font(.title.bold())
            .foregroundStyle(entry.tint(for: kind))
            .widgetAccentable()
            .widgetLabel {
                Gauge(value: entry.progress(for: kind), in: 0...100) {
                    Text(kind.title)
                } currentValueLabel: {
                    Text(entry.valueText(for: kind))
                } minimumValueLabel: {
                    Text(kind.title)
                } maximumValueLabel: {
                    Text(entry.valueText(for: kind))
                }
                .tint(entry.isStale ? Gradient(colors: [.staleLevel]) : .dangerScale)
            }
    }
}

#endif

private struct RectangularView: View {
    let entry: SensorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Label(headline, systemImage: headlineSymbol)
                    .font(.headline)
                    .foregroundStyle(headlineTint)
                    .lineLimit(1)
                    .widgetAccentable()
                Spacer(minLength: 2)
                if let reading = entry.reading {
                    Text(reading.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            ForEach(entry.kinds) { kind in
                HStack(spacing: 6) {
                    Text(kind.title)
                        .font(.caption2.weight(.semibold))
                        .frame(width: 30, alignment: .leading)
                    ProgressBar(value: entry.progress(for: kind) / 100, tint: entry.tint(for: kind))
                        .frame(height: 5)
                        .widgetAccentable()
                    Text("\(entry.valueText(for: kind))%")
                        .font(.body.weight(.bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .frame(minWidth: 44, alignment: .trailing)
                }
            }
        }
    }

    private var level: DangerLevel { entry.reading?.worstLevel ?? .safe }
    private var headline: String { entry.isStale ? String(localized: "Brak danych") : level.shortTitle }
    private var headlineSymbol: String { entry.isStale ? "clock.badge.exclamationmark" : level.symbolName }
    private var headlineTint: Color { entry.isStale ? .staleLevel : level.color }
}

private struct ProgressBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.25))
                Capsule().fill(tint).frame(width: max(proxy.size.width * value, proxy.size.height))
            }
        }
    }
}

private struct InlineView: View {
    let entry: SensorEntry

    var body: some View {
        if entry.isStale {
            Label("Gaz / CO: brak danych", systemImage: "clock.badge.exclamationmark")
        } else if let reading = entry.reading, reading.worstLevel == .danger {
            Label("ALARM \(entry.primaryKind.title) \(entry.valueText(for: entry.primaryKind))%", systemImage: "light.beacon.max.fill")
        } else {
            Text(entry.kinds.map { "\($0.title) \(entry.valueText(for: $0))%" }.joined(separator: " · "))
        }
    }
}
