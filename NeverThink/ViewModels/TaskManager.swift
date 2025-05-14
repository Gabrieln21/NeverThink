//
//  TaskManager.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import Foundation
import SwiftUI

// A simple manager for storing and modifying individual tasks
class TaskManager: ObservableObject {
    @Published var tasks: [UserTask] = []
    
    func addTask(_ task: UserTask) {
        tasks.append(task)
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}

// Persistent Storage for Task Groups and Conflict Queues
extension TaskGroupManager {
    // File location for all task group data.
    private var fileURL: URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return path.appendingPathComponent("task_groups.json")
    }
    // File location for manually flagged reschedule queue.
    private var manualQueueURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("manual_queue.json")
    }
    
    // File location for auto-detected conflict queue.
    private var autoQueueURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("auto_queue.json")
    }


    func saveToDisk() {
        let encoder = JSONEncoder()
        do {
            let groupData = try encoder.encode(groups)
            try groupData.write(to: fileURL)

            let manualData = try encoder.encode(manualRescheduleQueue)
            try manualData.write(to: manualQueueURL)

            let autoData = try encoder.encode(autoConflictQueue)
            try autoData.write(to: autoQueueURL)

            print("✅ All task data saved to disk")
        } catch {
            print("❌ Failed to save task data: \(error)")
        }
    }


    func loadFromDisk() {
        let decoder = JSONDecoder()
        
        // Load task groups
        if let groupData = try? Data(contentsOf: fileURL),
           let decodedGroups = try? decoder.decode([TaskGroup].self, from: groupData) {
            self.groups = decodedGroups
        }

        // Load manual queue and prevent duplicates
        if let manualData = try? Data(contentsOf: manualQueueURL),
           let decodedManual = try? decoder.decode([UserTask].self, from: manualData) {
            // Avoid duplicates
            let unique = decodedManual.filter { task in
                !self.manualRescheduleQueue.contains(where: { $0.id == task.id })
            }
            self.manualRescheduleQueue.append(contentsOf: unique)
        }

        // Load auto conflict queue and prevent duplicates
        if let autoData = try? Data(contentsOf: autoQueueURL),
           let decodedAuto = try? decoder.decode([UserTask].self, from: autoData) {
            let unique = decodedAuto.filter { task in
                !self.autoConflictQueue.contains(where: { $0.id == task.id })
            }
            self.autoConflictQueue.append(contentsOf: unique)
        }
        // Refresh conflict detection after loading
        detectAndQueueConflicts()
        deduplicateRescheduleQueues()
    }
}
