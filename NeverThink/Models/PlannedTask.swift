//
//  PlannedTask.swift
//  NeverThink
//

import Foundation

struct PlannedTask: Codable, Identifiable {
    var id = UUID()
    let start_time: String
    let end_time: String
    let title: String
    let notes: String?
    let reason: String?
    
    private enum CodingKeys: String, CodingKey {
        case start_time, end_time, title, notes, reason
    }
}




