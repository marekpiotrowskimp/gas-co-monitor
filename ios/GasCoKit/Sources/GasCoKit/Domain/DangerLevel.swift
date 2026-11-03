import Foundation

public enum DangerLevel: Int, Comparable, Sendable, CaseIterable {
    case safe
    case warning
    case danger

    public static let warningThreshold = 51
    public static let dangerThreshold = 71

    public init(value: Int, isAlarmActive: Bool = false) {
        if isAlarmActive || value >= Self.dangerThreshold {
            self = .danger
        } else if value >= Self.warningThreshold {
            self = .warning
        } else {
            self = .safe
        }
    }

    public static func < (lhs: DangerLevel, rhs: DangerLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var title: String {
        switch self {
        case .safe: String(localized: "Poziom bezpieczny", bundle: .module)
        case .warning: String(localized: "Podwyższony poziom", bundle: .module)
        case .danger: String(localized: "Niebezpieczny poziom!", bundle: .module)
        }
    }

    public var shortTitle: String {
        switch self {
        case .safe: String(localized: "OK", bundle: .module)
        case .warning: String(localized: "Uwaga", bundle: .module)
        case .danger: String(localized: "Alarm", bundle: .module)
        }
    }

    public var symbolName: String {
        switch self {
        case .safe: "checkmark.shield.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .danger: "light.beacon.max.fill"
        }
    }
}
