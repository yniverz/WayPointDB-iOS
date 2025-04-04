//
//  LocationHelper.swift
//  WayPointDB iOS
//
//  Created by yniverz on 17.01.25.
//

import Foundation
import CoreLocation
import UserNotifications
import UIKit
import Network

class LocationHelper: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    private let maximumPositionAccuracy: Double = 50 // meters
    private let regionTimeoutRadius: Double = 20 // meters of no movement to enable turn off
    private let positionUpdateTimeout: Double = 60*1 // seconds of no movement until turn off. (foot timeout)
    private let positionUpdateTimeoutInVehicle: Double = 60*5 // seconds of no movement after speed was >= 30 until turn off. (vehicle timeout)
    private let timeoutOutOfVehicle: Double = 60*3 // seconds of slow movement until resets to foot timeout
    private let minDistanceBeforeSave: Double = 15 // meters: less than this, skip location entirely
    
    private var lastMovedThreshhold: Date?
    private var updatesRunning = false
    private var stopUpdates = false
    
    private var writingQueue = DispatchQueue(label: "writingQueue")
    private var sendingQueue = DispatchQueue(label: "sendingQueue")
    private var loopStartQueue = DispatchQueue(label: "loopStartQueue")
    private var networkMonitorQueue = DispatchQueue(label: "networkMonitorQueue")
    
    var isNetworkReachable: Bool = false
    var validStart: Bool = false
    
    //set default values for configuration parameters (overwritten in init block)
    @Published var authorisationStatus: CLAuthorizationStatus = .notDetermined
    
    
    var waypointdbServerHost: String {
        set {
            UserDefaults.standard.set(newValue, forKey: "waypointdbServerHost")
        }
        get {
            UserDefaults.standard.string(forKey: "waypointdbServerHost") ?? ""
        }
    }
    var waypointdbServerKey: String {
        set {
            UserDefaults.standard.set(newValue, forKey: "waypointdbServerKey")
        }
        get {
            UserDefaults.standard.string(forKey: "waypointdbServerKey") ?? ""
        }
    }
    
    var trackingActivated: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "trackingActivated")
            if newValue {
                start()
            } else {
                stop()
            }
        }
        get {
            UserDefaults.standard.bool(forKey: "trackingActivated")
        }
    }
    var alwaysHighDensity: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "alwaysHighDensity")
        }
        get {
            UserDefaults.standard.bool(forKey: "alwaysHighDensity")
        }
    }
    
    var debugNotifications: Bool {
        set {
            if newValue && !debugNotifications {
                sendNotification("Notifications activated.")
            }
            UserDefaults.standard.set(newValue, forKey: "debugNotifications")
        }
        get {
            UserDefaults.standard.bool(forKey: "debugNotifications")
        }
    }
    
    var selectedMaxBufferSize: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedMaxBufferSize")
        }
        get {
            let x = UserDefaults.standard.integer(forKey: "selectedMaxBufferSize")
            if x == 0 {
                return 300
            }
            return x
        }
    }
    
    
    var traceBuffer: [LocationItem] {
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                UserDefaults.standard.set(data, forKey: "traceBuffer")
                print("saved lastLocationItem")
            } catch {
                print("Failed to encode lastLocationItem: \(error)")
            }
        }
        get {
            do {
                if let data = UserDefaults.standard.data(forKey: "traceBuffer") {
                    let decoder = JSONDecoder()
                    return try decoder.decode([LocationItem].self, from: data)
                } else {
                    print("No traceBuffer found in UserDefaults.")
                }
            } catch {
                print("Failed to decode traceBuffer: \(error)")
            }
            
            return []
        }
    }
    
    override
    init() {
        super.init()
        
        //set up CLLocationManager to send us location updates continously (while active)
        self.locationManager.delegate = self
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.distanceFilter = 100
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Internet connection is available.")
                self.isNetworkReachable = true
            } else {
                print("Internet connection is not available.")
                self.isNetworkReachable = false
            }
        }
        monitor.start(queue: networkMonitorQueue)
        
        tryStart()
    }
    
    
    public func tryStart() {
        if trackingActivated {
            self.start()
        }
    }
    
    
    public func start() {
        self.requestAuth()
        
        self.locationManager.startUpdatingLocation()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startMonitoringVisits()
        
        startLoop()
    }
    
    public func startLoop() {
        
        loopStartQueue.async {
            if !self.trackingActivated {
                return
            }
            
            if !self.alwaysHighDensity {
                return
            }
            
            print("Scheduling start live Service")
            
            if !self.updatesRunning {
                self.stopUpdates = false
                self.updatesRunning = true
                
                Task() {
                    self.lastMovedThreshhold = Date()
                    
                    self.sendNotification("Starting Updates")
                    
                    print("Starting live Service")
                    await self.livePositionLoop()
                    
                    self.updatesRunning = false
                    
                    self.sendNotification("Stopping Updates")
                }
            }
        }
    }
    
    public func stop(){
        self.locationManager.stopUpdatingLocation()
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.stopMonitoringVisits()
        self.stopUpdates = true
    }
    
    public func requestAuth() {
        if self.authorisationStatus != .authorizedAlways {
            self.locationManager.requestAlwaysAuthorization()
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification permissions granted!")
            } else if let error {
                print(error.localizedDescription)
            }
        }
    }
    
    func livePositionLoop() async {
        
        do {
            
            let updates = CLLocationUpdate.liveUpdates()
            
            let startTime = Date()
            var inVehicle = false
            var lastFastTime = Date(timeIntervalSince1970: 0)
            
            self.lastMovedThreshhold = nil
            var lastMovedLocation: CLLocation? = nil
            for try await update in updates {
                if self.stopUpdates || !trackingActivated {
                    self.stopUpdates = false
                    break
                }
                
                if let location = update.location {
                    
                    if lastMovedLocation.isNil || self.lastMovedThreshhold.isNil || location.speed * 3.6 >= 10 || location.distance(from: lastMovedLocation!) >= regionTimeoutRadius {
                        lastMovedLocation = location
                        self.lastMovedThreshhold = Date()
                    }
                    
                    print(location)
                        
                    if location.timestamp > self.lastMovedThreshhold!.addingTimeInterval(positionUpdateTimeoutInVehicle) || (location.timestamp > self.lastMovedThreshhold!.addingTimeInterval(positionUpdateTimeout) && !inVehicle) {
                        print("Logged for ", Date().timeIntervalSince(startTime), "Seconds")
                        break
                    }
                    
                    if location.speed * 3.6 >= 30 {
                        lastFastTime = Date()
                    }
                    
                    if !inVehicle && location.speed * 3.6 >= 30 {
                        inVehicle = true
                    } else if inVehicle && location.timestamp > lastFastTime.addingTimeInterval(timeoutOutOfVehicle) && location.speed * 3.6 < 30 && location.speed * 3.6 >= 5 {
                        inVehicle = false
                    }
                    
                    self.locationManager(didUpdateLocation: location)
                }
            }
            
            sendToServer(force: true)
        } catch {
            print("Could not start location updates")
        }
    }
    
}






extension LocationHelper: CLLocationManagerDelegate {
    var lastLocationItem: LocationItem? {
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                UserDefaults.standard.set(data, forKey: "lastLocationItem")
                print("saved lastLocationItem")
            } catch {
                print("Failed to encode lastLocationItem: \(error)")
            }
        }
        get {
            do {
                if let data = UserDefaults.standard.data(forKey: "lastLocationItem") {
                    let decoder = JSONDecoder()
                    return try decoder.decode(LocationItem.self, from: data)
                } else {
                    print("No lastLocationItem found in UserDefaults.")
                }
            } catch {
                print("Failed to decode lastLocationItem: \(error)")
            }
            return nil
        }
    }

    //update auth status whenever it changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorisationStatus = status
    }
    
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !updatesRunning {
            for newLocation in locations {
                self.locationManager(didUpdateLocation: newLocation)
            }
        }
        
        
        startLoop()
    }
    
    private func locationManager(didUpdateLocation location: CLLocation) {
        writingQueue.async {
            if location.horizontalAccuracy > self.maximumPositionAccuracy {
                return
            }
            
            let newItem = self.getLocationItemFromCLLocation(location)
            
            if let lastLocation = self.lastLocationItem {
                if lastLocation.time >= newItem.time || lastLocation.location.distance(from: newItem.location).magnitude < self.minDistanceBeforeSave {
                    return
                }
            }
            
            self.traceBuffer.append(newItem)
            
            self.lastLocationItem = newItem
            
            if self.traceBuffer.count >= self.selectedMaxBufferSize {
                self.sendToServer()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
//        if visit.departureDate != .distantFuture && visit.arrivalDate != .distantPast {
//            writingQueue.async {
//                self.storageManager.addVisitItem(visit)
//            }
//        }
        
        if visit.departureDate == .distantFuture {
            sendToServer(force: true)
            return
        }
        
        sendNotification("You left a Location.")
        
        startLoop()
    }
    
    //if the location manager failed for whatever reason, give up and log to console
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("ERROR - No Location Received")
    }
    
    
    func addVisitItem(_ item: CLVisit) {
        
    }
    
    
    
    func sendNotification(_ message: String, title: String? = nil) {
        if !debugNotifications {
            return
        }
        
        print("sending notification: \(message)")
        let content = UNMutableNotificationContent()
        content.title = "waypointdb"
        if !title.isNil && title!.isEmpty {
            content.title = "waypointdb - " + title!
        }
        content.body = message
        content.sound = UNNotificationSound.default
        
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    
    
    func sendToServer(force: Bool = false) {
        sendingQueue.async {
            if self.traceBuffer.count < self.selectedMaxBufferSize && !force {
                return
            }
            
            if self.traceBuffer.isEmpty {
                return
            }
            
            self._sendToServer()
        }
    }
    
    func _sendToServer() {
        // 1. Check network reachability
        if !isNetworkReachable {
            return
        }
        
        // 2. Validate we have data to send and a valid host
        guard !traceBuffer.isEmpty,
              !waypointdbServerHost.isEmpty,
              let baseURL = URL(string: waypointdbServerHost + "/api/v1/gps/batch?api_key=\(waypointdbServerKey)")
        else {
            print("No data to send or invalid server host.")
            return
        }
        
        let maxDataPoints = 300  // <-- Set your maximum number of items per request here
        
        // 3. Keep sending while traceBuffer is not empty
        while !traceBuffer.isEmpty {
            
            // 3a. Take a chunk (up to maxDataPoints) from the front of traceBuffer
            let chunk = Array(traceBuffer.prefix(maxDataPoints))
            
            // 4. Convert our chunk into the new GpsData format
            var gpsDataArray: [GpsData] = []
            for item in chunk {
                let gpsData = GpsData(
                    timestamp: item.time,
                    latitude: item.lat,
                    longitude: item.lng,
                    horizontal_accuracy: item.horAcc,
                    altitude: item.alt,
                    vertical_accuracy: item.altAcc,
                    heading: item.hdg,
                    heading_accuracy: item.hdgAcc,
                    speed: item.spd,
                    speed_accuracy: item.spdAcc
                )
                gpsDataArray.append(gpsData)
            }
            
            let gpsBatch = GpsBatch(gps_data: gpsDataArray)
            
            // 5. Encode to JSON
            guard let jsonData = try? JSONEncoder().encode(gpsBatch) else {
                print("Error encoding GPS batch data.")
                return
            }
            
            // 6. Create and configure the request
            var request = URLRequest(url: baseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // If your server expects Bearer token or other auth, set it here:
            // request.setValue("Bearer \(waypointdbServerKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData
            
            // 7. Use a semaphore to wait for completion before sending the next chunk
            let sem = DispatchSemaphore(value: 0)
            
            // Keep track of the buffer size before sending
            let bufferCountBeforeSend = traceBuffer.count
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                defer { sem.signal() }
                guard let self = self else { return }
                
                // Handle networking errors
                if let error = error {
                    print("Error sending data to server: \(error.localizedDescription)")
                    // Stop sending if there's an error – no removal from traceBuffer
                    return
                }
                
                // Handle HTTP status codes
                if let httpResponse = response as? HTTPURLResponse {
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("Server responded with status code: \(httpResponse.statusCode)")
                        sendNotification("\(httpResponse)", title: "HTTP Err")
                        // Stop sending if there's a non-success status – no removal
                        return
                    }
                }
                
                // If successful, remove the chunk we just sent from the buffer
                print("Data successfully sent to server. Removing this chunk from the buffer.")
                self.traceBuffer.removeFirst(chunk.count)
            }
            
            task.resume()
            sem.wait()
            
            // If buffer wasn't reduced, break out (means the send failed or didn't remove items)
            if traceBuffer.count == bufferCountBeforeSend {
                break
            }
        }
    }

    
    
    
    func clearBuffer() {
        writingQueue.async {
            self.traceBuffer = []
        }
    }
    
    
    // ##############
    // HELPERS
    // ##############
    
    func getLocationItemFromCLLocation(_ location: CLLocation) -> LocationItem {
        return LocationItem(time: location.timestamp.timeIntervalSince1970.magnitude,
                            lat: location.coordinate.latitude,
                            lng: location.coordinate.longitude,
                            horAcc: location.horizontalAccuracy,
                            alt: location.altitude,
                            altAcc: location.verticalAccuracy,
                            floor: location.floor?.level ?? 0,
                            hdg: location.course,
                            hdgAcc: location.courseAccuracy,
                            spd: location.speed,
                            spdAcc: location.speedAccuracy)
    }
}
