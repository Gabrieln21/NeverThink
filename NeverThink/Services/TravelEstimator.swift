import Foundation
import CoreLocation

struct TravelEstimator {
    static let apiKey = "GOOGLE_MAPS_API_KEY"

    static func fetchTravelTime(from origin: String, to destination: String, mode: String, arrivalTime: Date? = nil) async throws -> TimeInterval {
        var urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=\(mode)&key=AIzaSyCB_pXJjASuszZqOkVws8SbL9QlNRYMlug"
        
        if let arrivalTime = arrivalTime {
            let timestamp = Int(arrivalTime.timeIntervalSince1970)
            urlString += "&arrival_time=\(timestamp)"
        }

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            throw NSError(domain: "TravelEstimator", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)

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
