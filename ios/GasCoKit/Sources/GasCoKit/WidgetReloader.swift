import Foundation
import WidgetKit

@MainActor
public final class WidgetReloader {
    private var lastLevel: DangerLevel?
    private var lastReload: Date = .distantPast
    private let minimumInterval: TimeInterval = 60

    public init() {}

    public func reloadNow() {
        lastReload = .now
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.sensor)
    }

    public func handle(_ reading: SensorReading) {
        let level = reading.worstLevel
        guard level != lastLevel || Date.now.timeIntervalSince(lastReload) >= minimumInterval else { return }
        lastLevel = level
        lastReload = .now
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.sensor)
    }
}
