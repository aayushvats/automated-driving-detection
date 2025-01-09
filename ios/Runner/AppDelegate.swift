import UIKit
import Flutter
import GoogleMaps
import CoreLocation
import flutter_local_notifications
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    private let channelName = "com.example.telematic/minewsdk"
    private var bluetoothService: BluetoothScanningService?
    let locationManager = CLLocationManager()
    private var uuid = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")
    var beaconRegion: CLBeaconRegion?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBPlh4_U5eMRDt4mE4Q3MzA7_mdtQqDh8g")
        GeneratedPluginRegistrant.register(with: self)
        
        setupLocationManager()
        setupBeaconRegion()
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        
        methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "startMinewSDK" else {
                result(FlutterMethodNotImplemented)
                return
            }
            print("starting bluetooth service")
            self?.startBluetoothScanningService()
            result(nil)
        }
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        
        if let _ = launchOptions?[.location] {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        
        let flutterResult = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return flutterResult
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()  // Request 'Always' authorization
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    private func setupBeaconRegion() {
        guard let uuid = uuid else {
            print("Invalid UUID string")
            return
        }
        
        beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 0, minor: 0, identifier: "uynguyen")
        
        guard let beaconRegion = beaconRegion else {
            print("Beacon region setup failed")
            return
        }
        print("beacon ranging")
        locationManager.startMonitoring(for: beaconRegion)
        if #available(iOS 13.0, *) {
            let beaconRegionConstraint = CLBeaconIdentityConstraint(uuid: uuid, major: 0, minor: 0)
            locationManager.startRangingBeacons(satisfying: beaconRegionConstraint)
            print("Started beacon ranging for iOS 13+")
//            backgroundCheckNotification(contents: "Started beacon ranging for iOS 13+", identifier: "stbeaconMonitoring")
        } else {
            locationManager.startRangingBeacons(in: beaconRegion)
//            backgroundCheckNotification(contents: "Started beacon ranging for iOS 13-",identifier: "stbeaconMonitoring")
        }
    }
    
    private func startBluetoothScanningService() {
        print("Bluetooth service started")
        let service = BluetoothScanningService()
        service.startService()
        self.bluetoothService = service
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        locationManager.startUpdatingLocation()
        //showAlert()
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        //showAlert()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("New location: \(location)")
//        backgroundCheckNotification(contents: "Updated location: \(location)", identifier: "locationMonitoring")
        bluetoothService?.startService()
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        scheduleTerminationNotification()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func requestNotificationAuthorization(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func scheduleTerminationNotification() {
        let content = UNMutableNotificationContent()
        content.title = "App Terminated"
        content.body = "Telematics app has been terminated."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "terminationNotification",
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling termination notification: \(error)")
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
    
    private func fetchData(completion: @escaping (Bool) -> Void) {
        // Simulate network fetch
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let newDataFetched = true // Change based on your data fetching logic
            completion(newDataFetched)
        }
    }
    
    func showAlert() {
        if let rootViewController = window?.rootViewController {
            let alert = UIAlertController(title: "Important", message: "Please keep the app running in the background to ensure continuous Bluetooth connectivity.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started monitoring region: \(region.identifier)")
        locationManager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        if state == .inside {
            if #available(iOS 13.0, *) {
                let beaconRegionConstraint = CLBeaconIdentityConstraint(uuid: uuid ?? UUID(), major: 0, minor: 0)
                locationManager.startRangingBeacons(satisfying: beaconRegionConstraint)
//                backgroundCheckNotification(contents: "Started beacon ranging for iOS 13+",identifier: "beaconMonitoring")
            } else {
                locationManager.startRangingBeacons(in: beaconRegion)
//                backgroundCheckNotification(contents: "Started beacon ranging for iOS 13-",identifier: "beaconMonitoring")
            }
        } else {
            locationManager.stopRangingBeacons(in: beaconRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for beacon in beacons {
            let proximity: String
            switch beacon.proximity {
            case .immediate:
                proximity = "Immediate"
            case .near:
                proximity = "Near"
            case .far:
                proximity = "Far"
            case .unknown:
                proximity = "Unknown"
            @unknown default:
                proximity = "Unknown"
            }
            if #available(iOS 13.0, *) {
                backgroundCheckNotification(contents: "Beacon with UUID \(beacon.uuid.uuidString) is \(proximity) and has RSSI \(beacon.rssi)", identifier: "beaconMonitoring")
            } else {
                backgroundCheckNotification(contents: "Beacon with UUID \(beacon.proximityUUID.uuidString) is \(beacon.proximity) and has RSSI \(beacon.rssi)", identifier: "beaconMonitoring")
            }
            
            // Construct the beacon data dictionary
            let beaconData: [String: Any] = [
                "mac": "c3000021be42", // MAC address is not available via CoreLocation
                "name": "", // Name is not available via CoreLocation
                "battery": 100, // Battery info is not available via CoreLocation
                "rssi": beacon.rssi,
                "lastUpdate": formatDate(), // Use current time for last update
                "frames": [] // Add any additional frame information here
            ]
            // Convert beacon data to JSON and write to file
            if let jsonData = try? JSONSerialization.data(withJSONObject: beaconData, options: []) {
                bluetoothService?.updateBeaconData(uuid: uuid?.uuidString ?? "", major: 0, minor:0,rssi: beacon.rssi)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    backgroundCheckNotification(contents: "Beacon data JSON string: \(jsonString)", identifier: "json")
                }
            }
        }
    }
    
    func formatDate()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        return formattedDate;
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region: \(String(describing: region?.identifier)), error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        backgroundCheckNotification(contents: "Entered region: \(region.identifier)",identifier: "beaconMonitoring")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        backgroundCheckNotification(contents: "Exited region: \(region.identifier)",identifier: "beaconMonitoring")
    }
}
