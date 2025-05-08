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
            // at least one group, add to the first group
            if groups.isEmpty {
                let newGroup = TaskGroup(name: "General", tasks: [task])
                groups.append(newGroup)
            } else {
                groups[0].tasks.append(task)
            }
            
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
    }
