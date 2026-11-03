import Foundation

/// WatchConnectivity dictionary format used to relay readings from iPhone to Watch.
public enum RelayPayload {
    static let readingKey = "reading"

    public static func encode(_ reading: SensorReading) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(reading) else { return [:] }
        return [readingKey: data]
    }

    public static func decode(_ payload: [String: Any]) -> SensorReading? {
        guard let data = payload[readingKey] as? Data else { return nil }
        return try? JSONDecoder().decode(SensorReading.self, from: data)
    }
}
