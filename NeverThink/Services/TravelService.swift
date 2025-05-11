//
//  TravelService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/29/25.
//
import Foundation
import CoreLocation

struct TravelInfo: Decodable {
    let durationMinutes: Int
    let departureTime: String
}

class TravelService {
    static let shared = TravelService()
    private let apiKey = "<YOUR_GOOGLE_MAPS_API_KEY>"

    func fetchTravelTime(from origin: CLLocationCoordinate2D,
                         to destinationAddress: String,
                         mode: String,
                         arrivalTime: Date) async throws -> TravelInfo {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let arrivalEpoch = Int(arrivalTime.timeIntervalSince1970)
        
        let urlString = """
        https://maps.googleapis.com/maps/api/directions/json?origin=\(origin.latitude),\(origin.longitude)&destination=\(destinationAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&mode=\(mode)&arrival_time=\(arrivalEpoch)&key=\(apiKey)
        """

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let routes = json?["routes"] as? [[String: Any]],
              let firstLeg = routes.first?["legs"] as? [[String: Any]],
              let leg = firstLeg.first,
              let duration = leg["duration"] as? [String: Any],
              let departureTime = leg["departure_time"] as? [String: Any],
              let durationValue = duration["value"] as? Int,
              let departureText = departureTime["text"] as? String
        else {
            throw NSError(domain: "TravelService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Google Maps response"])
        }

        return TravelInfo(
            durationMinutes: durationValue / 60,
            departureTime: departureText
        )
    }
}

