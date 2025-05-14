//
//  LocationService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/3/25.
//

import Foundation
import CoreLocation

// Class that manages live user location updates
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService() // Shared instance for global access

    private let geocoder = CLGeocoder()
    private let manager = CLLocationManager()

    @Published var currentAddress: String?         // readable address
    @Published var currentLocation: CLLocation?   // latitude/longitude

    // Private initializer
    private override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    // Called when new location updates are available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let howRecent = -location.timestamp.timeIntervalSinceNow
        let accuracy = location.horizontalAccuracy

        // Ignore stale or low-accuracy data
        guard howRecent < 10, accuracy >= 0, accuracy < 100 else {
            print("⚠️ Ignored stale or inaccurate location (\(howRecent)s ago, \(accuracy)m)")
            return
        }

        // Accept and store valid location
        currentLocation = location
        print("📍 Accepted location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Reverse geocode to get readable address
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let street = placemark.name ?? ""
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                self.currentAddress = "\(street), \(city), \(state)"
                print("📍 Accurate Address: \(self.currentAddress ?? "none")")
            }
        }
    }
}
