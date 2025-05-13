import Foundation
import CoreLocation

struct TravelInfo: Decodable {
    let durationMinutes: Int
    let departureTime: String
}

class TravelService {
    static let shared = TravelService()
    private let apiKey = "AIzaSyCB_pXJjASuszZqOkVws8SbL9QlNRYMlug"
    
    // Caching to prevent duplicate requests
    private var travelTimeCache = [String: TravelInfo]()
    
    private func cacheKey(from: String, to: String) -> String {
        return "\(from.lowercased())_TO_\(to.lowercased())"
    }

    func fetchTravelTime(
        from originAddress: String,
        to destinationAddress: String,
        mode: String,
        arrivalTime: Date
    ) async throws -> TravelInfo {

        let key = cacheKey(from: originAddress, to: destinationAddress)

        if let cached = travelTimeCache[key] {
            print("🧠 Using cached route \(originAddress) → \(destinationAddress)")
            return cached
        }

        let arrivalEpoch = Int(arrivalTime.timeIntervalSince1970)
        let encodedOrigin = originAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedDestination = destinationAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = """
        https://maps.googleapis.com/maps/api/directions/json?origin=\(encodedOrigin)&destination=\(encodedDestination)&mode=\(mode)&arrival_time=\(arrivalEpoch)&key=\(apiKey)
        """

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        print("🌍 Requesting travel time:\n\(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            print("❌ Google Maps API returned HTTP status code \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "TravelService", code: 99, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode Google Maps response"
            ])
        }

        let status = json["status"] as? String ?? "Unknown"
        if status != "OK" {
            print("🛑 Google Maps API status: \(status)")
            print("🔎 Response:\n\(String(data: data, encoding: .utf8) ?? "nil")")
            throw NSError(domain: "TravelService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid Google Maps response (status: \(status))"
            ])
        }

        guard
            let routes = json["routes"] as? [[String: Any]],
            let firstRoute = routes.first,
            let legs = firstRoute["legs"] as? [[String: Any]],
            let firstLeg = legs.first,
            let duration = firstLeg["duration"] as? [String: Any],
            let durationValue = duration["value"] as? Int
        else {
            print("⚠️ Malformed Google Maps response for \(originAddress) → \(destinationAddress)")
            print("🔎 Raw JSON:\n\(String(data: data, encoding: .utf8) ?? "nil")")
            throw NSError(domain: "TravelService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Missing or invalid travel info in Google Maps response"
            ])
        }

        let departureText = (firstLeg["departure_time"] as? [String: Any])?["text"] as? String ?? "N/A"

        let travelInfo = TravelInfo(
            durationMinutes: durationValue / 60,
            departureTime: departureText
        )

        travelTimeCache[key] = travelInfo
        print("✅ Travel time from \(originAddress) → \(destinationAddress): \(travelInfo.durationMinutes) min")

        return travelInfo
    }
    func fetchTravelTime(
        from origin: CLLocationCoordinate2D,
        to destinationAddress: String,
        mode: String,
        arrivalTime: Date
    ) async throws -> TravelInfo {
        let originString = "\(origin.latitude),\(origin.longitude)"
        return try await fetchTravelTime(
            from: originString,
            to: destinationAddress,
            mode: mode,
            arrivalTime: arrivalTime
        )
    }

}
