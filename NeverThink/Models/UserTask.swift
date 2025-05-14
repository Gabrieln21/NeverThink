//
//  UserTask.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import Foundation
import SwiftUI

// Represents a single task the user wants to complete.
struct UserTask: Identifiable, Codable {
    var id: UUID = UUID()

    var title: String                // Task name or description
    var duration: Int               // Duration in minutes
    var isTimeSensitive: Bool       // Whether it has strict timing rules
    var urgency: UrgencyLevel       // Low, Medium, High
    var isLocationSensitive: Bool   // Whether the task requires being at a specific location
    var location: String?           // Optional location string
    var category: TaskCategory      // Used for organizing/filtering tasks

    var timeSensitivityType: TimeSensitivity   // startsAt, dueBy, busyFromTo
    var exactTime: Date?                       // For fixed-time tasks
    var timeRangeStart: Date?                  // Optional start of time window
    var timeRangeEnd: Date?                    // Optional end of time window

    var date: Date?                 // Optional planning date
    var parentRecurringId: UUID? = nil  // Links back to recurring task, if applicable
    var isCompleted: Bool = false  // Tracks completion state
}

extension UserTask: Equatable, Hashable {
    static func == (lhs: UserTask, rhs: UserTask) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Represents urgency of a task, used for prioritization and UI highlighting.
enum UrgencyLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

extension UrgencyLevel {
    // Maps urgency to a visual color in the UI.
    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// User-defined categories to help organize tasks.
enum TaskCategory: String, CaseIterable, Codable {
    case doAnywhere = "Do Anywhere"
    case beSomewhere = "Be Somewhere"
    case general
    case work
    case personal
    case fitness
    case errands
}
