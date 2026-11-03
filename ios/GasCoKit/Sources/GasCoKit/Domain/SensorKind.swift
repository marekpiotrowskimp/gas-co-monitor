import Foundation

public enum SensorKind: String, CaseIterable, Identifiable, Sendable, Codable {
    case co
    case gas

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .co: String(localized: "CO", bundle: .module)
        case .gas: String(localized: "Gaz", bundle: .module)
        }
    }

    public var symbolName: String {
        switch self {
        case .co: "carbon.monoxide.cloud.fill"
        case .gas: "flame.fill"
        }
    }
}

public extension SensorReading {
    func value(for kind: SensorKind) -> Int {
        switch kind {
        case .co: co
        case .gas: gas
        }
    }

    func level(for kind: SensorKind) -> DangerLevel {
        switch kind {
        case .co: coLevel
        case .gas: gasLevel
        }
    }

    func isAlarmActive(for kind: SensorKind) -> Bool {
        switch kind {
        case .co: isCOAlarmActive
        case .gas: isGasAlarmActive
        }
    }
}
