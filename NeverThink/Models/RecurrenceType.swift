//
//  RecurrenceType.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//

import Foundation

// Represents how often a recurring task repeats.
enum RecurrenceType: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { self.rawValue }
}
