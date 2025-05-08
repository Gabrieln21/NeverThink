//
//  UserTask.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
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
}



enum UrgencyLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum TaskCategory: String, CaseIterable, Codable {
    case doAnywhere = "Do Anywhere"
    case beSomewhere = "Be Somewhere"
}

