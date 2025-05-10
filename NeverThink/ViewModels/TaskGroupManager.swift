//
//  TaskGroupManager.swift
//  NeverThink
//

import Foundation
import SwiftUI

class TaskGroupManager: ObservableObject {
    @Published var groups: [TaskGroup] = []

    func addGroup(name: String) {
        let newGroup = TaskGroup(name: name, tasks: [])
        groups.append(newGroup)
        sortGroups()
    }

    func deleteGroup(at offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
    }

    func renameGroup(_ group: TaskGroup, to newName: String) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index].name = newName
        }
    }

    func updateGroup(_ group: TaskGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        }
    }

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
    }

    func deleteTask(_ task: UserTask) {
        for (index, group) in groups.enumerated() {
            if let taskIndex = group.tasks.firstIndex(where: { $0.id == task.id }) {
                groups[index].tasks.remove(at: taskIndex)
                break
            }
        }
    }

    var allTasks: [UserTask] {
        groups.flatMap { $0.tasks }
    }

    func updateTasks(for groupId: UUID, tasks: [UserTask]) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].tasks = tasks
            objectWillChange.send()
        }
    }

    private func sortGroups() {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        groups.sort { group1, group2 in
            guard let date1 = formatter.date(from: group1.name),
                  let date2 = formatter.date(from: group2.name) else { return false }
            return date1 < date2
        }
    }
}
