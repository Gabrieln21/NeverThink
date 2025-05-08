//
//  TaskListViewForGroup.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//
import SwiftUI

struct TaskListViewForGroup: View {
    @EnvironmentObject var groupManager: TaskGroupManager

    var group: TaskGroup
    @State private var tasks: [UserTask]

    init(group: TaskGroup) {
        self.group = group
        _tasks = State(initialValue: group.tasks)
    }

    var body: some View {
        List {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                NavigationLink(destination: TaskDetailView(task: task, taskIndex: index)) {
                    VStack(alignment: .leading) {
                        Text(task.title)
                            .font(.headline)
                        Text("\(task.duration) min • \(task.urgency.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onDelete { offsets in
                tasks.remove(atOffsets: offsets)
                groupManager.updateTasks(for: group.id, tasks: tasks)
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            NavigationLink(destination: NewTaskViewForGroup(groupId: group.id, tasks: $tasks)) {
                Image(systemName: "plus")
            }
        }
    }
}

