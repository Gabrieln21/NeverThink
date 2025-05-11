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
extension TaskGroupManager {
    private var fileURL: URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return path.appendingPathComponent("task_groups.json")
    }

    func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(groups)
            try data.write(to: fileURL)
            print("✅ Task groups saved to disk")
        } catch {
            print("❌ Failed to save task groups: \(error)")
        }
    }

    func loadFromDisk() {
        do {
            let data = try Data(contentsOf: fileURL)
            let loaded = try JSONDecoder().decode([TaskGroup].self, from: data)
            self.groups = loaded
            print("✅ Task groups loaded from disk")
        } catch {
            print("⚠️ No saved task groups or failed to load: \(error)")
        }
    }
}
