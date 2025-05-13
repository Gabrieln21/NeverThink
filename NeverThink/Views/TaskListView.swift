//
//  TaskListView.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/25/25.
//
import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskManager: TaskManager

    var body: some View {
        NavigationView {
            List {
                ForEach(taskManager.tasks) { task in
                    VStack(alignment: .leading) {
                        Text(task.title)
                            .font(.headline)
                        HStack {
                            Text("\(task.duration) min • \(task.urgency.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: taskManager.deleteTask)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: NewTaskView(targetDate: Date())) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

