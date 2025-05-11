//
//  TaskExpansionService.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/26/25.
//

import Foundation

class TaskExpansionService {
    static let shared = TaskExpansionService()

    private var apiKey: String? {
        PlannerService.shared.apiKey
    }

    private init() {}
    
    func findRelevantDates(from userInput: String) async throws -> [Date] {
        guard let apiKey = apiKey else {
            throw NSError(domain: "TaskExpansionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])
        }

        let prompt = """
        THE YEAR IS 2025!!! IMPORTANT!!!

        Analyze the following text and identify any **specific dates** mentioned.

        ❗ Output ONLY the dates in the ISO format: "yyyy-MM-dd"
        ❗ If no specific date is mentioned, return an empty JSON array: []

        Example output:
        ["2025-05-01", "2025-05-02"]

        Text:
        \"\"\"
        \(userInput)
        \"\"\"
        """

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4-turbo-preview",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = jsonObject?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "TaskExpansionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing fields in GPT response"])
        }

        print("🧠 RAW DATE EXTRACTION RESPONSE:\n\(content)")

        // Parse the JSON array
        guard let dataContent = content.data(using: .utf8),
              let dateStrings = try? JSONDecoder().decode([String].self, from: dataContent) else {
            throw NSError(domain: "TaskExpansionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode dates from response: \(content)"])
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return dateStrings.compactMap { formatter.date(from: $0) }
    }


    func expandTextToTasks(_ userInput: String, existingSchedule: [Date: [String]] = [:]) async throws -> [UserTask] {
        guard let apiKey = apiKey else {
            throw NSError(domain: "TaskExpansionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])
        }

        let scheduleContext = Self.buildScheduleContext(existingSchedule)


        let prompt = """
        THE YEAR IS 2025!!! - IMPORTANT!!!!!

        You are a smart productivity assistant.

        Given the user's text, intelligently extract a list of actionable tasks.

        Also, keep in mind the user's **existing schedule** provided below when suggesting tasks.

        \(scheduleContext)

        For EACH new task, generate:

        - title (short, human-readable)
        - duration (estimated minutes)
        - urgency ("High", "Medium", "Low")
        - timeSensitivityType ("None", "Due by", "Starts at", "Busy from-to")
        - exactTime (for StartsAt / DueBy tasks) — format "h:mm a"
        - timeRangeStart and timeRangeEnd (for BusyFromTo tasks) — format "h:mm a"
        - location ("Home", "Anywhere", "Gym", etc)
        - category ("Work", "Health", "Errands", "Personal", "Chores")
        - date (optional, if specified — format "yyyy-MM-dd")

        ❗ Always fill in as many fields as possible.
        ❗ Default to "Personal" if category is unclear.
        ❗ Default to "Anywhere" if location unclear.

        Return ONLY a **raw JSON array**, no extra explanations.

        Example output:

        [
          {
            "title": "Prepare Design Presentation",
            "duration": 120,
            "urgency": "High",
            "timeSensitivityType": "Starts at",
            "exactTime": "8:00 AM",
            "timeRangeStart": null,
            "timeRangeEnd": null,
            "location": "Office",
            "category": "Work",
            "date": "2025-05-01"
          },
          {
            "title": "Grocery Shopping",
            "duration": 45,
            "urgency": "Medium",
            "timeSensitivityType": "None",
            "exactTime": null,
            "timeRangeStart": null,
            "timeRangeEnd": null,
            "location": "Supermarket",
            "category": "Errands",
            "date": null
          }
        ]

        ---
        USER TEXT:
        \"\"\"
        \(userInput)
        \"\"\"
        """

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4-turbo-preview",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = jsonObject?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "TaskExpansionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing fields in GPT response"])
        }

        print("🧠 RAW EXPANSION RESPONSE:\n\(content)")

        return try Self.parseExpandedTasks(from: content)
    }

    private static func buildScheduleContext(_ schedule: [Date: [String]]) -> String {
        if schedule.isEmpty {
            return "⚡ USER HAS NO EXISTING TASKS."
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var result = "⚡ EXISTING TASKS BY DAY:\n"

        for (date, tasks) in schedule.sorted(by: { $0.key < $1.key }) {
            let dateString = formatter.string(from: date)
            let tasksList = tasks.map { "- \($0)" }.joined(separator: "\n")
            result += "\n\(dateString):\n\(tasksList)\n"
        }

        return result
    }

    private static func parseExpandedTasks(from response: String) throws -> [UserTask] {
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
            cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let start = cleanedResponse.firstIndex(of: "["),
              let end = cleanedResponse.lastIndex(of: "]") else {
            throw NSError(domain: "TaskExpansionService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "No JSON array found in GPT response:\n\(response)"
            ])
        }

        let jsonString = String(cleanedResponse[start...end])
        let data = Data(jsonString.utf8)

        struct RawTask: Codable {
            let title: String
            let duration: Int
            let urgency: String
            let timeSensitivityType: String
            let exactTime: String?
            let timeRangeStart: String?
            let timeRangeEnd: String?
            let location: String?
            let category: String?
            let date: String?
        }

        let rawTasks = try JSONDecoder().decode([RawTask].self, from: data)

        let mappedTasks = rawTasks.map { raw in
            UserTask(
                id: UUID(),
                title: raw.title,
                duration: raw.duration,
                isTimeSensitive: raw.timeSensitivityType.lowercased() != "none",
                urgency: UrgencyLevel(rawValue: raw.urgency) ?? .medium,
                isLocationSensitive: (raw.location != nil && raw.location?.lowercased() != "anywhere"),
                location: raw.location ?? "Anywhere",
                category: TaskCategory(rawValue: raw.category ?? "Personal") ?? .personal,
                timeSensitivityType: TimeSensitivity(rawValue: raw.timeSensitivityType) ?? .none,
                exactTime: parseTime(raw.exactTime),
                timeRangeStart: parseTime(raw.timeRangeStart),
                timeRangeEnd: parseTime(raw.timeRangeEnd),
                date: parseDate(raw.date),
                parentRecurringId: nil
            )
        }

        return mappedTasks
    }

    private static func parseTime(_ timeString: String?) -> Date? {
        guard let timeString = timeString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.date(from: timeString)
    }

    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
