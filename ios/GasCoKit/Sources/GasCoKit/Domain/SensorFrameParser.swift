import Foundation

/// Frame layout: [co, gas, coAlarm, gasAlarm]. Alarm byte equal to 0 means alarm is active.
public enum SensorFrameParser {
    enum ByteIndex: Int {
        case co, gas, coAlarm, gasAlarm
    }

    public static func parse(_ data: Data, timestamp: Date = .now) -> SensorReading? {
        let bytes = [UInt8](data)
        guard bytes.count > ByteIndex.gas.rawValue else { return nil }
        return SensorReading(
            co: Int(bytes[ByteIndex.co.rawValue]),
            gas: Int(bytes[ByteIndex.gas.rawValue]),
            isCOAlarmActive: isAlarmActive(bytes, .coAlarm),
            isGasAlarmActive: isAlarmActive(bytes, .gasAlarm),
            timestamp: timestamp
        )
    }

    private static func isAlarmActive(_ bytes: [UInt8], _ index: ByteIndex) -> Bool {
        guard bytes.indices.contains(index.rawValue) else { return false }
        return bytes[index.rawValue] == 0
    }
}
