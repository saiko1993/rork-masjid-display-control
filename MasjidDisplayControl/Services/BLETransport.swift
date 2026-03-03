import Foundation
import CoreBluetooth

let masjidServiceUUID = CBUUID(string: "9B2F6A6E-2C3A-4C6D-9E5F-2A7B1E0C8D11")
let themeCharacteristicUUID = CBUUID(string: "6D1C2A8B-7F7C-4B53-9D3B-10C78E8A4F01")
let syncCharacteristicUUID = CBUUID(string: "3A91A0C4-1E1F-4D5A-8A2F-5D2B6E7C9012")
let ackCharacteristicUUID = CBUUID(string: "0E6F1D2C-3B4A-4C5D-8E9F-1A2B3C4D5E6F")

nonisolated struct DiscoveredDevice: Identifiable, Sendable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    let lastSeen: Date
    let isMasjidDevice: Bool

    init(peripheral: CBPeripheral, rssi: Int, targetName: String) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = peripheral.name ?? "Unknown Device"
        self.rssi = rssi
        self.lastSeen = Date()
        self.isMasjidDevice = (peripheral.name ?? "").contains(targetName)
    }
}

@Observable
@MainActor
class BLEManager: NSObject {
    var connectionState: BLEConnectionState = .disconnected
    var discoveredDevices: [DiscoveredDevice] = []
    var connectedPeripheral: CBPeripheral?
    var lastError: String?
    var mtu: Int = 20
    var lastAckMessage: String?
    var isPoweredOn: Bool = false
    var scanDuration: TimeInterval = 0
    var connectedDeviceName: String?

    private var centralManager: CBCentralManager?
    private var themeCharacteristic: CBCharacteristic?
    private var syncCharacteristic: CBCharacteristic?
    private var ackCharacteristic: CBCharacteristic?
    private var targetDeviceName: String = "MasjidDisplay"
    private var writeCompletion: ((Result<Void, Error>) -> Void)?
    private var ackContinuation: CheckedContinuation<String, Error>?
    private let maxChunkRetries = 3
    private var scanTimer: Timer?
    private var scanStartTime: Date?

    func start(targetName: String) {
        targetDeviceName = targetName
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func startScanning() {
        guard let cm = centralManager, cm.state == .poweredOn else {
            if centralManager == nil {
                centralManager = CBCentralManager(delegate: self, queue: nil)
            }
            return
        }
        connectionState = .scanning
        discoveredDevices = []
        lastError = nil
        scanStartTime = Date()
        scanDuration = 0

        cm.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.scanStartTime else { return }
                self.scanDuration = Date().timeIntervalSince(start)
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(15))
            if connectionState == .scanning {
                stopScanning()
            }
        }
    }

    func stopScanning() {
        centralManager?.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }

    func connect(to device: DiscoveredDevice) {
        stopScanning()
        connectionState = .connecting
        connectedPeripheral = device.peripheral
        connectedDeviceName = device.name
        device.peripheral.delegate = self
        centralManager?.connect(device.peripheral, options: nil)
    }

    func connectToPeripheral(_ peripheral: CBPeripheral) {
        stopScanning()
        connectionState = .connecting
        connectedPeripheral = peripheral
        connectedDeviceName = peripheral.name ?? "Unknown"
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        cleanup()
    }

    func writeThemePack(data: Data) async throws {
        guard let characteristic = themeCharacteristic else {
            throw TransportError.bleNotReady
        }
        try await writeChunked(data: data, to: characteristic, withResponse: true)
    }

    func writeLightSync(data: Data) async throws {
        guard let characteristic = syncCharacteristic else {
            throw TransportError.bleNotReady
        }
        try await writeChunked(data: data, to: characteristic, withResponse: true)
    }

    var isReady: Bool {
        connectionState == .ready && themeCharacteristic != nil && syncCharacteristic != nil
    }

    func waitForAck(pushId: String, timeout: TimeInterval = 10) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            ackContinuation = continuation
            Task {
                try await Task.sleep(for: .seconds(timeout))
                if let pending = ackContinuation {
                    ackContinuation = nil
                    pending.resume(throwing: TransportError.timeout)
                }
            }
        }
    }

    private func writeChunked(data: Data, to characteristic: CBCharacteristic, withResponse: Bool) async throws {
        guard let peripheral = connectedPeripheral else {
            throw TransportError.notConnected
        }

        let chunkSize = max(mtu - 3, 20)
        let pushId = String(UUID().uuidString.prefix(8))
        let totalChunks = Int(ceil(Double(data.count) / Double(chunkSize)))

        let header = "MSDC:\(pushId):\(totalChunks):\(data.count)\n".data(using: .utf8) ?? Data()
        try await writeWithContinuation(peripheral: peripheral, data: header, characteristic: characteristic, type: .withResponse)

        for i in 0..<totalChunks {
            let start = i * chunkSize
            let end = min(start + chunkSize, data.count)
            let chunk = data[start..<end]

            var sent = false
            for attempt in 0..<maxChunkRetries {
                do {
                    try await writeWithContinuation(peripheral: peripheral, data: Data(chunk), characteristic: characteristic, type: withResponse ? .withResponse : .withoutResponse)
                    sent = true
                    break
                } catch {
                    if attempt == maxChunkRetries - 1 { throw error }
                    try await Task.sleep(for: .milliseconds(100 * (attempt + 1)))
                }
            }
            if !sent { throw TransportError.bleWriteFailed }
        }

        let footer = "MSDC:END:\(pushId)\n".data(using: .utf8) ?? Data()
        try await writeWithContinuation(peripheral: peripheral, data: footer, characteristic: characteristic, type: .withResponse)

        if withResponse, ackCharacteristic != nil {
            do {
                let ack = try await waitForAck(pushId: pushId, timeout: 10)
                if ack.contains("ERR") {
                    throw TransportError.bleWriteFailed
                }
            } catch is TransportError {
                throw TransportError.bleWriteFailed
            }
        }
    }

    private func writeWithContinuation(peripheral: CBPeripheral, data: Data, characteristic: CBCharacteristic, type: CBCharacteristicWriteType) async throws {
        if type == .withoutResponse {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            writeCompletion = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    private func cleanup() {
        connectedPeripheral = nil
        connectedDeviceName = nil
        themeCharacteristic = nil
        syncCharacteristic = nil
        ackCharacteristic = nil
        connectionState = .disconnected
    }
}

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            isPoweredOn = central.state == .poweredOn
            if central.state == .poweredOn && connectionState == .disconnected {
                lastError = nil
            } else if central.state != .poweredOn {
                lastError = bleStateMessage(central.state)
                cleanup()
            }
        }
    }

    nonisolated private func bleStateMessage(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOff: return "Bluetooth is turned off"
        case .unauthorized: return "Bluetooth permission denied"
        case .unsupported: return "Bluetooth not supported"
        case .resetting: return "Bluetooth is resetting"
        default: return "Bluetooth is not available"
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let rssiVal = RSSI.intValue
        guard rssiVal > -100 && rssiVal < 0 else { return }

        Task { @MainActor in
            let device = DiscoveredDevice(peripheral: peripheral, rssi: rssiVal, targetName: targetDeviceName)
            if let idx = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                discoveredDevices[idx] = device
            } else {
                discoveredDevices.append(device)
                discoveredDevices.sort { d1, d2 in
                    if d1.isMasjidDevice != d2.isMasjidDevice { return d1.isMasjidDevice }
                    return d1.rssi > d2.rssi
                }
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            connectionState = .connected
            peripheral.discoverServices([masjidServiceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            lastError = error?.localizedDescription ?? "Connection failed"
            cleanup()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            if connectionState != .disconnected {
                lastError = "Device disconnected"
            }
            cleanup()
        }
    }
}

extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard let service = peripheral.services?.first(where: { $0.uuid == masjidServiceUUID }) else {
                lastError = "Masjid Display service not found"
                return
            }
            peripheral.discoverCharacteristics(
                [themeCharacteristicUUID, syncCharacteristicUUID, ackCharacteristicUUID],
                for: service
            )
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard let characteristics = service.characteristics else { return }
            for c in characteristics {
                switch c.uuid {
                case themeCharacteristicUUID:
                    themeCharacteristic = c
                case syncCharacteristicUUID:
                    syncCharacteristic = c
                case ackCharacteristicUUID:
                    ackCharacteristic = c
                    peripheral.setNotifyValue(true, for: c)
                default:
                    break
                }
            }

            if themeCharacteristic != nil && syncCharacteristic != nil {
                connectionState = .ready
                mtu = peripheral.maximumWriteValueLength(for: .withResponse)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            if let error {
                writeCompletion?(.failure(error))
            } else {
                writeCompletion?(.success(()))
            }
            writeCompletion = nil
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            if characteristic.uuid == ackCharacteristicUUID {
                if let data = characteristic.value, let message = String(data: data, encoding: .utf8) {
                    lastAckMessage = message
                    if let pending = ackContinuation {
                        ackContinuation = nil
                        pending.resume(returning: message)
                    }
                }
            }
        }
    }
}

struct BLESyncTransport: SyncTransport {
    let transportName = "Bluetooth"
    let bleManager: BLEManager

    func sendThemePack(data: Data, config: TransportConfig) async throws {
        guard bleManager.isReady else {
            throw TransportError.bleNotReady
        }
        try await bleManager.writeThemePack(data: data)
    }

    func sendLightSync(data: Data, config: TransportConfig) async throws {
        guard bleManager.isReady else {
            throw TransportError.bleNotReady
        }
        try await bleManager.writeLightSync(data: data)
    }

    func testConnection(config: TransportConfig) async throws -> String {
        guard bleManager.isReady else {
            throw TransportError.bleNotReady
        }
        return "Connected via Bluetooth (MTU: \(bleManager.mtu))"
    }
}
