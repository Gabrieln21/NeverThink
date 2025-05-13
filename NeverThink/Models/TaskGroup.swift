//
//  TaskGroup.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//

import Foundation

struct TaskGroup: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var name: String
    var tasks: [UserTask]
}
