#if os(iOS)
import SwiftUI
import WidgetKit
import GasCoKit

struct SmallView: View {
    let entry: SensorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            StatusHeader(entry: entry)
            Spacer(minLength: 0)
            ForEach(entry.kinds) { kind in
                SensorValueRow(entry: entry, kind: kind, valueFont: entry.kinds.count == 1 ? .system(size: 44, weight: .bold, design: .rounded) : .title.bold())
            }
            Spacer(minLength: 0)
            UpdatedText(entry: entry)
        }
    }
}

struct MediumView: View {
    let entry: SensorEntry

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                StatusHeader(entry: entry)
                Spacer()
                UpdatedText(entry: entry)
            }
            HStack(spacing: 0) {
                ForEach(entry.kinds) { kind in
                    SensorGaugeView(kind: kind, reading: entry.displayReading, lineWidth: 8, showsStatus: false)
                        .dynamicTypeSize(.xSmall)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct LargeView: View {
    let entry: SensorEntry

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatusHeader(entry: entry)
                Spacer()
                UpdatedText(entry: entry)
            }
            HStack(spacing: 12) {
                ForEach(entry.kinds) { kind in
                    SensorGaugeView(kind: kind, reading: entry.displayReading, lineWidth: 12)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
            if let reading = entry.reading, !entry.isStale {
                Text(reading.worstLevel.title)
                    .font(.headline)
                    .foregroundStyle(reading.worstLevel.color)
            }
        }
    }
}

private struct SensorValueRow: View {
    let entry: SensorEntry
    let kind: SensorKind
    let valueFont: Font

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(kind.title, systemImage: kind.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(kind.accent)
            Spacer(minLength: 4)
            Text("\(entry.valueText(for: kind))%")
                .font(valueFont)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(entry.tint(for: kind))
        }
    }
}

private struct MiniRing: View {
    let entry: SensorEntry
    let kind: SensorKind

    var body: some View {
        ZStack {
            Circle().stroke(entry.tint(for: kind).opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: entry.progress(for: kind) / 100)
                .stroke(entry.tint(for: kind), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: kind.symbolName)
                .font(.title3)
                .foregroundStyle(kind.accent)
        }
        .widgetAccentable()
    }
}

private struct StatusHeader: View {
    let entry: SensorEntry

    private var level: DangerLevel { entry.reading?.worstLevel ?? .safe }

    var body: some View {
        Label(entry.isStale ? String(localized: "Brak danych") : level.shortTitle,
              systemImage: entry.isStale ? "clock.badge.exclamationmark" : level.symbolName)
            .font(.caption.weight(.bold))
            .foregroundStyle(entry.isStale ? Color.staleLevel : level.color)
    }
}

private struct UpdatedText: View {
    let entry: SensorEntry

    var body: some View {
        if let reading = entry.reading {
            Text(reading.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

extension SensorEntry {
    var displayReading: SensorReading? {
        guard var reading else { return nil }
        if isStale { reading.timestamp = .distantPast }
        return reading
    }

    func levelText(for kind: SensorKind) -> String {
        guard let reading, !isStale else { return String(localized: "Brak danych") }
        return reading.level(for: kind).shortTitle
    }
}
#endif
