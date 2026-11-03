#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity
import OSLog

/// Relays sensor readings from the iPhone (the only BLE client of the sensor) to the Watch.
@MainActor
public final class ReadingRelay: NSObject {
    /// Called on the receiving side (Watch) for every reading newer than the last delivered one.
    public var onReading: ((SensorReading) -> Void)?

    private let session: WCSession? = WCSession.isSupported() ? .default : nil
    private let logger = Logger(subsystem: "GasCoKit", category: "Relay")
    private var lastDelivered: Date = .distantPast
    #if os(iOS)
    private var lastLevel: DangerLevel?
    private var lastContextSent: Date = .distantPast
    private var lastMessageSent: Date = .distantPast
    private let contextInterval: TimeInterval = 30
    private let messageInterval: TimeInterval = 1
    #endif

    public override init() {
        super.init()
    }

    public func activate() {
        guard let session, session.activationState != .activated else { return }
        session.delegate = self
        session.activate()
    }

    /// Waits until queued WatchConnectivity transfers have been delivered (for the Watch background task).
    public func waitForPendingContent(timeout: Duration = .seconds(10)) async {
        activate()
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while let session, session.hasContentPending || session.activationState != .activated, clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(200))
        }
    }

    #if os(iOS)
    public func send(_ reading: SensorReading) {
        guard let session, session.activationState == .activated,
              session.isPaired, session.isWatchAppInstalled else { return }
        let payload = RelayPayload.encode(reading)
        let level = reading.worstLevel
        let levelChanged = level != lastLevel
        let now = Date.now

        if session.isReachable, levelChanged || now.timeIntervalSince(lastMessageSent) >= messageInterval {
            lastMessageSent = now
            session.sendMessage(payload, replyHandler: nil) { [logger] error in
                logger.debug("sendMessage failed: \(error.localizedDescription)")
            }
        }
        if levelChanged || now.timeIntervalSince(lastContextSent) >= contextInterval {
            do {
                try session.updateApplicationContext(payload)
                lastContextSent = now
            } catch {
                logger.error("updateApplicationContext failed: \(error.localizedDescription)")
            }
        }
        if levelChanged, lastLevel != nil, session.isComplicationEnabled,
           session.remainingComplicationUserInfoTransfers > 0 {
            session.transferCurrentComplicationUserInfo(payload)
        }
        lastLevel = level
    }
    #endif

    private func deliver(_ reading: SensorReading) {
        guard reading.timestamp > lastDelivered else { return }
        lastDelivered = reading.timestamp
        onReading?(reading)
    }

    nonisolated private func receive(_ payload: [String: Any]) {
        guard let reading = RelayPayload.decode(payload) else { return }
        Task { @MainActor in self.deliver(reading) }
    }
}

extension ReadingRelay: WCSessionDelegate {
    nonisolated public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                                    error: Error?) {
        if activationState == .activated {
            receive(session.receivedApplicationContext)
        }
    }

    nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }

    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    nonisolated public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        receive(userInfo)
    }

    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        // The user switched to another Watch; activate for the new one.
        session.activate()
    }
    #endif
}
#endif
