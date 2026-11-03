import WidgetKit
import GasCoKit

struct SensorEntry: TimelineEntry {
    let date: Date
    let reading: SensorReading?
    let selection: SensorSelection

    var isStale: Bool { reading?.isStale(now: date) ?? true }

    var relevance: TimelineEntryRelevance? {
        guard let reading, !isStale else { return nil }
        switch reading.worstLevel {
        case .danger: return TimelineEntryRelevance(score: 100)
        case .warning: return TimelineEntryRelevance(score: 50)
        case .safe: return TimelineEntryRelevance(score: 1)
        }
    }
}

struct SensorTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SensorEntry {
        SensorEntry(date: .now, reading: .preview, selection: .both)
    }

    func snapshot(for configuration: SensorWidgetIntent, in context: Context) async -> SensorEntry {
        SensorEntry(date: .now, reading: context.isPreview ? .preview : ReadingStore.shared.load(), selection: configuration.sensor)
    }

    func timeline(for configuration: SensorWidgetIntent, in context: Context) async -> Timeline<SensorEntry> {
        let reading = ReadingStore.shared.load()
        var entries = [SensorEntry(date: .now, reading: reading, selection: configuration.sensor)]
        if let reading {
            let staleDate = reading.timestamp.addingTimeInterval(SensorReading.staleInterval + 1)
            if staleDate > .now {
                entries.append(SensorEntry(date: staleDate, reading: reading, selection: configuration.sensor))
            }
        }
        let refresh: TimeInterval = reading == nil ? 60 : 15 * 60
        return Timeline(entries: entries, policy: .after(.now.addingTimeInterval(refresh)))
    }

    func recommendations() -> [AppIntentRecommendation<SensorWidgetIntent>] {
        [
            AppIntentRecommendation(intent: SensorWidgetIntent(sensor: .both), description: "CO i Gaz"),
            AppIntentRecommendation(intent: SensorWidgetIntent(sensor: .co), description: "CO"),
            AppIntentRecommendation(intent: SensorWidgetIntent(sensor: .gas), description: "Gaz")
        ]
    }

    func relevances() async -> WidgetRelevance<SensorWidgetIntent> {
        WidgetRelevance([])
    }
}
