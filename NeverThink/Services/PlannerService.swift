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

        let prompt = """
        You are an intelligent personal assistant helping a real person plan their entire day on \(dateString).
        Their **starting location** is approximately Latitude: \(userLocation.latitude), Longitude: \(userLocation.longitude).
        They are traveling by **\(transportMode)**. The current time is **\(currentTime)**.

        You are given a list of tasks with varying:
        - Durations
        - Urgency levels
        - Time constraints (due-by, start time, time ranges)
        - Location sensitivity

        🧠 Your job: Build a **fully detailed, realistic daily schedule** that includes:
        ✅ All tasks
        ✅ All required **travel time between tasks**
        ✅ An initial **travel event from the user's current location to the first task**

        ---

        You must:
        - Begin by determining which task should come first based on urgency, location, and timing.
        - **Insert a travel event from the user's current location to the first task.**
          - This event should have a clear start time, end time, and explain why it’s needed.
          - Ensure they leave early enough from their current location to arrive on time.
        - Insert additional **travel events between tasks at different locations**.
        - Estimate travel time using:
          - Walk: ~3 mph
          - Drive: 25–40 mph (urban)
          - Public Transit: include wait time and buffer
        - Honor all time-sensitive constraints (exact times and ranges).
        - Spread out tasks to avoid burnout (no nonstop overload).
        - Prioritize higher urgency tasks. Lower priority tasks may be **shortened, delayed, or skipped** if needed.
        - Use your best judgment when conflicts arise — act like a proactive, thoughtful assistant.

        ---

        🚗 **TRAVEL EVENTS must:**
        - Be titled: "Travel to [Task Title or Location]"
        - Include:
          - Estimated travel duration
          - Clear start_time and end_time
          - Notes field: travel details
          - Reason field: why it was scheduled when it was

        🕒 Time format: **12-hour AM/PM** only — e.g., "08:45 AM", "1:15 PM".

        ---

        ⚠️ Conflicts? Handle smartly:
        - If two tasks conflict, prioritize based on urgency and constraints.
        - Clearly state in the "reason" field why something was delayed, shortened, or omitted.

        ---

        ✅ Final output format: A **raw JSON array** like this:

        [
          {
            "start_time": "08:30 AM",
            "end_time": "09:00 AM",
            "title": "Travel to Dentist",
            "notes": "Estimated 30 min drive from current location. Leaving early to arrive on time.",
            "reason": "First task of the day. Leaving early from current location to reach dentist by 9:00 AM."
          },
          {
            "start_time": "09:00 AM",
            "end_time": "09:30 AM",
            "title": "Dentist Appointment",
            "notes": "Location: 123 Main St. Urgency: High. Category: Be Somewhere.",
            "reason": "Scheduled early to prioritize health and minimize morning traffic."
          }
        ]

        ---

        🚫 Do NOT include intros, markdown, explanations, or any non-JSON text.

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
