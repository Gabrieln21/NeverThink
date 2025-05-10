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

    func expandTextToTasks(_ userInput: String) async throws -> [UserTask] {
        guard let apiKey = apiKey else {
            throw NSError(domain: "TaskExpansionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key not configured"])
        }

        let prompt = """
        You are an intelligent productivity assistant.  
        Given a block of text, extract a list of actionable tasks.

        For EACH task, generate:

        - title (short)
        - duration (minutes)
        - urgency: High, Medium, or Low
        - timeSensitivityType: StartsAt, DueBy, BusyFromTo, None
        - exactTime (if any, format hh:mm a)
        - timeRangeStart (if any, format hh:mm a)
        - timeRangeEnd (if any, format hh:mm a)
        - location (optional, like "Home", "Gym", or "Anywhere")
        - category (Work, Health, Errands, Personal, Chores)

        Return ONLY a raw JSON array like:

        [
          {
            "title": "Buy groceries",
            "duration": 45,
            "urgency": "High",
            "timeSensitivityType": "None",
            "exactTime": null,
            "timeRangeStart": null,
            "timeRangeEnd": null,
            "location": "Supermarket",
            "category": "Errands"
          }
        ]

        No extra commentary. Only the raw JSON array.

        ---
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
            "model": "gpt-4-turbo-preview", // now usisng GPT-4 Turbo for smarter plans
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
            throw NSError(domain: "TaskExpansionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing fields in GPT response"])
        }

        print("🧠 RAW EXPANSION RESPONSE:\n\(content)")

        return try Self.parseExpandedTasks(from: content)
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
        }

        let rawTasks = try JSONDecoder().decode([RawTask].self, from: data)

        let mappedTasks = rawTasks.map { raw in
            UserTask(
                id: UUID(),
                title: raw.title,
                duration: raw.duration,
                isTimeSensitive: raw.timeSensitivityType != "None",
                urgency: UrgencyLevel(rawValue: raw.urgency) ?? .medium,
                isLocationSensitive: (raw.location != nil && raw.location != "Anywhere"),
                location: raw.location,
                category: TaskCategory(rawValue: raw.category ?? "Personal") ?? .personal,
                timeSensitivityType: TimeSensitivity(rawValue: raw.timeSensitivityType) ?? .none,
                exactTime: parseTime(raw.exactTime),
                timeRangeStart: parseTime(raw.timeRangeStart),
                timeRangeEnd: parseTime(raw.timeRangeEnd),
                date: nil,
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
}
