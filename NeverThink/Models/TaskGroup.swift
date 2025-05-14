//
//  TaskGroup.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//

import Foundation

// Tasks are grouped into days by default
//  TasksGroups not restricted by days can also be created
struct TaskGroup: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var name: String
    var tasks: [UserTask]
}
