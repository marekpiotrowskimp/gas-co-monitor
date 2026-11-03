import WatchKit
import GasCoKit

@MainActor
final class AlarmHaptics {
    private var lastPlayed: Date = .distantPast
    private let interval: TimeInterval = 5

    func handle(_ reading: SensorReading) {
        guard reading.worstLevel == .danger, Date.now.timeIntervalSince(lastPlayed) >= interval else { return }
        lastPlayed = .now
        WKInterfaceDevice.current().play(.notification)
    }
}
