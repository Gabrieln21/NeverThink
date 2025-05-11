//
//  GPTPromptBuilder.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//

import Foundation

struct GPTPromptBuilder {
    
    static func buildPrompt(
        tasks: [UserTask],
        deadlines: [UUID: Date],
        scheduledEvents: [UserTask],
        from startDate: Date,
        to endDate: Date
    ) -> String {
        
        let isoFormatter = ISO8601DateFormatter()
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

        let eventList: [[String: String]] = scheduledEvents.compactMap { event in
            guard let time = event.exactTime else { return nil }
            return [
                "title": event.title,
                "time": isoFormatter.string(from: time)
            ]
        }

        var prompt = "Today is \(isoFormatter.string(from: startDate)).\n"
        prompt += "Schedule the following tasks before \(isoFormatter.string(from: endDate)).\n"
        prompt += "Here are the tasks:\n\(taskList)\n"
        prompt += "Here are already scheduled events:\n\(eventList)\n"
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
