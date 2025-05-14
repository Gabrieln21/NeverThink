//
//  PlannedTask.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//

import Foundation

// Represents a scheduled task or event in the user's day.
// Used by AI-generated plans
struct PlannedTask: Codable, Identifiable {
    var id: String = UUID().uuidString                      // Unique identifier
    var start_time: String                                  // Start time ("hh:mm a")
    var end_time: String                                    // End time ("hh:mm a")
    var title: String                                       // Task name or title
    var notes: String?                                      // additional info or metadata
    var reason: String?                                     // Why the task is scheduled
    var date: Date = Calendar.current.startOfDay(for: Date()) // The calendar day this task belongs to
    var isCompleted: Bool = false                           // Whether the user marked the task as done
    var duration: Int                                       // Task length in minutes
    var urgency: UrgencyLevel                               // How urgent the task is (low/medium/high)
    var timeSensitivityType: TimeSensitivity = .startsAt    // Determines time flexibility
    var location: String?                                   // Location where the task takes place

    // Defines how strictly the task must occur at a certain time
    enum TimeSensitivity: String, Codable, CaseIterable {
        case none          // Flexible
        case dueBy         // Must be completed before a deadline
        case startsAt      // Must start at a specific time
        case busyFromTo    // Must happen within a range
    }

    private enum CodingKeys: String, CodingKey {
        case id, start_time, end_time, title, notes, reason, date, isCompleted, duration, urgency, timeSensitivityType, location
    }

    // initializer, calculates duration based on start/end time strings
    init(
        id: String = UUID().uuidString,
        start_time: String,
        end_time: String,
        title: String,
        notes: String? = nil,
        reason: String? = nil,
        date: Date = Calendar.current.startOfDay(for: Date()),
        urgency: UrgencyLevel = .medium,
        timeSensitivityType: TimeSensitivity = .startsAt,
        location: String? = nil
    ) {
        self.id = id
        self.start_time = start_time
        self.end_time = end_time
        self.title = title
        self.notes = notes
        self.reason = reason
        self.date = date
        self.isCompleted = false
        self.duration = PlannedTask.calculateDuration(from: start_time, to: end_time)
        self.urgency = urgency
        self.timeSensitivityType = timeSensitivityType
        self.location = location
    }

    // Custom decoder that handles missing or older fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        start_time = try container.decode(String.self, forKey: .start_time)
        end_time = try container.decode(String.self, forKey: .end_time)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Calendar.current.startOfDay(for: Date())
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        urgency = try container.decodeIfPresent(UrgencyLevel.self, forKey: .urgency) ?? .medium
        timeSensitivityType = try container.decodeIfPresent(TimeSensitivity.self, forKey: .timeSensitivityType) ?? .startsAt

        if let providedDuration = try container.decodeIfPresent(Int.self, forKey: .duration) {
            duration = providedDuration
        } else {
            duration = PlannedTask.calculateDuration(from: start_time, to: end_time)
        }
    }

    // Calculates the duration in minutes between two time strings
    static func calculateDuration(from start: String, to end: String) -> Int {
        guard
            let startDate = DateFormatter.parseTimeString(start),
            let endDate = DateFormatter.parseTimeString(end)
        else {
            return 0
        }

        let diff = Calendar.current.dateComponents([.minute], from: startDate, to: endDate)
        return max(diff.minute ?? 0, 0)
    }
}
