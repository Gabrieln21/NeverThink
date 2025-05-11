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

    private(set) var apiKey: String?
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
        print("📍 Current user location: \(currentLocation)")
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


    func generatePlan(from tasks: [UserTask], for date: Date, transportMode: String, extraNotes: String = "") async throws -> [PlannedTask] {
        guard let apiKey = apiKey else {
            throw NSError(domain: "PlannerService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])
        }

        let userLocation = try await getCurrentLocation()
        let home = AuthenticationManager.shared.homeAddress

        // Build travel hints
        let cleanedTasks = tasks.filter {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.duration > 0
        }

        guard !cleanedTasks.isEmpty else {
            throw NSError(
                domain: "PlannerService",
                code: 11,
                userInfo: [NSLocalizedDescriptionKey: "No valid tasks to plan."]
            )
        }

        print("🧠 STARTING TRAVEL MATRIX BUILD...")
        let travelHints = try await buildTravelMatrix(
            from: userLocation,
            tasks: cleanedTasks,
            home: home,
            mode: transportMode
        )
        print("✅ FINISHED TRAVEL MATRIX")


        
        
        let failures = travelHints.components(separatedBy: "\n").filter { $0.contains("Failed to fetch") }
        if failures.count > 4 {
            print("❌ Travel Fetch Failures:\n" + failures.joined(separator: "\n"))
            throw NSError(domain: "PlannerService", code: 99, userInfo: [
                NSLocalizedDescriptionKey: "Too many travel fetches failed. Please check your internet or location addresses."
            ])
        }



        let formattedTasks = cleanedTasks.map { task -> String in
            let calendar = Calendar.current
            var assumedStartTime: Date?

            if task.isTimeSensitive {
                switch task.timeSensitivityType {
                case .startsAt:
                    assumedStartTime = task.exactTime
                case .dueBy:
                    if let dueTime = task.exactTime {
                        assumedStartTime = calendar.date(byAdding: .minute, value: -(task.duration), to: dueTime)
                    }
                case .busyFromTo:
                    assumedStartTime = task.timeRangeStart
                case .none:
                    break
                }
            }

            var result = """
            Title: \(task.title)
            Duration: \(task.duration) minutes
            Urgency: \(task.urgency.rawValue)
            Time Sensitivity: \(task.isTimeSensitive ? "Yes" : "No")
            Time Sensitivity Type: \(task.isTimeSensitive ? task.timeSensitivityType.rawValue : "N/A")
            """

            if let assumedStartTime = assumedStartTime {
                result += "\nAssumed Start Time: \(DateFormatter.localizedString(from: assumedStartTime, dateStyle: .none, timeStyle: .short))"
            }
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

        let extraNotesSection = extraNotes.isEmpty ? "" : """

        ---
        📝 **User Additional Notes / Problems with previous AI plan:**
        \(extraNotes)
        """

        let prompt = """
        You are an intelligent personal assistant planning times for tasks strategically for a real person's day.

        📍 Context:
        - User’s starting location: Latitude \(userLocation.latitude), Longitude \(userLocation.longitude)
        - Home address: "\(homeAddress)" — tasks labeled "Home" happen here.
        - Transportation method: **\(transportMode)**
        - Current time: \(currentTime) (for context only — do NOT use this as the start time)
        - You will learn the exact planning date from the tasks at the end. This plan is for that day — **not today**.

        🧠 Your Four Core Jobs:

        1. **Schedule All Tasks Intelligently**
           - Fixed-time tasks must be respected exactly as provided:
             - `startsAt`: Must begin at the designated time.
             - `dueBy`: Must be completed **well before** the due time, not at the last possible moment.
             - `busyFromTo`: Must fully fit inside the specified time window.
           - Unscheduled tasks must be placed using advanced logic, urgency, and appropriate spacing.
           - Every task must include:
             - `"start_time"` and `"end_time"` in `HH:MM AM/PM` format
             - `"location"`, `"reason"`, `"urgency"`, `"timeSensitivityType"`
           - Do NOT overlap tasks.
           - Insert **10 to 20 minutes of buffer** before tasks unless a longer one is clearly justified.
           - Do NOT insert "TBD" — if no time is given, place it logically based on the schedule and importance.

        2. **Include First Travel Block**
           - You **must insert a travel block from the user’s current location to the first task** if it’s at a different location.
           - This travel duration must come directly from the provided travel matrix data.
           - Do NOT assume the user is already at the first location.

        3. **Handle Round-Trip Travel Accurately**
           - Anytime the user returns home and then goes back out, insert **both** travel blocks:
             - To home
             - And then **back to the next task**
           - Travel must be inserted between any two tasks at different locations — no teleportation.

        4. **Avoid Over-Buffering**
           - Do not add more than 20 minutes of early arrival buffer unless explicitly required.
           - Long idle time (e.g., over 40 min) should only occur for valid reasons (like free time or dinner breaks).
           - Keep the plan tight and efficient while respecting energy pacing.

        ⚠️ Output Requirements:
        - You must return ONLY a **valid JSON array** of tasks.
        - No markdown, comments, headings, or “TBD” values are allowed.
        - Every task must be complete, logical, and non-overlapping.
        - All fixed-time durations must be fully respected — do not shorten classes or assignments.
        - Travel time must be precise and sourced directly from the list below.

        ---

        🚦 Travel Time Data:
        You are provided with durations between tasks using Google Maps. Each looks like:

        From [Source Task] → [Destination Task] = [X] min (Depart at: [Time])

        - Use ONLY the `[X] min` duration — **ignore the departure time**
        - Match by full address or task title
        - Do NOT invent or estimate travel time — if it’s missing, explain in `"reason"` and skip

        ---

        📦 Task Data Format:

        You will receive a variable called `formattedTasks`. This is a **JSON array of objects**, where each object represents a task. Every task includes structured fields such as:

        ```json
        {
          "title": "HCI Class",
          "duration": 75,
          "urgency": "High",
          "timeSensitivityType": "startsAt",
          "exactTime": "09:30 AM",
          "location": "1600 Holloway Avenue, San Francisco, CA 94132"
        }

        🧠 Use this data to:
        -Respect fixed times (like "startsAt" at 9:30 AM)
        -Accurately calculate task durations
        -Place tasks logically throughout the day
        -Never alter "startsAt" or "busyFromTo" times
        
        📝 Tasks:
        \(formattedTasks)

        ---
        🚦 Travel Durations Format:

        You will receive a variable called travelHints. This is a plain-text list with travel durations between tasks, like:

        From Home → HCI Class = 20 min (Depart at: 8:30 AM) From Databases Class → Cute been date!!! = 70 min (Depart at: 6:45 PM)

        🧠 Use this data to:
        
        -Calculate travel time blocks
        -Insert them as their own tasks with "start_time", "end_time", "reason", and "location"
        -Ignore the “Depart at” — just use the number of minutes

        If you place two tasks in different locations back-to-back, you must insert a travel block in between using the matching duration from this list.
        
        🛣️ Travel Durations:
        \(travelHints)

        ---

        🧾 Extra Notes:
        \(extraNotesSection)
        """


        // Setup API call
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard !travelHints.contains("Failed to fetch") else {
            throw NSError(domain: "PlannerService", code: 99, userInfo: [
                NSLocalizedDescriptionKey: "Unable to generate travel matrix."
            ])
        }


        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let raw = String(data: data, encoding: .utf8) ?? "No body"
            throw NSError(domain: "PlannerService", code: 401, userInfo: [NSLocalizedDescriptionKey: "GPT API failed. Status: \((response as? HTTPURLResponse)?.statusCode ?? -1). Body: \(raw)"])
        }

        print("🧠 RAW GPT JSON: \(String(data: data, encoding: .utf8) ?? "nil")")



        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "PlannerService", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON in GPT response"])
        }

        if let error = jsonObject["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw NSError(domain: "OpenAI", code: 101, userInfo: [NSLocalizedDescriptionKey: "OpenAI Error: \(message)"])
        }

        guard let choices = jsonObject["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("🔴 GPT response missing expected fields: \(jsonObject)")
            throw NSError(domain: "PlannerService", code: 102, userInfo: [NSLocalizedDescriptionKey: "Missing expected fields in GPT response"])
        }


        print("🧠 RAW GPT RESPONSE:\n\(content)")

        let parsedTasks = try Self.parseSchedule(from: content, selectedDate: date)

        // Inject travel blocks
        let withTravel = Self.insertMissingTravelBlocks(from: parsedTasks, using: travelHints)

        // Reposition DueBy tasks if needed
        let adjustedTasks = Self.repositionDueByTasks(withTravel)

        // Validate travel logic
        let travelWarnings = validateTravelSequence(tasks: adjustedTasks)

        return adjustedTasks

        if !travelWarnings.isEmpty {
            print("🚨 Travel Logic Issues Found:")
            travelWarnings.forEach { print($0) }
        }

        return parsedTasks
    }

    

    private static func parseSchedule(from response: String, selectedDate: Date) throws -> [PlannedTask] {
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
            var rawTasks = try JSONDecoder().decode([PlannedTask].self, from: data)

            for i in 0..<rawTasks.count {
                let task = rawTasks[i]
                
                guard let start = DateFormatter.parseTimeString(task.start_time),
                      let end = DateFormatter.parseTimeString(task.end_time),
                      end > start else {
                    print("⚠️ Skipping task with invalid or missing times: \(task.title)")
                    continue
                }

                // INSERT VALIDATION BLOCK
                if task.timeSensitivityType == .startsAt,
                   let expected = DateFormatter.parseTimeString(task.start_time),
                   abs(start.timeIntervalSince(expected)) > 60 {
                    print("⚠️ Task startsAt time mismatch: \(task.title)")
                }

                if task.timeSensitivityType == .dueBy,
                   let due = DateFormatter.parseTimeString(task.end_time),
                   end >= due {
                    print("❌ Task \(task.title) ends after due time!")
                }

                let duration = Int(end.timeIntervalSince(start) / 60)
                rawTasks[i].duration = max(duration, 0)
                rawTasks[i].date = Calendar.current.startOfDay(for: selectedDate)
            }


            return rawTasks

        } catch {
            throw NSError(domain: "PlannerService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode JSON: \(error.localizedDescription)\nJSON String: \(jsonString)"
            ])
        }
    }
    func validateTravelSequence(tasks: [PlannedTask]) -> [String] {
        var warnings = [String]()
        var lastLocation: String? = nil

        for i in 0..<tasks.count {
            let current = tasks[i]
            let isTravel = current.title.lowercased().contains("travel")
            let isNewLocation = current.location != lastLocation && !isTravel

            if isNewLocation {
                if i == 0 || !(tasks[i - 1].title.lowercased().contains("travel")) {
                    warnings.append("⚠️ Missing travel to \(current.title) at index \(i)")
                }
            }
            if !isTravel {
                lastLocation = current.location
            }
        }

        return warnings
    }
    static func repositionDueByTasks(_ tasks: [PlannedTask]) -> [PlannedTask] {
        print("🔁 Repositioning dueBy tasks if they are too close to deadlines...")
        
        // TODO logic to reposition tasks
        return tasks
    }

    static func insertMissingTravelBlocks(from tasks: [PlannedTask], using travelData: String) -> [PlannedTask] {
        var result: [PlannedTask] = []
        var previous: PlannedTask? = nil

        func travelDuration(from: String, to: String) -> Int? {
            let needle = "From \(from) → \(to) = "
            guard let line = travelData.components(separatedBy: "\n").first(where: { $0.contains(needle) }) else {
                return nil
            }
            if let minutes = line.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first,
               let duration = Int(minutes) {
                return duration
            }
            return nil
        }

        for task in tasks {
            if let prev = previous,
               let prevLoc = prev.location,
               let currLoc = task.location,
               prevLoc != currLoc,
               let duration = travelDuration(from: prev.title, to: task.title) {

                let travelTask = PlannedTask(
                    id: UUID().uuidString,
                    start_time: prev.end_time,
                    end_time: DateFormatter.timeStringByAddingMinutes(to: prev.end_time, minutes: duration),
                    title: "Travel to \(task.title)",
                    notes: "Auto-inserted travel block",
                    reason: "Inserted travel from \(prev.title) to \(task.title).",
                    date: prev.date,
                    urgency: .low,
                    timeSensitivityType: .startsAt,
                    location: task.location ?? "Unknown"
                )

                result.append(travelTask)
            }

            result.append(task)
            previous = task
        }

        return result
    }


}

import Foundation
import CoreLocation

extension PlannerService {
    func buildTravelMatrix(
        from origin: CLLocationCoordinate2D,
        tasks: [UserTask],
        home: String,
        mode: String
    ) async throws -> String {
        let originString = "\(origin.latitude),\(origin.longitude)"
        let arrivalTime = Date().addingTimeInterval(3600)
        var matrixEntries: [String] = []
        var travelTimeCache = [String: TravelInfo]()

        func cacheKey(_ from: String, _ to: String) -> String {
            "\(from.lowercased())_TO_\(to.lowercased())"
        }

        func clean(_ s: String?) -> String? {
            guard let trimmed = s?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !["", "n/a", "anywhere", "none"].contains(trimmed.lowercased()) else { return nil }
            return trimmed
        }

        let validTasks = tasks.filter { $0.isLocationSensitive && clean($0.location) != nil }

        try await withThrowingTaskGroup(of: String?.self) { group in
            for task in validTasks {
                guard let to = clean(task.location) else { continue }

                group.addTask {
                    let from = originString
                    let key = cacheKey(from, to)
                    if let cached = travelTimeCache[key] {
                        return "From Current Location → \(task.title) [\(to)] = \(cached.durationMinutes) min (Depart at: \(cached.departureTime))"
                    }

                    do {
                        let info = try await TravelService.shared.fetchTravelTime(from: from, to: to, mode: mode, arrivalTime: arrivalTime)
                        travelTimeCache[key] = info
                        return "From Current Location → \(task.title) [\(to)] = \(info.durationMinutes) min (Depart at: \(info.departureTime))"
                    } catch {
                        return "⚠️ Failed: Current Location → \(task.title): \(error.localizedDescription)"
                    }
                }

                if let homeClean = clean(home) {
                    group.addTask {
                        let from = to
                        let toHome = homeClean
                        let key = cacheKey(from, toHome)
                        if let cached = travelTimeCache[key] {
                            return "\(task.title) → Home [\(toHome)] = \(cached.durationMinutes) min (Depart at: \(cached.departureTime))"
                        }

                        do {
                            let info = try await TravelService.shared.fetchTravelTime(from: from, to: toHome, mode: mode, arrivalTime: arrivalTime)
                            travelTimeCache[key] = info
                            return "\(task.title) → Home [\(toHome)] = \(info.durationMinutes) min (Depart at: \(info.departureTime))"
                        } catch {
                            return "⚠️ Failed: \(task.title) → Home: \(error.localizedDescription)"
                        }
                    }
                }
            }

            for try await result in group {
                if let entry = result {
                    matrixEntries.append(entry)
                }
            }
        }

        return matrixEntries.joined(separator: "\n")
    }
}
extension DateFormatter {
    static func timeStringByAddingMinutes(to timeString: String, minutes: Int) -> String {
        guard let date = parseTimeString(timeString) else { return timeString }
        let newDate = date.addingTimeInterval(TimeInterval(minutes * 60))
        return formatTimeString(newDate)
    }

    static func formatTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}
