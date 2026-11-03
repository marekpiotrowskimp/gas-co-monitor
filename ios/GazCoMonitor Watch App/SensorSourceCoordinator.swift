import Foundation
import GasCoKit

/// The sensor accepts a single BLE connection, which the iPhone normally holds.
/// The Watch takes readings relayed by the iPhone and connects over BLE only
/// as a fallback when the relay goes quiet, releasing the sensor as soon as the relay is back.
@MainActor
final class SensorSourceCoordinator {
    let relay = ReadingRelay()
    private let model: MonitorModel
    private var isActive = false
    private var fallbackTask: Task<Void, Never>?
    private let launchGrace: Duration = .seconds(3)

    init(model: MonitorModel) {
        self.model = model
    }

    func start() {
        relay.onReading = { [weak self] reading in
            self?.handleRelayed(reading)
        }
        relay.activate()
    }

    func becameActive() {
        isActive = true
        scheduleFallback(after: model.isRelayFresh() ? nil : launchGrace)
    }

    func enteredBackground() {
        isActive = false
        fallbackTask?.cancel()
        model.stop()
    }

    private func handleRelayed(_ reading: SensorReading) {
        model.receiveRelayed(reading)
        guard model.isRelayFresh() else { return }
        if model.state != .idle { model.stop() }
        scheduleFallback(after: nil)
    }

    /// Starts BLE once the relay has been silent for `MonitorModel.relayFreshness`.
    private func scheduleFallback(after delay: Duration?) {
        fallbackTask?.cancel()
        guard isActive else { return }
        let wait: Duration
        if let delay {
            wait = delay
        } else if let lastRelayAt = model.lastRelayAt {
            let remaining = MonitorModel.relayFreshness - Date.now.timeIntervalSince(lastRelayAt)
            wait = .seconds(max(remaining, 0) + 1)
        } else {
            wait = .zero
        }
        fallbackTask = Task { [weak self] in
            try? await Task.sleep(for: wait)
            guard !Task.isCancelled, let self, self.isActive, !self.model.isRelayFresh() else { return }
            self.model.start()
        }
    }
}
