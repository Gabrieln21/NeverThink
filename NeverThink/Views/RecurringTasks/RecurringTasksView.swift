//
//  RecurringTasksView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//
import SwiftUI

struct RecurringTasksView: View {
    @EnvironmentObject var recurringManager: RecurringTaskManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @State private var showAddRecurring = false

    var body: some View {
        NavigationView {
            List {
                ForEach(recurringManager.tasks.indices, id: \.self) { index in
                    let task = recurringManager.tasks[index]
                    NavigationLink(destination: RecurringTaskDetailView(task: task, taskIndex: index)
                        .environmentObject(recurringManager)
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                            if task.isTimeSensitive {
                                switch task.timeSensitivityType {
                                case .dueBy:
                                    if let dueBy = task.exactTime {
                                        Text("\(task.recurringInterval.rawValue) • Due by \(dueBy.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                case .startsAt:
                                    if let startsAt = task.exactTime {
                                        Text("\(task.recurringInterval.rawValue) • Starts at \(startsAt.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                case .busyFromTo:
                                    if let start = task.timeRangeStart, let end = task.timeRangeEnd {
                                        Text("\(task.recurringInterval.rawValue) • \(start.formatted(date: .omitted, time: .shortened))–\(end.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                Text("\(task.recurringInterval.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteRecurringTask)
            }
            .navigationTitle("🔁 Recurring Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddRecurring = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRecurring) {
                NewRecurringTaskView()
                    .environmentObject(recurringManager)
                    .environmentObject(groupManager)
            }

        }
    }

    func deleteRecurringTask(at offsets: IndexSet) {
        recurringManager.tasks.remove(atOffsets: offsets)
    }
}
