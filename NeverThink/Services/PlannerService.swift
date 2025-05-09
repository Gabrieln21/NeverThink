//
//  PlannerService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import Foundation
import CoreLocation

class PlannerService: NSObject, CLLocationManagerDelegate {
    static let shared = PlannerService()

    private var apiKey: String?
    private var locationManager: CLLocationManager?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var currentLocation: CLLocationCoordinate2D?

    private override init() {
        super.init()
    }

    func configure(apiKey: String) {
        self.apiKey = apiKey
    }

    func requestLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        locationManager?.stopUpdatingLocation()

        locationContinuation?.resume(returning: location.coordinate)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        if let currentLocation = currentLocation {
            return currentLocation
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            requestLocation()

            //timeout fallback!
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.locationContinuation != nil {
                    continuation.resume(throwing: NSError(domain: "PlannerService", code: 99, userInfo: [
                        NSLocalizedDescriptionKey: "Location request timed out. Please enable location access."
                    ]))
                    self.locationContinuation = nil
                }
            }
        }
    }


    func generatePlan(from tasks: [UserTask], for date: Date, transportMode: String) async throws -> [PlannedTask] {
        guard let apiKey = apiKey else {
            throw NSError(domain: "PlannerService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])
        }

        // grab the location
        let userLocation = try await getCurrentLocation()

        let formattedTasks = tasks.map { task in
            var result = """
            Title: \(task.title)
            Duration: \(task.duration) minutes
            Urgency: \(task.urgency.rawValue)
            Time Sensitivity: \(task.isTimeSensitive ? "Yes" : "No")
            Time Sensitivity Type: \(task.isTimeSensitive ? task.timeSensitivityType.rawValue : "N/A")
            """

            if task.timeSensitivityType == .dueBy, let time = task.exactTime {
                result += "\nDue By: \(DateFormatter.localizedString(from: time, dateStyle: .none, timeStyle: .short))"
            }

            if task.timeSensitivityType == .startsAt, let time = task.exactTime {
                result += "\nStarts At: \(DateFormatter.localizedString(from: time, dateStyle: .none, timeStyle: .short))"
            }

            if task.timeSensitivityType == .busyFromTo,
               let start = task.timeRangeStart,
               let end = task.timeRangeEnd {
                result += "\nBusy From: \(DateFormatter.localizedString(from: start, dateStyle: .none, timeStyle: .short)) to \(DateFormatter.localizedString(from: end, dateStyle: .none, timeStyle: .short))"
            }


            result += """
            
            Location Sensitive: \(task.isLocationSensitive ? "Yes" : "No")
            Location: \(task.isLocationSensitive ? (task.location ?? "N/A") : "N/A")
            Category: \(task.category.rawValue)
            """

            return result
        }.joined(separator: "\n\n")

        let dateString = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)

        let currentTime = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)

        let homeAddress = AuthenticationManager.shared.homeAddress.isEmpty ? "Not Set" : AuthenticationManager.shared.homeAddress

        let prompt = """
        You are an intelligent personal assistant helping a real person plan their day on \(dateString).

        - Their **starting location** is approximately Latitude: \(userLocation.latitude), Longitude: \(userLocation.longitude).
        - Their **home address** is "\(homeAddress)" — tasks labeled "Home" happen here.
        - Their method of transportation is **\(transportMode)**.
        - The current time is **\(currentTime)**.

        You are given a list of tasks with these attributes:
        - Duration
        - Urgency level
        - Time sensitivity (due-by, starts-at, or busy range)
        - Location sensitivity:
          - "Home" ➔ Happens at home address.
          - "Anywhere" ➔ Can be completed wherever the user currently is, unless the task naturally implies a move (e.g., gym workout).
          - Specific Address ➔ Requires traveling to that location.

        ---

        🎯 **Your Mission**: 
        Design a fully human-like, efficient daily schedule, accounting for **travel, task timing, duration, and realistic energy pacing**.

        ---

        🧠 **Non-Negotiable Time Rules**:

        - **Starts-At Tasks**:
          - Must begin **EXACTLY** at their specified start time.
          - **NO** early starts or late starts allowed.
          - Insert travel **before** if needed to guarantee arrival on time.

        - **Due-By Tasks**:
          - Must be **COMPLETED before** the due-by time.
          - Plan enough time to finish without rushing.

        - **Busy From-To Tasks**:
          - Must **fully fit within** their available time window (start and end).
          - No scheduling outside of this window.

        - **Duration Integrity**:
          - Every task's full duration must fit inside its assigned block. No unrealistic squeezing or cutting short unless absolutely necessary (and you must explain it).

        ---

        🚕 **Realistic Travel Scheduling**:

        - Travel between physical locations must be **its own scheduled task**.
        - Travel times must be realistic, assuming:
          - Walking ≈ 3 mph
          - Driving ≈ 35–45 mph (urban)
          - Public Transit: reasonable waits (normal city conditions)
        - ⚡ **Never double or overinflate travel times**. Estimate moderately, not worst-case.
        - Allow enough buffer to **arrive on time without rushing**.

        ---

        🕒 **Time Format**:

        - Always use **12-hour AM/PM** format (e.g., "08:45 AM", "3:15 PM").

        ---

        📈 **Energy and Flow Management**:

        - Insert **Free Time** blocks when there is an open gap of **≥30 minutes** between tasks.
          - Title: `"Free Time"`
          - Notes: Encourage rest, personal errands, recharge, or reflection.
          - Reason: Maintain healthy energy pacing throughout the day.

        ---

        ⚡ **Conflict Handling**:

        - **Always prioritize** urgent and time-sensitive tasks.
        - Drop, delay, or shorten low-priority leisure tasks as needed — **clearly explain why** in the "reason" field.

        ---

        ✅ **Output Format**:

        Return ONLY a raw JSON array like:

        [
          {
            "start_time": "08:00 AM",
            "end_time": "08:15 AM",
            "title": "Travel to Dentist",
            "notes": "15 min drive to 123 Main St.",
            "reason": "Leaving early to ensure punctual arrival for 8:30 AM appointment."
          },
          {
            "start_time": "08:30 AM",
            "end_time": "09:00 AM",
            "title": "Dentist Appointment",
            "notes": "Location: 123 Main St. Urgency: High.",
            "reason": "Important health-related appointment prioritized early."
          }
        ]

        🚫 No markdown, no explanations, no headings. Only the JSON array.

        ---

        Tasks:
        \(formattedTasks)
        """






        // Setup API call
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = jsonObject?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "PlannerService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing expected fields in GPT response"])
        }

        print("🧠 RAW GPT RESPONSE:\n\(content)")

        return try Self.parseSchedule(from: content)
    }

    private static func parseSchedule(from response: String) throws -> [PlannedTask] {
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
            cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let start = cleanedResponse.firstIndex(of: "["),
              let end = cleanedResponse.lastIndex(of: "]") else {
            throw NSError(domain: "PlannerService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "No JSON array found in GPT response:\n\(response)"
            ])
        }

        let jsonString = String(cleanedResponse[start...end])
        let data = Data(jsonString.utf8)

        do {
            return try JSONDecoder().decode([PlannedTask].self, from: data)
        } catch {
            throw NSError(domain: "PlannerService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode JSON: \(error.localizedDescription)\nJSON String: \(jsonString)"
            ])
        }
    }
}
