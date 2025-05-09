//
//  RecurringTask.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//
import Foundation

enum RecurringInterval: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { self.rawValue }
}

struct RecurringTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var duration: Int // minutes
    var isTimeSensitive: Bool
    var timeSensitivityType: TimeSensitivity
    var exactTime: Date?
    var timeRangeStart: Date?
    var timeRangeEnd: Date?
    var urgency: UrgencyLevel
    var location: String?
    var category: TaskCategory
    var recurringInterval: RecurringInterval
}


