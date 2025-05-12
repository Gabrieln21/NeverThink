//
//  PlannerService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import Foundation
import CoreLocation

private struct PromptTask: Codable {
    let id: String
    let title: String
    var duration: Int
    let urgency: String
    let timeSensitivityType: String
    let start_time: String
    let end_time: String
    let location: String
    let reason: String
}



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

        let userStartAddress = AuthenticationManager.shared.homeAddress


        let home = AuthenticationManager.shared.homeAddress

        // 🧠 Build travel hints
        let cleanedTasks = tasks.filter {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.duration > 0
        }
        print("🧠 Cleaned Tasks to be sent to GPT:")
        cleanedTasks.forEach { print("• \($0.title) (\($0.duration) min)") }

        let promptTasks: [PromptTask] = cleanedTasks.map { task in
            var startTime = "TBD"
            var endTime = "TBD"

            if task.timeSensitivityType == .startsAt, let exact = task.exactTime {
                startTime = DateFormatter.formatTimeString(exact)
                endTime = DateFormatter.formatTimeString(exact.addingTimeInterval(TimeInterval(task.duration * 60)))
            } else if task.timeSensitivityType == .busyFromTo,
                      let start = task.timeRangeStart,
                      let end = task.timeRangeEnd {
                startTime = DateFormatter.formatTimeString(start)
                endTime = DateFormatter.formatTimeString(end)
            }

            return PromptTask(
                id: task.id.uuidString, // <-- Ensure `id` goes into the prompt
                title: task.title,
                duration: task.duration,
                urgency: task.urgency.rawValue,
                timeSensitivityType: task.timeSensitivityType.rawValue,
                start_time: startTime,
                end_time: endTime,
                location: task.location ?? "N/A",
                reason: "TBD"
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let formattedTasksData = try encoder.encode(promptTasks)
        let formattedTasksJSON = String(data: formattedTasksData, encoding: .utf8)!


        guard !cleanedTasks.isEmpty else {
            throw NSError(
                domain: "PlannerService",
                code: 11,
                userInfo: [NSLocalizedDescriptionKey: "No valid tasks to plan."]
            )
        }

        print("🧠 STARTING TRAVEL MATRIX BUILD...")
        
        let travelHints = try await buildTravelMatrix(fromAddress: userStartAddress, tasks: cleanedTasks, home: home, mode: transportMode)

        print("✅ FINISHED TRAVEL MATRIX")
        // 🧠 Decide whether to suppress the initial travel block if very short
        let firstTask = cleanedTasks.first(where: { $0.isLocationSensitive && ($0.location?.isEmpty == false) })
        var skipInitialTravel = false

        if let firstTaskLocation = firstTask?.location {
            do {
                let travelToFirst = try await TravelService.shared.fetchTravelTime(
                    from: userStartAddress,
                    to: firstTaskLocation,
                    mode: transportMode,
                    arrivalTime: Date().addingTimeInterval(3600)
                )

                if travelToFirst.durationMinutes < 8 {
                    print("✅ Travel duration is short enough — skipping initial travel block.")
                    skipInitialTravel = true
                }
            } catch {
                print("⚠️ Could not evaluate initial travel duration: \(error.localizedDescription)")
            }
        }



        
        
        let failures = travelHints.components(separatedBy: "\n").filter { $0.contains("Failed to fetch") }
        if failures.count > 4 {
            print("❌ Travel Fetch Failures:\n" + failures.joined(separator: "\n"))
            throw NSError(domain: "PlannerService", code: 99, userInfo: [
                NSLocalizedDescriptionKey: "Too many travel fetches failed. Please check your internet or location addresses."
            ])
        }


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
        - User’s starting location: "\(userStartAddress)"
        - Home address: "\(homeAddress)" — tasks labeled "Home" happen here.
        - Transportation method: **\(transportMode)**
        - Current time: \(currentTime) (for context only — do NOT use this as the start time)
        - You will learn the exact planning date from the tasks at the end. This plan is for that day — **not today**.

        🧠 Your Core Responsibilities:

        1. **Keep Original Task Data Intact**
           - You must **preserve all fields exactly as provided** from the original task list, except:
             - You are allowed to change **`"start_time"` and `"end_time"`** only:
               - For tasks without a fixed time
               - Or for `"timeSensitivityType": "dueBy"`
           - Do **not** change:
             - `"title"`, `"duration"`, `"urgency"`, `"location"`, `"timeSensitivityType"`
           - Travel blocks may be inserted but must include **all required fields**, even if guessed:
             - Use `"urgency": "Low"` and `"timeSensitivityType": "startsAt"` by default.

        2. **Schedule All Tasks Intelligently**
           - Fixed-time tasks must be respected:
             - `startsAt`: Start exactly at the given time.
             - `dueBy`: Finish well before the given time.
             - `busyFromTo`: Fit fully within the window.
           - Use urgency, buffer logic, and energy pacing to position other tasks.
           - Insert **10–20 minutes of buffer** before important tasks.
           - Do **not** overlap tasks.
           - Never insert "TBD" — always give a valid time.

        3. **Insert Travel Blocks Logically**
           - Always insert travel blocks when locations change.
           - Travel duration must come from the travel matrix below.
           - If the **first task’s location** is different from the user’s current location, you **must** insert a travel block **before it** using the travel matrix.
           - If you decide a the user should say go home between tasks, you must inset a travel block home and **INSERT ANOTHER TRAVEL BLOCK TO THE NEXT TASK**
           - You also **MUST insert a travel block** returning the user home after the last task
           - This travel block must be the **first item** in the list.
           - Do **not** assume the user is already at the task location.
           - Label this block clearly, e.g. `"title": "Travel to [First Task Title]"`, with `"reason": "Starting location is different from first task"`.
           - Return home and leaving again? Insert **two** travel blocks.

        ‼️ DO NOT insert the final travel block home.
        - The system will insert the return-home travel block separately in Swift after your response.
        - You only need to handle travel **between** tasks.

        



        4. **Avoid Over-Buffering**
           - Keep the day efficient — avoid idle gaps over 40 minutes unless necessary.

        ⚠️ Output Requirements:
        -Every task must also include the "id" field, which is preserved from the original list of tasks.
        - Output must be a **valid JSON array** of task objects.
        - NEVER include trailing commas inside objects or arrays — output must be valid JSON.
        - Do **not** include markdown, comments, formatting, or explanations.
        - **Every task, including travel blocks, must include**:
          - `"start_time"` and `"end_time"` (HH:MM AM/PM)
          - `"location"`
          - `"reason"` — even for travel or idle time
          - `"urgency"`
          - `"timeSensitivityType"`

        ⚠️ ID Field Requirement:
        - Every task in your response MUST include the original `"id"` exactly as provided.
        - Do NOT change or regenerate `"id"`s.
        - If you omit or alter the `"id"` on any task, it will be treated as INVALID.
        - Travel blocks do not have IDS


        ---

        🚦 Travel Time Data:
        You are provided with durations between tasks using Google Maps. Each looks like:

        From [Source Task] → [Destination Task] = [X] min (Depart at: [Time])

        - Use **only** the `[X] min` duration
        - Ignore the "Depart at" time
        - Match by full address or task title
        ‼️ If a travel block is required but no travel data is found:

            Insert it anyway with "duration": 10 and "reason": "Missing travel info"

            NEVER use "duration": 0 — this will be ignored and break the plan

        ---

        🧠 Use this data to make intelligent scheduling decisions:
        - Fixed-time tasks are indicated using `exactTime` or `timeRangeStart`/`timeRangeEnd`
        - You may adjust only `start_time` and `end_time` for flexible or due-by tasks
        - DO NOT include any of the following fields in your final JSON output:
          - `exactTime`, `timeRangeStart`, `timeRangeEnd`, `category`, `isLocationSensitive`
        - Your output must only include the following fields per task:
          - `"title"`, `"duration"`, `"urgency"`, `"timeSensitivityType"`, `"start_time"`, `"end_time"`, `"location"`, `"reason"`

        🧠 Use this data to:
        -Respect fixed times (like "startsAt" at 9:30 AM)
        -Accurately calculate task durations
        -Place tasks logically throughout the day
        -Never alter "startsAt" or "busyFromTo" times
        
        📝 Tasks:
        \(formattedTasksJSON)
        
        ‼️ INCLUDE EVERY SINGLE ONE OF THESE TASKS IN YOUR RESPONSE, NOT DOING SO WOULD BE FAILURE
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
        
        Your final response must be a pure JSON array of task objects, starting with `[` and ending with `]`. 
        Do NOT include extra characters, markdown, or text outside the array.

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
        #if DEBUG
        print("🧠 FINAL GPT PROMPT:\n\(prompt)")
        #endif

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

        let parsedTasks = try Self.parseSchedule(from: content, selectedDate: date, originalTasks: cleanedTasks)
        var adjustedTasks = parsedTasks

        if skipInitialTravel,
           let first = adjustedTasks.first,
           first.title.lowercased().starts(with: "travel to"),
           let reason = first.reason?.lowercased(),
           reason.contains("starting location") {
            
            print("🧹 Removing first travel block because it's under 8 minutes.")
            adjustedTasks.removeFirst()
        }


        // ✅ Inject travel blocks
        let withTravel = Self.insertMissingTravelBlocks(from: adjustedTasks, using: travelHints)


        // ✅ Reposition DueBy tasks if needed
        let finalTasks = Self.repositionDueByTasks(withTravel)


        // 🔍 Validate travel logic
        let travelWarnings = validateTravelSequence(tasks: adjustedTasks)
        
        let uniqueTasks = Dictionary(grouping: finalTasks, by: { $0.id })
            .compactMap { $0.value.first }

        #if DEBUG
        print("🗓 Final Scheduled Tasks:")
        for task in uniqueTasks {
            print("- \(task.title): \(task.start_time) – \(task.end_time)")
        }
        #endif

        let sortedTasks = uniqueTasks.sorted {
            guard let time1 = DateFormatter.parseTimeString($0.start_time),
                  let time2 = DateFormatter.parseTimeString($1.start_time) else {
                return false
            }
            return time1 < time2
        }
        if !travelWarnings.isEmpty {
            print("🚨 Travel Logic Issues Found:")
            travelWarnings.forEach { print($0) }
        }

        return sortedTasks
    }

    

    private static func parseSchedule(from response: String, selectedDate: Date, originalTasks: [UserTask]) throws -> [PlannedTask] {

        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove GPT formatting
        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback safety net for malformed but recoverable output
        if !cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") {
            if let fixed = "[\(cleanedResponse)]".replacingOccurrences(of: "}\n,", with: "},").data(using: .utf8),
               let decoded = try? JSONDecoder().decode([PlannedTask].self, from: fixed) {
                return decoded
            }
        }

        // Locate JSON array
        guard let start = cleanedResponse.firstIndex(of: "["),
              let end = cleanedResponse.lastIndex(of: "]") else {
            throw NSError(domain: "PlannerService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "No JSON array found in GPT response:\n\(response)"
            ])
        }

        var jsonString = String(cleanedResponse[start...end])

        // ✅ Fix: Remove all trailing commas in objects and arrays
        while jsonString.contains(",\n]") || jsonString.contains(",\n}") {
            jsonString = jsonString.replacingOccurrences(of: ",\n]", with: "\n]")
            jsonString = jsonString.replacingOccurrences(of: ",\n}", with: "\n}")
        }

        let data = Data(jsonString.utf8)

        do {
            var rawTasks = try JSONDecoder().decode([PlannedTask].self, from: data)

            for i in 0..<rawTasks.count {
                var task = rawTasks[i]

                // 🚨 Ensure ID is present before trying to match
                guard !task.id.isEmpty else {
                    print("🚨 Missing task ID on task: \(task.title)")
                    continue
                }

                // 🔒 Enforce fixed times for `startsAt` tasks
                if task.timeSensitivityType == .startsAt {
                    if let original = originalTasks.first(where: { $0.id.uuidString == task.id }),
                       let expected = original.exactTime {
                        let fixedStart = DateFormatter.formatTimeString(expected)
                        let fixedEnd = DateFormatter.formatTimeString(expected.addingTimeInterval(TimeInterval(original.duration * 60)))
                        task.start_time = fixedStart
                        task.end_time = fixedEnd
                        task.duration = original.duration
                    } else {
                        print("⚠️ Could not find original for startsAt task with id \(task.id)")
                    }
                }

                task.date = Calendar.current.startOfDay(for: selectedDate)

                guard let start = DateFormatter.parseTimeString(task.start_time),
                      let end = DateFormatter.parseTimeString(task.end_time),
                      end > start else {
                    print("⚠️ Skipping task with invalid or missing times: \(task.title)")
                    continue
                }

                task.duration = Int(end.timeIntervalSince(start) / 60)

                let midnight = Calendar.current.startOfDay(for: selectedDate.addingTimeInterval(86400))
                if end >= midnight {
                    print("⚠️ Task \(task.title) ends after midnight. Trimming to 11:59 PM.")
                    let safeEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: selectedDate)!
                    task.end_time = DateFormatter.formatTimeString(safeEnd)
                    task.duration = Int(safeEnd.timeIntervalSince(start) / 60)
                }

                rawTasks[i] = task
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

        var updatedTasks = tasks
        let bufferThreshold: TimeInterval = 10 * 60 // 10 minutes

        for i in 0..<updatedTasks.count {
            let task = updatedTasks[i]

            // Only reposition dueBy tasks
            guard task.timeSensitivityType == .dueBy,
                  let start = DateFormatter.parseTimeString(task.start_time),
                  let end = DateFormatter.parseTimeString(task.end_time) else {
                continue
            }

            let originalDuration = TimeInterval(task.duration * 60)

            // Check if there's less than 10 min before the deadline
            if end.timeIntervalSince(start) < originalDuration + bufferThreshold {
                print("⚠️ Task \"\(task.title)\" is too close to its deadline. Trying to move earlier...")

                // Try to move it earlier by searching backwards
                var earliestAvailableStart = start

                for j in stride(from: i - 1, through: 0, by: -1) {
                    let prev = updatedTasks[j]
                    guard let prevEnd = DateFormatter.parseTimeString(prev.end_time) else { break }
                    let gap = earliestAvailableStart.timeIntervalSince(prevEnd)

                    if gap >= originalDuration + bufferThreshold {
                        // Found enough room
                        let newStart = prevEnd.addingTimeInterval(bufferThreshold)
                        let newEnd = newStart.addingTimeInterval(originalDuration)
                        updatedTasks[i].start_time = DateFormatter.formatTimeString(newStart)
                        updatedTasks[i].end_time = DateFormatter.formatTimeString(newEnd)
                        print("✅ Moved \"\(task.title)\" earlier to \(updatedTasks[i].start_time) – \(updatedTasks[i].end_time)")
                        break
                    }

                    earliestAvailableStart = prevEnd
                }
            }
        }

        return updatedTasks
    }

    private static func extractMinutes(from line: String) -> Int? {
        let pattern = #"= (\d+) min"#
        if let match = line.range(of: pattern, options: .regularExpression) {
            let numberString = line[match].replacingOccurrences(of: "= ", with: "").replacingOccurrences(of: " min", with: "")
            return Int(numberString)
        }
        return nil
    }


    static func insertMissingTravelBlocks(from tasks: [PlannedTask], using travelData: String) -> [PlannedTask] {
        var result: [PlannedTask] = []
        var previous: PlannedTask? = nil

        func travelDuration(from: String, to: String) -> Int? {
            let allLines = travelData.components(separatedBy: "\n")

            // Try direct match
            if let line = allLines.first(where: { $0.contains("From \(from) → \(to) =") }) {
                return extractMinutes(from: line)
            }

            // Try flexible match: ignore case, spaces, and punctuation
            let fromNorm = PlannerService.normalize(from)
            let toNorm = PlannerService.normalize(to)

            for line in allLines {
                let lineNorm = PlannerService.normalize(line)
                if lineNorm.contains("from\(fromNorm)") && lineNorm.contains("to\(toNorm)") {
                    return extractMinutes(from: line)
                }
            }


            return nil
        }

        for task in tasks {
            let isTravel = task.title.lowercased().starts(with: "travel")

            if isTravel {
                // ✅ Don't insert travel to travel, and don’t re-add
                result.append(task)
                previous = task
                continue
            }

            if let prev = previous,
               let prevLoc = prev.location,
               let currLoc = task.location,
               prevLoc != currLoc {

                // ✅ Check if previous is already a travel block
                let prevIsTravel = prev.title.lowercased().starts(with: "travel")
                if !prevIsTravel {
                    // 🧠 Avoid duplicate travel blocks
                    let duration = travelDuration(from: prev.title, to: task.title) ?? 10

                    let travel = PlannedTask(
                        id: UUID().uuidString,
                        start_time: prev.end_time,
                        end_time: DateFormatter.timeStringByAddingMinutes(to: prev.end_time, minutes: duration),
                        title: "Travel to \(task.title)",
                        notes: "Auto-generated travel block",
                        reason: "Location change from \(prev.title) to \(task.title)",
                        date: task.date,
                        urgency: .low,
                        timeSensitivityType: .startsAt,
                        location: task.location
                    )
                    result.append(travel)
                }
            }

            result.append(task)
            previous = task
        }


        // ✅ Insert final travel block back home if needed
        if let last = result.last,
           let lastLocation = last.location {
            
            let normalizedLast = PlannerService.normalize(lastLocation)
            let normalizedHome = PlannerService.normalize(AuthenticationManager.shared.homeAddress)

            if normalizedLast != normalizedHome {
                let homeAddress = AuthenticationManager.shared.homeAddress
                let duration: Int = {
                    // Try to find exact line: [Last Task Title] → Home
                    let allLines = travelData.components(separatedBy: "\n")
                    if let line = allLines.first(where: { entry in
                        entry.lowercased().contains("\(PlannerService.normalize(last.title)) → home".lowercased())
                    }) {
                        return extractMinutes(from: line) ?? 10
                    }
                    return 10
                }()

                let travelBack = PlannedTask(
                    id: UUID().uuidString,
                    start_time: last.end_time,
                    end_time: DateFormatter.timeStringByAddingMinutes(to: last.end_time, minutes: duration),
                    title: "Travel to Home",
                    notes: "Auto-inserted final return trip",
                    reason: "Returning home after final task",
                    date: last.date,
                    urgency: .low,
                    timeSensitivityType: .startsAt,
                    location: homeAddress
                )
                result.append(travelBack)
            }
        }

        return result
    }
    private static func normalize(_ str: String) -> String {
        return str.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }

}




import Foundation
import CoreLocation

extension PlannerService {
    func buildTravelMatrix(
        fromAddress originAddress: String,
        tasks: [UserTask],
        home: String,
        mode: String
    ) async throws -> String {
        let originString = originAddress
        let arrivalTime = Date().addingTimeInterval(3600)
        var matrixEntries: [String] = []
        var travelTimeCache = [String: TravelInfo]()

        func cacheKey(_ from: String?, _ to: String?) -> String {
            let normalize: (String?) -> String = {
                ($0 ?? "").lowercased()
                    .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            }
            return "\(normalize(from))_to_\(normalize(to))"
        }


        func clean(_ s: String?) -> String? {
            guard let trimmed = s?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !["", "n/a", "anywhere", "none"].contains(trimmed.lowercased()) else { return nil }
            return trimmed
        }

        let homeClean = clean(home)
        let validTasks = tasks.filter { $0.isLocationSensitive && clean($0.location) != nil }

        try await withThrowingTaskGroup(of: String?.self) { group in
            for task in validTasks {
                guard let taskAddress = clean(task.location) else { continue }

                // From origin address → task address
                group.addTask {
                    let from = originString
                    let to = taskAddress
                    let key = cacheKey(clean(from), clean(to))
                    if let cached = travelTimeCache[key] {
                        return "From \(from) → \(task.title) [\(to)] = \(cached.durationMinutes) min (Depart at: \(cached.departureTime))"
                    }
                    do {
                        let info = try await TravelService.shared.fetchTravelTime(from: from, to: to, mode: mode, arrivalTime: arrivalTime)
                        travelTimeCache[key] = info
                        return "From \(from) → \(task.title) [\(to)] = \(info.durationMinutes) min (Depart at: \(info.departureTime))"
                    } catch {
                        return "⚠️ Failed: \(from) → \(task.title): \(error.localizedDescription)"
                    }
                }

                // Task → Home
                if let toHome = homeClean {
                    group.addTask {
                        let from = taskAddress
                        let to = toHome
                        let key = cacheKey(clean(from), clean(to))
                        print("🔍 Looking up travelTimeCache with key: \(key)")
                        if let cached = travelTimeCache[key] {
                            return "\(task.title) → Home [\(to)] = \(cached.durationMinutes) min (Depart at: \(cached.departureTime))"
                        }

                        do {
                            let info = try await TravelService.shared.fetchTravelTime(from: from, to: to, mode: mode, arrivalTime: arrivalTime)
                            travelTimeCache[key] = info
                            return "\(task.title) → Home [\(to)] = \(info.durationMinutes) min (Depart at: \(info.departureTime))"
                        } catch {
                            return "⚠️ Failed: \(task.title) → Home: \(error.localizedDescription)"
                        }
                    }

                    // Home → Task
                    group.addTask {
                        let from = toHome
                        let to = taskAddress
                        let key = cacheKey(clean(from), clean(to))
                        if let cached = travelTimeCache[key] {
                            return "From Home → \(task.title) [\(to)] = \(cached.durationMinutes) min (Depart at: \(cached.departureTime))"
                        }
                        do {
                            let info = try await TravelService.shared.fetchTravelTime(from: from, to: to, mode: mode, arrivalTime: arrivalTime)
                            travelTimeCache[key] = info
                            return "From Home → \(task.title) [\(to)] = \(info.durationMinutes) min (Depart at: \(info.departureTime))"
                        } catch {
                            return "⚠️ Failed: Home → \(task.title): \(error.localizedDescription)"
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



    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let street = placemark.thoroughfare ?? ""
                let number = placemark.subThoroughfare ?? ""
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                return "\(number) \(street), \(city), \(state)".trimmingCharacters(in: .whitespaces)
            }
        } catch {
            print("🔴 Reverse geocoding failed: \(error.localizedDescription)")
        }
        return "Unknown Location"
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
