//
//  TaskGroup.swift
//  NeverThink
//

import Foundation

struct TaskGroup: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var name: String
    var tasks: [UserTask]
}
