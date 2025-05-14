//
//  TravelEstimator.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//
import Foundation
import CoreLocation

// utility for fetching estimated travel time between two addresses using Google Maps Directions API.
struct TravelEstimator {
    //static let apiKey = "AIzaSyA0hNSzHtuScFiYRwyVAp6aUt_NAF8C8T4"
    // Fetches estimated travel time in seconds from Google Maps Directions API.
    static func fetchTravelTime(from origin: String, to destination: String, mode: String, arrivalTime: Date? = nil) async throws -> TimeInterval {
        guard !TravelService.shared.apiKey.isEmpty else {
            throw NSError(domain: "TravelEstimator", code: 99, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])
        }
        // Construct URL
        var urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=\(mode)&key=\(TravelService.shared.apiKey)"
        
        // Append arrival time
        if let arrivalTime = arrivalTime {
            let timestamp = Int(arrivalTime.timeIntervalSince1970)
            urlString += "&arrival_time=\(timestamp)"
        }
        // encode the full URL string
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            throw NSError(domain: "TravelEstimator", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Fetch data from Google Maps API
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Parse JSON and extract travel duration value
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let routes = json["routes"] as? [[String: Any]],
              let leg = routes.first?["legs"] as? [[String: Any]],
              let duration = leg.first?["duration"] as? [String: Any],
              let seconds = duration["value"] as? TimeInterval else {
            throw NSError(domain: "TravelEstimator", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Google Maps API"])
        }

        return seconds // Travel time in seconds
    }
}
