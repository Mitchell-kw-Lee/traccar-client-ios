//
// Copyright 2015 - 2017 Anton Tananaev (anton.tananaev@gmail.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import CoreLocation

protocol PositionProviderDelegate: class {
    func didUpdate(position: Position)
}

class PositionProvider: NSObject, CLLocationManagerDelegate {

    weak var delegate: PositionProviderDelegate?
    
    var locationManager: CLLocationManager
    var lastLocation: CLLocation?

    var deviceId: String
    var interval: Double
    var distance: Double
    var angle: Double
    var auth: String
    var isForceFrequency: Bool
    
    override init() {
        let userDefaults = UserDefaults.standard
        deviceId = userDefaults.string(forKey: "device_id_preference")!
        interval = userDefaults.double(forKey: "frequency_preference")
        distance = userDefaults.double(forKey: "distance_preference")
        angle = userDefaults.double(forKey: "angle_preference")
        auth = userDefaults.string(forKey: "auth_preference")!
        isForceFrequency = userDefaults.bool(forKey: "force_frequency_preference")

        locationManager = CLLocationManager()

        super.init()

        locationManager.delegate = self

        locationManager.pausesLocationUpdatesAutomatically = false

        switch userDefaults.string(forKey: "accuracy_preference") ?? "medium" {
        case "high":
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case "low":
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        default:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
        
		locationManager.distanceFilter = isForceFrequency ? 0 : distance  // In meters.

        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
    }

    func startUpdates() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .restricted, .denied:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func getBatteryLevel() -> Float {
        let device = UIDevice.current
        if device.batteryState != .unknown {
            return device.batteryLevel * 100
        } else {
            return 0
        }
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

        if let location = locations.last {
            var diffDistance: Double = lastLocation != nil ? DistanceCalculator.distance(fromLat: location.coordinate.latitude, fromLon: location.coordinate.longitude, toLat: lastLocation!.coordinate.latitude, toLon: lastLocation!.coordinate.longitude) : 0;
            var diffBearing: Double = lastLocation != nil ? fabs(location.course - lastLocation!.course) : 0;
            
            if lastLocation == nil 
                //|| location.timestamp.timeIntervalSince(lastLocation!.timestamp) >= interval
                //|| (distance > 0 && DistanceCalculator.distance(fromLat: location.coordinate.latitude, fromLon: location.coordinate.longitude, toLat: lastLocation!.coordinate.latitude, toLon: lastLocation!.coordinate.longitude) >= distance)
                //|| (angle > 0 && fabs(location.course - lastLocation!.course) >= angle) 
                ||
                (
                    location.timestamp.timeIntervalSince(lastLocation!.timestamp) >= interval
                    &&
                        (
                            isForceFrequency
                            ||
                            (
                                    distance > 0 ? diffDistance >= distance : true
                                    ||
                                    angle > 0 ? diffBearing >= angle : true
                            )
                        )
                )                
            {
                let position = Position(managedObjectContext: DatabaseHelper().managedObjectContext)
                position.deviceId = deviceId
                position.setLocation(location)
                position.battery = getBatteryLevel() as NSNumber
                position.auth = auth;

                delegate?.didUpdate(position: position)

                lastLocation = location
            }else{
            	StatusViewController.addMessage(NSLocalizedString("Location ignored", comment: ""))
            }
        }else{
        	//null data
        }
    }
}
