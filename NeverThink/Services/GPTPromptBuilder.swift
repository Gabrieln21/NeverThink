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
        
        let todayFormatted = DateFormatter.localizedString(from: startDate, dateStyle: .long, timeStyle: .none)
        let lastDeadlineFormatted = DateFormatter.localizedString(from: endDate, dateStyle: .long, timeStyle: .none)

        var prompt = ""
        prompt += "You are a scheduling assistant.\n"
        prompt += "Today is \(todayFormatted).\n"
        prompt += "You must schedule the following tasks before the final deadline: \(lastDeadlineFormatted).\n\n"

        // existing scheduled events
        prompt += "Here are the user's already scheduled events:\n"
        if scheduledEvents.isEmpty {
            prompt += "- None scheduled yet.\n"
        } else {
            for event in scheduledEvents {
                if let time = event.exactTime {
                    let timeFormatted = DateFormatter.localizedString(from: time, dateStyle: .short, timeStyle: .short)
                    prompt += "- [\(timeFormatted)] \(event.title)\n"
                }
            }
        }
        prompt += "\n"

        // Tasks that need scheduling
        prompt += "Here are the tasks that need to be scheduled:\n"
        for task in tasks {
            prompt += "- \(task.title) (\(task.duration) minutes, Urgency: \(task.urgency.rawValue))"
            if let deadline = deadlines[task.id] {
                let deadlineFormatted = DateFormatter.localizedString(from: deadline, dateStyle: .short, timeStyle: .short)
                prompt += " [Hard Deadline: \(deadlineFormatted)]"
            }
            prompt += "\n"
        }

        prompt += "\nInstructions:\n"
        prompt += "- Distribute the tasks across available free time.\n"
        prompt += "- Avoid conflicts with the user's existing scheduled events.\n"
        prompt += "- Prioritize urgent tasks sooner.\n"
        prompt += "- Fit longer tasks into larger gaps.\n"
        prompt += "- Respect the hard deadlines.\n"
        prompt += "- Group similar tasks together when possible.\n"
        prompt += "- Respond with a clear day-by-day plan."
        prompt += "- Format it nicely by date.\n"

        return prompt
    }
}
