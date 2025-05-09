//
//  TaskGroupManager.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: taskDate)

        if let index = groups.firstIndex(where: { $0.name == dateString }) {
            // Group for this date already exists
            groups[index].tasks.append(task)
        } else {
            // Group does not exist
            let newGroup = TaskGroup(name: dateString, tasks: [task])
            groups.append(newGroup)
        }
        groups.sort { $0.name < $1.name }
        objectWillChange.send()
    }


    func allTasks() -> [UserTask] {
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
            guard
                let date1 = formatter.date(from: group1.name),
                let date2 = formatter.date(from: group2.name)
            else {
                return false
            }
            return date1 < date2
        }
    }
}
