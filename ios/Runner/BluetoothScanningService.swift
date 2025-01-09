import Foundation
import CoreBluetooth
import MTBeaconPlus
import UIKit

class BluetoothScanningService: NSObject{
    private var mtCentralManager: MTCentralManager?
    private var mtFrameHandler: MTFrameHandler?
    private var counter = 0
    private var beacons : [Any] = []
    var scannerDevices : Array<MTPeripheral> = []
    

    func startService() {
        mtCentralManager = MTCentralManager.sharedInstance()
        startScanning()
    }

    public func startScanning() {
        mtCentralManager?.stopScan()
        mtCentralManager?.stateBlock = { state in
            print("Current Bluetooth state: \(state.rawValue)")
        }
        
        mtCentralManager?.startScan { (devices) in
            self.scannerDevices = self.mtCentralManager?.scannedPeris ?? []
            print(devices ?? "nothing")
            self.beacons = []
            for device in self.scannerDevices {
                print("Discovered peripheral: \(String(describing: device.framer.mac))")
//                self.backgroundCheckNotification(contents: "Able to discover peripheral", identifier: "appleBG")
                self.beacons.append(self.convertPeripheralToDictionary(peripheral: device))
            }
            let jsonData = try? JSONSerialization.data(withJSONObject: self.beacons, options: [])
            if let jsonData = jsonData {
                print("WAWAWAWAWAWAWAWAAWAWAWAWA \(jsonData)")
                self.writeFile(jsonData: jsonData)
            }
        }
    }
    
    func backgroundCheckNotification(contents: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Telematics app"
        content.body = "\(contents)"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling background notification: \(error)")
            }
        }
    }


    private func convertPeripheralToDictionary(peripheral: MTPeripheral) -> [String: Any] {
        var frames: [[String: Any]] = []
        let handler = peripheral.framer
        for frame in handler?.advFrames ?? [] {
            switch frame.frameType {
            case .FrameiBeacon:
                let iBeaconFrame = frame as! MinewiBeacon
                frames.append([
                    "type": "ibeacon",
                    "uuid": iBeaconFrame.uuid ?? "",
                    "major": iBeaconFrame.major,
                    "minor": iBeaconFrame.minor,
                    "tx": iBeaconFrame.txPower
                ])
            case .FrameUID:
                let uidFrame = frame as! MinewUID
                frames.append([
                    "type": "uid",
                    "namespace": uidFrame.namespaceId!,
                    "instance": uidFrame.instanceId!
                ])
            case .FrameAccSensor:
                let accFrame = frame as! MinewAccSensor
                frames.append([
                    "type": "accelerometer",
                    "x": accFrame.xAxis,
                    "y": accFrame.yAxis,
                    "z": accFrame.zAxis
                ])
            case .FrameHTSensor:
                let htFrame = frame as! MinewHTSensor
                frames.append([
                    "type": "ht",
                    "temperature": htFrame.temperature,
                    "humidity": htFrame.humidity
                ])
            case .FrameTLM:
                let tlmFrame = frame as! MinewTLM
                frames.append([
                    "type": "tlm",
                    "temperature": tlmFrame.temperature,
                    "batteryVol": tlmFrame.batteryVol,
                    "secCount": tlmFrame.secCount,
                    "advCount": tlmFrame.advCount
                ])
            case .FrameURL:
                let urlFrame = frame as! MinewURL
                frames.append([
                    "type": "url",
                    "tx": urlFrame.txPower,
                    "url": urlFrame.urlString!
                ])
            case .FrameLightSensor:
                let lightFrame = frame as! MinewLightSensor
                frames.append([
                    "type": "light",
                    "battery": lightFrame.battery,
                    "lux": lightFrame.luxValue
                ])
            case .FrameForceSensor:
                let forceFrame = frame as! MinewForceSensor
                frames.append([
                    "type": "force",
                    "battery": forceFrame.battery,
//                    "force": forceFrame.force
                ])
            case .FramePIRSensor:
                let pirFrame = frame as! MinewPIRSensor
                frames.append([
                    "type": "pir",
                    "battery": pirFrame.battery
                ])
//            case .FrameTempSensor:
//                let temperatureFrame = frame as! MinewTempSensor
//                frames.append([
//                    "type": "temperature",
//                    "battery": temperatureFrame.battery,
//                    "temperature": temperatureFrame.value
//                ])
            case .FrameTVOCSensor:
                let tvocFrame = frame as! MinewTVOCSensor
                frames.append([
                    "type": "tvoc",
                    "battery": tvocFrame.battery,
                    "tvoc": tvocFrame.value
                ])
            case .FrameLineBeacon:
                let lineBeaconFrame = frame as! MinewLineBeacon
                frames.append([
                    "type": "line",
                    "hwid": lineBeaconFrame.hwId,
                    "tx": lineBeaconFrame.txPower,
                    "auth": lineBeaconFrame.authenticationCode,
                    "timestamp": lineBeaconFrame.timestamp
                ])
            case .FrameDeviceInfo:
                let deviceInfoFrame = frame as! MinewDeviceInfo
                frames.append([
                    "type": "info",
                    "mac": deviceInfoFrame.mac!,
                    "name": deviceInfoFrame.name!,
                    "battery": deviceInfoFrame.battery
                ])
            default:
                print("default")
            }
        }
        
        print("KUKDUKU \(handler?.advLastUpdate.description)")

        if #available(iOS 15.0, *) {
            return [
                "mac": handler?.mac ?? "",
                "name": handler?.name ?? "",
                "battery": handler?.battery ?? 0,
                "rssi": handler?.rssi ?? 0,
                "lastUpdate": handler?.advLastUpdate.ISO8601Format() ?? 0,
                "frames": frames
            ]
        } else {
            return [
                "mac": handler?.mac ?? "",
                "name": handler?.name ?? "",
                "battery": handler?.battery ?? 0,
                "rssi": handler?.rssi ?? 0,
                "lastUpdate": handler?.advLastUpdate.timeIntervalSinceNow ?? 0,
                "frames": frames
            ]
        }
    }

     func writeFile(jsonData: Data) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentDirectory = urls.first {
            let fileURL = documentDirectory.appendingPathComponent("beacons.json")
            do {
                try jsonData.write(to: fileURL)
                print("File written to: \(fileURL.path)")
            } catch {
                print("Error writing file: \(error)")
            }
        }
    }
    
    func updateBeaconData(uuid: String, major: Int, minor: Int, rssi: Int) {
            let fileManager = FileManager.default
            let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            if let documentDirectory = urls.first {
                let fileURL = documentDirectory.appendingPathComponent("beacons.json")
                do {
                    let data = try Data(contentsOf: fileURL)
                    var beacons = try JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
                    
                    if let index = beacons.firstIndex(where: { beacon in
                        guard let frames = beacon["frames"] as? [[String: Any]] else { return false }
                        for frame in frames {
                            if frame["type"] as? String == "ibeacon",
                               let frameUUID = frame["uuid"] as? String, frameUUID == uuid,
                               let frameMajor = frame["major"] as? Int, frameMajor == major,
                               let frameMinor = frame["minor"] as? Int, frameMinor == minor {
                                return true
                            }
                        }
                        return false
                    }) {
                        if #available(iOS 15.0, *) {
                            beacons[index]["rssi"] = rssi
                            beacons[index]["lastUpdate"] = ISO8601DateFormatter().string(from: Date())
                        } else {
                            beacons[index]["rssi"] = rssi
                            beacons[index]["lastUpdate"] = Date().timeIntervalSince1970
                        }
                        
                        let updatedData = try JSONSerialization.data(withJSONObject: beacons, options: [])
                        try updatedData.write(to: fileURL); backgroundCheckNotification(contents: "Beacon data updated successfully.", identifier: "update")
                    }
                } catch {
                    print("Error updating beacon data: \(error)")
                    backgroundCheckNotification(contents: "Beacon data did not update.", identifier: "update")
                }
            }
        }

    private func clearFile() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentDirectory = urls.first {
            let fileURL = documentDirectory.appendingPathComponent("beacons.json")
            do {
                try "".write(to: fileURL, atomically: true, encoding: .utf8)
                print("File cleared successfully.")
            } catch {
                print("Error clearing file: \(error)")
            }
        }
    }
    
    func stopService() {
        mtCentralManager?.stopScan()
    }
    
    
    

//    private func restartScanning() {
//        mtCentralManager?.stopScan()
////        mtCentralManager?.clear()
//        mtCentralManager?.startScan()
//    }

//    func mtCentralManager(_ manager: MTCentralManager!, didUpdate state: MTCentralManagerState) {
//        // Handle state updates if necessary
//    }

    deinit {
//        mtCentralManager?.stopScan()
//        mtCentralManager?.stopService()
    }
}

//import Foundation
//import CoreBluetooth
//
//class BluetoothScanningService: NSObject, CBCentralManagerDelegate {
//    private var centralManager: CBCentralManager?
//    private var discoveredPeripherals: [CBPeripheral] = []
//
//    override init() {
//        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//    }
//
//    func startScanning() {
//        print("Starting scan...")
//        centralManager?.scanForPeripherals(withServices: nil, options: nil)
//    }
//
//    func stopScanning() {
//        print("Stopping scan...")
//        centralManager?.stopScan()
//    }
//
//    // CBCentralManagerDelegate Methods
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        switch central.state {
//        case .poweredOn:
//            print("Bluetooth is On")
//            startScanning()
//        case .poweredOff:
//            print("Bluetooth is Off")
//        case .resetting:
//            print("Bluetooth is resetting")
//        case .unauthorized:
//            print("Bluetooth is not authorized")
//        case .unsupported:
//            print("Bluetooth is not supported on this device")
//        case .unknown:
//            print("Bluetooth state is unknown")
//        @unknown default:
//            fatalError("Unknown state")
//        }
//    }
//
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
//        print("Discovered peripheral: \(peripheral.name ?? "Unknown") at \(RSSI)")
//        discoveredPeripherals.append(peripheral)
//    }
//}

