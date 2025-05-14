//
//  TaskGroupManager.swift
//  NeverThink
//

import Foundation
import SwiftUI

// Manages grouped user tasks by date and handles scheduling conflicts.
class TaskGroupManager: ObservableObject {
    @Published var groups: [TaskGroup] = []                        // List of date-based task groups
    @Published var autoConflictQueue: [UserTask] = []              // Tasks with detected conflicts
    @Published var manualRescheduleQueue: [UserTask] = []          // Tasks flagged manually for rescheduling

    // Combined queue for UI display or batch rescheduling logic
    var rescheduleQueue: [UserTask] {
        autoConflictQueue + manualRescheduleQueue
    }

    // Group Management

    func addGroup(name: String) {
        let newGroup = TaskGroup(name: name, tasks: [])
        groups.append(newGroup)
        sortGroups()
        saveToDisk()
        detectAndQueueConflicts()
    }

    func deleteGroup(at offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
        saveToDisk()
        detectAndQueueConflicts()
    }

    func renameGroup(_ group: TaskGroup, to newName: String) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index].name = newName
        }
        saveToDisk()
        detectAndQueueConflicts()
    }

    func updateGroup(_ group: TaskGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        }
        saveToDisk()
        detectAndQueueConflicts()
    }
    
    // Task Management

    func addTask(_ task: UserTask) {
        guard let taskDate = task.date else { return }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateString = formatter.string(from: taskDate)

        if let index = groups.firstIndex(where: { $0.name == dateString }) {
            groups[index].tasks.append(task)
        } else {
            let newGroup = TaskGroup(name: dateString, tasks: [task])
            groups.append(newGroup)
        }
        sortGroups()
        objectWillChange.send()
        saveToDisk()
        detectAndQueueConflicts()
    }

    func deleteTask(_ task: UserTask) {
        for (index, group) in groups.enumerated() {
            if let taskIndex = group.tasks.firstIndex(where: { $0.id == task.id }) {
                groups[index].tasks.remove(at: taskIndex)
                break
            }
        }
        saveToDisk()
        detectAndQueueConflicts()
    }

    var allTasks: [UserTask] {
        groups.flatMap { $0.tasks }
    }
    
    func removeTaskById(_ id: UUID) {
        for (groupIndex, group) in groups.enumerated() {
            if let taskIndex = group.tasks.firstIndex(where: { $0.id == id }) {
                groups[groupIndex].tasks.remove(at: taskIndex)
                break
            }
        }
        // Also remove from conflict/reschedule queues
        manualRescheduleQueue.removeAll { $0.id == id }
        autoConflictQueue.removeAll { $0.id == id }
        objectWillChange.send()
        saveToDisk()
        detectAndQueueConflicts()
    }



    func updateTask(_ updatedTask: UserTask) {
        for groupIndex in groups.indices {
            if let taskIndex = groups[groupIndex].tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                groups[groupIndex].tasks[taskIndex] = updatedTask
                saveToDisk()
                return
            }
        }
    }
    
    // Filters tasks that are completed on a given date
    func completedTasks(for date: Date) -> [UserTask] {
        let day = Calendar.current.startOfDay(for: date)
        return allTasks.filter {
            $0.isCompleted &&
            Calendar.current.isDate($0.date ?? .distantPast, inSameDayAs: day) &&
            !rescheduleQueue.contains(where: { $0.id == $0.id })
        }
    }

    // Removes duplicate task IDs from both conflict queues
    func deduplicateRescheduleQueues() {
        manualRescheduleQueue = deduplicatedTasks(from: manualRescheduleQueue)
        autoConflictQueue = deduplicatedTasks(from: autoConflictQueue)
    }

    private func deduplicatedTasks(from tasks: [UserTask]) -> [UserTask] {
        var seen = Set<UUID>()
        var result: [UserTask] = []

        for task in tasks {
            if !seen.contains(task.id) {
                seen.insert(task.id)
                result.append(task)
            }
        }

        return result
    }


    // Sorts groups by their date string (assumes date format is consistent)
    private func sortGroups() {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        groups.sort { group1, group2 in
            guard let date1 = formatter.date(from: group1.name),
                  let date2 = formatter.date(from: group2.name) else { return false }
            return date1 < date2
        }
    }

    // Detects overlapping tasks and queues them for automatic conflict resolution
    func detectAndQueueConflicts() {
        var conflicts: Set<UUID> = []
        let tasksWithTime = allTasks.filter { $0.exactTime != nil }

        for (i, a) in tasksWithTime.enumerated() {
            for b in tasksWithTime[(i+1)...] {
                // Skip if not on same day
                guard let aDate = a.date, let bDate = b.date,
                      Calendar.current.isDate(aDate, inSameDayAs: bDate) else { continue }

                // Skip if either is not time sensitive
                if !a.isTimeSensitive || !b.isTimeSensitive { continue }

                if isConflict(a, b) {
                    conflicts.insert(a.id)
                    conflicts.insert(b.id)
                }
            }
        }

        let conflictedTasks = allTasks.filter { conflicts.contains($0.id) }
        DispatchQueue.main.async {
            self.autoConflictQueue = conflictedTasks
        }
    }



    // Checks if two tasks overlap in time
    private func isConflict(_ a: UserTask, _ b: UserTask) -> Bool {
        guard let aStart = a.exactTime, let bStart = b.exactTime else { return false }
        let aEnd = Calendar.current.date(byAdding: .minute, value: a.duration, to: aStart)!
        let bEnd = Calendar.current.date(byAdding: .minute, value: b.duration, to: bStart)!
        return max(aStart, bStart) < min(aEnd, bEnd)
    }

}
extension TaskGroupManager {
    // Updates all tasks in a specific group
    func updateTasks(for groupId: UUID, tasks: [UserTask]) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].tasks = tasks
            saveToDisk()
        }
    }
}
