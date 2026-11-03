import Foundation
import Observation

@MainActor
@Observable
public final class MonitorModel {
    public let connection: SensorConnection
    public private(set) var reading: SensorReading?
    /// Timestamp of the newest reading relayed from the iPhone (Watch only).
    public private(set) var lastRelayAt: Date?
    @ObservationIgnored public var onNewReading: ((SensorReading) -> Void)?
    @ObservationIgnored private let store: ReadingStore

    public init(connection: SensorConnection = SensorConnection(), store: ReadingStore = .shared) {
        self.connection = connection
        self.store = store
        self.reading = store.load()
        connection.onReading = { [weak self] reading in
            self?.receive(reading)
        }
    }

    public var state: SensorConnectionState { connection.state }

    public func start() {
        connection.start()
    }

    /// Releases the BLE connection so another device (the iPhone) can take the sensor's only slot.
    public func stop() {
        connection.stop()
    }

    public static let relayFreshness: TimeInterval = 60

    public func isRelayFresh(now: Date = .now) -> Bool {
        guard let lastRelayAt else { return false }
        return now.timeIntervalSince(lastRelayAt) <= Self.relayFreshness
    }

    /// Connects (if needed) and waits for a reading newer than the call time.
    public func refreshOnce(timeout: Duration) async -> SensorReading? {
        let requestedAt = Date.now
        start()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if let reading, reading.timestamp >= requestedAt { return reading }
            try? await Task.sleep(for: .milliseconds(500))
        }
        return nil
    }

    public func receiveRelayed(_ reading: SensorReading) {
        if let current = self.reading, current.timestamp >= reading.timestamp { return }
        lastRelayAt = reading.timestamp
        receive(reading)
    }

    public func receive(_ reading: SensorReading) {
        self.reading = reading
        store.save(reading)
        onNewReading?(reading)
    }

    public static func preview(_ reading: SensorReading? = .preview) -> MonitorModel {
        let model = MonitorModel(store: ReadingStore(directory: nil))
        model.reading = reading
        return model
    }
}
