import Foundation
import CoreBluetooth
import Observation
import OSLog

@MainActor
@Observable
public final class SensorConnection: NSObject {
    public private(set) var state: SensorConnectionState = .idle
    public private(set) var latestReading: SensorReading?
    public private(set) var discovered: [DiscoveredSensor] = []
    @ObservationIgnored public var onReading: ((SensorReading) -> Void)?

    @ObservationIgnored private var central: CBCentralManager?
    @ObservationIgnored private var peripheral: CBPeripheral?
    @ObservationIgnored private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    @ObservationIgnored private var autoConnect = true
    @ObservationIgnored private let restoreIdentifier: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let logger = Logger(subsystem: "GasCoKit", category: "BLE")

    static let manufacturerPrefix: [UInt8] = [0x69, 0x69, 0x02]
    static let uartRXUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    private static let rememberedIDKey = "peripheralIdKey"
    private static let rememberedNameKey = "peripheralNameKey"

    public init(restoreIdentifier: String? = nil, defaults: UserDefaults = .standard) {
        self.restoreIdentifier = restoreIdentifier
        self.defaults = defaults
        super.init()
    }

    public var rememberedSensorName: String? {
        defaults.string(forKey: Self.rememberedNameKey)
    }

    private var rememberedID: UUID? {
        defaults.string(forKey: Self.rememberedIDKey).flatMap(UUID.init(uuidString:))
    }

    public func start() {
        autoConnect = true
        guard let central else {
            var options: [String: Any] = [:]
            #if os(iOS)
            if let restoreIdentifier {
                options[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
            }
            #endif
            central = CBCentralManager(delegate: self, queue: nil, options: options)
            return
        }
        if peripheral == nil {
            connectToKnownOrScan(central)
        }
    }

    public func scanForSensors() {
        disconnectCurrent()
        discovered = []
        discoveredPeripherals = [:]
        autoConnect = false
        guard let central, central.state == .poweredOn else {
            start()
            autoConnect = false
            return
        }
        beginScan(central)
    }

    public func connect(to sensor: DiscoveredSensor) {
        guard let central, let target = discoveredPeripherals[sensor.id] else { return }
        central.stopScan()
        connect(target, using: central)
    }

    public func forgetSensor() {
        defaults.removeObject(forKey: Self.rememberedIDKey)
        defaults.removeObject(forKey: Self.rememberedNameKey)
        disconnectCurrent()
        start()
    }

    public func stop() {
        central?.stopScan()
        disconnectCurrent()
        state = .idle
    }

    private func disconnectCurrent() {
        let current = peripheral
        peripheral = nil
        if let current { central?.cancelPeripheralConnection(current) }
    }

    private func connectToKnownOrScan(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        if let id = rememberedID, let known = central.retrievePeripherals(withIdentifiers: [id]).first {
            connect(known, using: central)
        } else {
            beginScan(central)
        }
    }

    private func beginScan(_ central: CBCentralManager) {
        state = .scanning
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    private func connect(_ target: CBPeripheral, using central: CBCentralManager) {
        peripheral = target
        target.delegate = self
        state = .connecting(name: target.name ?? rememberedSensorName ?? "")
        central.connect(target, options: nil)
    }

    private func remember(_ peripheral: CBPeripheral) {
        defaults.set(peripheral.identifier.uuidString, forKey: Self.rememberedIDKey)
        defaults.set(peripheral.name ?? "", forKey: Self.rememberedNameKey)
    }

    private func handle(_ data: Data) {
        guard let reading = SensorFrameParser.parse(data) else { return }
        latestReading = reading
        onReading?(reading)
    }
}

extension SensorConnection: @preconcurrency CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if let peripheral, peripheral.state == .connected {
                state = .connected(name: peripheral.name ?? "")
                peripheral.discoverServices(nil)
            } else {
                connectToKnownOrScan(central)
            }
        case .poweredOff: state = .bluetoothUnavailable(.poweredOff)
        case .unauthorized: state = .bluetoothUnavailable(.unauthorized)
        case .unsupported: state = .bluetoothUnavailable(.unsupported)
        default: state = .idle
        }
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        guard let restored = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first else { return }
        peripheral = restored
        restored.delegate = self
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                               advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name,
              let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              [UInt8](manufacturerData).starts(with: Self.manufacturerPrefix) else { return }

        if autoConnect {
            central.stopScan()
            connect(peripheral, using: central)
            return
        }
        discoveredPeripherals[peripheral.identifier] = peripheral
        if !discovered.contains(where: { $0.id == peripheral.identifier }) {
            discovered.append(DiscoveredSensor(id: peripheral.identifier, name: name, rssi: RSSI.intValue))
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected \(peripheral.identifier)")
        remember(peripheral)
        autoConnect = true
        state = .connected(name: peripheral.name ?? "")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Connect failed: \(error?.localizedDescription ?? "-")")
        self.peripheral = nil
        state = .disconnected
        connectToKnownOrScan(central)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard peripheral.identifier == self.peripheral?.identifier else { return }
        state = .disconnected
        // Pending connect has no timeout; it completes when the sensor is back in range.
        connect(peripheral, using: central)
    }
}

extension SensorConnection: @preconcurrency CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] where characteristic.uuid == Self.uartRXUUID {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        handle(data)
    }
}
