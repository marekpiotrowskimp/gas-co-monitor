import Foundation
import SwiftData
import GasCoKit

@Model
final class ReadingRecord {
    var timestamp: Date
    var co: Int
    var gas: Int
    var isAlarm: Bool

    init(_ reading: SensorReading) {
        timestamp = reading.timestamp
        co = reading.co
        gas = reading.gas
        isAlarm = reading.isAnyAlarmActive
    }
}

@MainActor
final class HistoryRecorder {
    private let context: ModelContext
    private var lastSaved: Date = .distantPast
    private let interval: TimeInterval = 30
    private let retention: TimeInterval = 24 * 60 * 60

    init(context: ModelContext) {
        self.context = context
    }

    func record(_ reading: SensorReading) {
        guard reading.timestamp.timeIntervalSince(lastSaved) >= interval || reading.isAnyAlarmActive else { return }
        lastSaved = reading.timestamp
        context.insert(ReadingRecord(reading))
        let cutoff = Date.now.addingTimeInterval(-retention)
        try? context.delete(model: ReadingRecord.self, where: #Predicate { $0.timestamp < cutoff })
        try? context.save()
    }

    #if DEBUG
    func seedDemoHistory(endingWith reading: SensorReading) {
        try? context.delete(model: ReadingRecord.self)
        for minute in stride(from: 60, through: 1, by: -1) {
            let t = Double(60 - minute) / 60
            let wave = sin(Double(minute) / 6)
            let sample = SensorReading(
                co: max(0, Int(Double(reading.co) * t + 12 + wave * 5)),
                gas: max(0, Int(Double(reading.gas) * (0.6 + 0.4 * t) + wave * 7)),
                isCOAlarmActive: false, isGasAlarmActive: false,
                timestamp: .now.addingTimeInterval(-Double(minute) * 60))
            context.insert(ReadingRecord(sample))
        }
        try? context.save()
    }
    #endif
}
