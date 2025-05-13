//
//  LocationService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/3/25.
//
import Foundation
import CoreLocation

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let geocoder = CLGeocoder()
    private let manager = CLLocationManager()

    @Published var currentAddress: String?
    @Published var currentLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let howRecent = -location.timestamp.timeIntervalSinceNow
        let accuracy = location.horizontalAccuracy

        guard howRecent < 10, accuracy >= 0, accuracy < 100 else {
            print("⚠️ Ignored stale or inaccurate location (\(howRecent)s ago, \(accuracy)m)")
            return
        }

        currentLocation = location
        print("📍 Accepted location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

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
