//
//  UserTask.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/25/25.
//

import Foundation

struct UserTask: Identifiable, Codable, Hashable, Equatable {
    var id: UUID = UUID()
    var title: String
    var duration: Int
    var isTimeSensitive: Bool
    var urgency: UrgencyLevel
    var isLocationSensitive: Bool
    var location: String?
    var category: TaskCategory
    var timeSensitivityType: TimeSensitivity
    var exactTime: Date?
    var timeRangeStart: Date?
    var timeRangeEnd: Date?
    var date: Date?
    var parentRecurringId: UUID? = nil
}



enum UrgencyLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

// Urgency Level colors
import SwiftUI

extension UrgencyLevel {
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

enum TaskCategory: String, CaseIterable, Codable {
    case doAnywhere = "Do Anywhere"
    case beSomewhere = "Be Somewhere"
    case general
    case work
    case personal
    case fitness
    case errands
}

