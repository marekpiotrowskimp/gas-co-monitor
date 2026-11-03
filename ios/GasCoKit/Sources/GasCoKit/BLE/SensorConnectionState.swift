import Foundation

public enum SensorConnectionState: Equatable, Sendable {
    case idle
    case bluetoothUnavailable(BluetoothIssue)
    case scanning
    case connecting(name: String)
    case connected(name: String)
    case disconnected

    public enum BluetoothIssue: Sendable {
        case poweredOff, unauthorized, unsupported
    }

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    public var title: String {
        switch self {
        case .idle: String(localized: "Oczekiwanie", bundle: .module)
        case .bluetoothUnavailable(.poweredOff): String(localized: "Bluetooth wyłączony", bundle: .module)
        case .bluetoothUnavailable(.unauthorized): String(localized: "Brak zgody na Bluetooth", bundle: .module)
        case .bluetoothUnavailable(.unsupported): String(localized: "Bluetooth niedostępny", bundle: .module)
        case .scanning: String(localized: "Szukanie czujnika…", bundle: .module)
        case .connecting(let name): String(localized: "Łączenie z \(name)…", bundle: .module)
        case .connected(let name): String(localized: "Połączono z \(name)", bundle: .module)
        case .disconnected: String(localized: "Rozłączono, ponawianie…", bundle: .module)
        }
    }

    public var symbolName: String {
        switch self {
        case .connected: "dot.radiowaves.left.and.right"
        case .scanning, .connecting: "antenna.radiowaves.left.and.right"
        case .bluetoothUnavailable, .disconnected, .idle: "antenna.radiowaves.left.and.right.slash"
        }
    }
}

public struct DiscoveredSensor: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let rssi: Int
}
