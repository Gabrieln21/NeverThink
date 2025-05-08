//
//  TaskManager.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import Foundation
import SwiftUI

class TaskManager: ObservableObject {
    @Published var tasks: [UserTask] = []
    
    func addTask(_ task: UserTask) {
        tasks.append(task)
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}
