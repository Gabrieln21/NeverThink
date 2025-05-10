//
//  RecurringTaskDetailView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//

import SwiftUI

struct RecurringTaskDetailView: View {
    @EnvironmentObject var recurringTaskManager: RecurringTaskManager
    @Environment(\.presentationMode) var presentationMode

    var task: RecurringTask
    var taskIndex: Int

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Info")) {
                    Text(task.title)
                        .font(.title)
                        .bold()

                    HStack {
                        Image(systemName: "repeat")
                        Text("Repeats: \(task.recurringInterval.rawValue)")
                    }

                    if task.isTimeSensitive {
                        switch task.timeSensitivityType {
                        case .dueBy:
                            if let dueBy = task.exactTime {
                                HStack {
                                    Image(systemName: "clock")
                                    Text("Due by: \(dueBy.formatted(date: .omitted, time: .shortened))")
                                }
                            }
                        case .startsAt:
                            if let startsAt = task.exactTime {
                                HStack {
                                    Image(systemName: "clock")
                                    Text("Starts at: \(startsAt.formatted(date: .omitted, time: .shortened))")
                                }
                            }
                        case .busyFromTo:
                            if let start = task.timeRangeStart, let end = task.timeRangeEnd {
                                HStack {
                                    Image(systemName: "clock")
                                    Text("Busy from: \(start.formatted(date: .omitted, time: .shortened)) to \(end.formatted(date: .omitted, time: .shortened))")
                                }
                            }
                        case .none:
                            EmptyView() // nothing to display if `.none`
                        }
                    }

                }

                Section {
                    Button(role: .destructive) {
                        deleteTask()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Recurring Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditRecurringTaskView(taskIndex: taskIndex, task: task)
                        .environmentObject(recurringTaskManager)
                    ) {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
    }

    func deleteTask() {
        recurringTaskManager.deleteRecurringTask(at: IndexSet(integer: taskIndex))
        presentationMode.wrappedValue.dismiss()
    }
}
