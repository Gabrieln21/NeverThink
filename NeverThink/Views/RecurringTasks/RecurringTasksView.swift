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
    @State private var selectedFilter: RecurringInterval? = nil

    var body: some View {
        NavigationView {
            VStack {
                filterButtons

                List {
                    ForEach(filteredTasks.indices, id: \.self) { index in
                        let task = filteredTasks[index]
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
                                    case .none:
                                        EmptyView()
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
                .listStyle(.plain)
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

    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(title: "All", type: nil)
                filterButton(title: "Daily", type: .daily)
                filterButton(title: "Weekly", type: .weekly)
                filterButton(title: "Monthly", type: .monthly)
                filterButton(title: "Yearly", type: .yearly)
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }

    private func filterButton(title: String, type: RecurringInterval?) -> some View {
        Button(action: {
            selectedFilter = type
        }) {
            Text(title)
                .font(.subheadline.weight(.semibold)) // smaller and cleaner text
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(selectedFilter == type ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                .foregroundColor(selectedFilter == type ? .accentColor : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selectedFilter == type ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
                )
                .fixedSize(horizontal: true, vertical: false) // Prevent ugly line breaks
        }
    }


    private var filteredTasks: [RecurringTask] {
        if let filter = selectedFilter {
            return recurringManager.tasks.filter { $0.recurringInterval == filter }
        } else {
            return recurringManager.tasks
        }
    }

    func deleteRecurringTask(at offsets: IndexSet) {
        // Delete from full list, not filtered list
        let mappedOffsets = IndexSet(offsets.map { index in
            recurringManager.tasks.firstIndex(where: { $0.id == filteredTasks[index].id }) ?? index
        })
        recurringManager.tasks.remove(atOffsets: mappedOffsets)
    }
}
