import Foundation

public struct SensorReading: Codable, Equatable, Sendable {
    public var co: Int
    public var gas: Int
    public var isCOAlarmActive: Bool
    public var isGasAlarmActive: Bool
    public var timestamp: Date

    public init(co: Int, gas: Int, isCOAlarmActive: Bool, isGasAlarmActive: Bool, timestamp: Date = .now) {
        self.co = co
        self.gas = gas
        self.isCOAlarmActive = isCOAlarmActive
        self.isGasAlarmActive = isGasAlarmActive
        self.timestamp = timestamp
    }

    public var coLevel: DangerLevel { DangerLevel(value: co, isAlarmActive: isCOAlarmActive) }
    public var gasLevel: DangerLevel { DangerLevel(value: gas, isAlarmActive: isGasAlarmActive) }
    public var isAnyAlarmActive: Bool { isCOAlarmActive || isGasAlarmActive }
    public var worstLevel: DangerLevel { max(coLevel, gasLevel) }

    public func isStale(now: Date = .now, after interval: TimeInterval = SensorReading.staleInterval) -> Bool {
        now.timeIntervalSince(timestamp) > interval
    }

    public static let staleInterval: TimeInterval = 15 * 60

    public static let preview = SensorReading(co: 23, gas: 61, isCOAlarmActive: false, isGasAlarmActive: false)
    public static let previewAlarm = SensorReading(co: 87, gas: 12, isCOAlarmActive: true, isGasAlarmActive: false)
}
