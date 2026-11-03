import SwiftUI
import WidgetKit
import GasCoKit

@main
struct SensorWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKinds.sensor, intent: SensorWidgetIntent.self, provider: SensorTimelineProvider()) { entry in
            SensorWidgetView(entry: entry)
        }
        .configurationDisplayName("Gaz / CO")
        .description("Aktualny poziom CO i gazu z czujnika.")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(watchOS)
        [.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline]
        #else
        [.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #endif
    }
}

#Preview(as: .accessoryRectangular) {
    SensorWidget()
} timeline: {
    SensorEntry(date: .now, reading: .preview, selection: .both)
    SensorEntry(date: .now, reading: .previewAlarm, selection: .both)
    SensorEntry(date: .now, reading: nil, selection: .both)
}

#Preview(as: .accessoryCircular) {
    SensorWidget()
} timeline: {
    SensorEntry(date: .now, reading: .preview, selection: .gas)
    SensorEntry(date: .now, reading: .previewAlarm, selection: .co)
}
