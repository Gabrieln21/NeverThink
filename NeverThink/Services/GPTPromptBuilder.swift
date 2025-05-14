//
//  GPTPromptBuilder.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//

import Foundation

// Utility for building a GPT prompt from a list of tasks and constraints
struct GPTPromptBuilder {
    // Builds a english and JSON prompt to send to GPT for rescheduling tasks.
    static func buildPrompt(
        tasks: [UserTask],
        deadlines: [UUID: Date],
        scheduledEvents: [UserTask],
        from startDate: Date,
        to endDate: Date,
        wakeTime: Date,
        sleepTime: Date
    ) -> String {
        
        let isoFormatter = ISO8601DateFormatter()
        
        // Format user tasks into dictionaries with deadline if available
        let taskList: [[String: Any]] = tasks.map { task in
            var dict: [String: Any] = [
                "id": task.id.uuidString,
                "title": task.title,
                "duration": task.duration,
                "urgency": task.urgency.rawValue
            ]
            if let deadline = deadlines[task.id] {
                dict["deadline"] = isoFormatter.string(from: deadline)
            }
            return dict
        }

        // Format already scheduled events for context
        let eventList: [[String: String]] = scheduledEvents.compactMap { event in
            guard let time = event.exactTime else { return nil }
            return [
                "title": event.title,
                "time": isoFormatter.string(from: time)
            ]
        }
        
        let wake = isoFormatter.string(from: wakeTime)
        let sleep = isoFormatter.string(from: sleepTime)
        
        // Create final prompt with scheduling rules and serialized data
        var prompt = "Today is \(isoFormatter.string(from: startDate)).\n"
        prompt += """
        
    IMPORTANT:
    - Do NOT schedule anything **before \(wake)** or **after \(sleep)** — these are the user’s sleep hours and are off-limits.
    - If two tasks conflict in time, always preserve the more important one (higher urgency), and reschedule the other.
    - Never remove or move both tasks.
    """

        prompt += "\nSchedule the following tasks before \(isoFormatter.string(from: endDate)).\n"
        prompt += "Here are the tasks:\n\(taskList)\n"
        prompt += "Here are already scheduled events for context only (DO NOT include them in your response):\n\(eventList)\n"
        prompt += """

    Respond with a JSON array of updated tasks like:
    [
      {
        "id": "same-id-as-above",
        "title": "Task title",
        "exactTime": "2025-05-02T14:00:00Z",
        "duration": 30,
        "urgency": "Medium"
      },
      ...
    ]
    """
        return prompt
    }
}
