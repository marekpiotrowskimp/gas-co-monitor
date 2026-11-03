import SwiftUI

public extension Color {
    static let gasCoBackground = Color.black
    static let safeLevel = Color(red: 0.19, green: 0.82, blue: 0.35)
    static let warningLevel = Color(red: 1.0, green: 0.84, blue: 0.04)
    static let dangerLevel = Color(red: 1.0, green: 0.27, blue: 0.23)
    static let staleLevel = Color.gray
    static let coAccent = Color(red: 0.39, green: 0.82, blue: 1.0)
    static let gasAccent = Color(red: 1.0, green: 0.62, blue: 0.04)
}

public extension DangerLevel {
    var color: Color {
        switch self {
        case .safe: .safeLevel
        case .warning: .warningLevel
        case .danger: .dangerLevel
        }
    }
}

public extension SensorKind {
    var accent: Color {
        switch self {
        case .co: .coAccent
        case .gas: .gasAccent
        }
    }
}

public extension Gradient {
    static let dangerScale = Gradient(stops: [
        .init(color: .safeLevel, location: 0),
        .init(color: .safeLevel, location: 0.45),
        .init(color: .warningLevel, location: 0.6),
        .init(color: .dangerLevel, location: 0.8)
    ])
}
