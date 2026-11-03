import Foundation
import UIKit
import UserNotifications
import GasCoKit

@MainActor
final class AlarmNotifier {
    private var lastLevel: DangerLevel = .safe
    private let feedback = UINotificationFeedbackGenerator()

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func handle(_ reading: SensorReading) {
        let level = reading.worstLevel
        defer { lastLevel = level }
        guard level > lastLevel, level >= .warning else { return }
        feedback.notificationOccurred(level == .danger ? .error : .warning)
        post(reading, level: level)
    }

    private func post(_ reading: SensorReading, level: DangerLevel) {
        let content = UNMutableNotificationContent()
        content.title = level.title
        content.body = "\(SensorKind.co.title): \(reading.co)%, \(SensorKind.gas.title): \(reading.gas)%"
        content.sound = .default
        content.interruptionLevel = level == .danger ? .timeSensitive : .active
        let request = UNNotificationRequest(identifier: "gasco.alarm", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
