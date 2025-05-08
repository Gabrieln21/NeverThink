//
//  HomeView.swift
//  NeverThink
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager

    @State private var selectedDate: Date = Date()
    @State private var showAddTask = false

    private var todayTasks: [UserTask] {
        groupManager.allTasks().filter { task in
            guard let taskDate = task.date else { return false }
            return Calendar.current.isDate(taskDate, inSameDayAs: selectedDate)
        }
    }

    private var scheduledTasks: [UserTask] {
        todayTasks.filter { task in
            task.isTimeSensitive && (task.exactTime != nil || (task.timeRangeStart != nil && task.timeRangeEnd != nil))
        }
        .sorted(by: { lhs, rhs in
            (lhs.exactTime ?? lhs.timeRangeStart ?? Date()) < (rhs.exactTime ?? rhs.timeRangeStart ?? Date())
        })
    }

    private var unscheduledTasks: [UserTask] {
        todayTasks.filter { task in
            !(task.isTimeSensitive && (task.exactTime != nil || (task.timeRangeStart != nil && task.timeRangeEnd != nil)))
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select a day",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                List {
                    if !todayPlanManager.todayPlan.isEmpty {
                        Section(header: Text("🎯 Today's AI Plan")) {
                            ForEach(todayPlanManager.todayPlan) { task in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(task.start_time) - \(task.end_time)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(task.title)
                                        .font(.headline)
                                    if let reason = task.reason, !reason.isEmpty {
                                        Text(reason)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    if scheduledTasks.isEmpty && unscheduledTasks.isEmpty {
                        Text("No tasks for this day!")
                            .foregroundColor(.gray)
                    } else {
                        if !scheduledTasks.isEmpty {
                            scheduledTasksSection
                        }
                        if !unscheduledTasks.isEmpty {
                            unscheduledTasksSection
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        Button(action: {
                            showAddTask = true
                        }) {
                            Image(systemName: "plus")
                        }

                        NavigationLink(destination: PlannerView()
                            .environmentObject(groupManager)
                            .environmentObject(todayPlanManager)
                        ) {
                            Image(systemName: "sparkles")
                        }
                    }
                }



                .sheet(isPresented: $showAddTask) {
                    NewTaskView()
                        .environmentObject(groupManager)
                }
            }
        }
    }

    private var scheduledTasksSection: some View {
        Section(header: Text("📅 Scheduled Tasks")) {
            ForEach(Array(scheduledTasks.enumerated()), id: \.1.id) { index, task in
                NavigationLink(destination: TaskDetailView(task: task, taskIndex: index)
                    .environmentObject(groupManager)) {
                    taskRow(task)
                }
            }
        }
    }

    private var unscheduledTasksSection: some View {
        Section(header: Text("🗓️ Unscheduled Tasks")) {
            ForEach(Array(unscheduledTasks.enumerated()), id: \.1.id) { index, task in
                NavigationLink(destination: TaskDetailView(task: task, taskIndex: index)
                    .environmentObject(groupManager)) {
                    taskRow(task)
                }
            }
        }
    }

    private func taskRow(_ task: UserTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if task.isTimeSensitive {
                HStack {
                    Image(systemName: "clock")
                    if let time = task.exactTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let start = task.timeRangeStart {
                        Text(start.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(task.title)
                .font(.headline)

            Text("\(task.duration) min | Urgency: \(task.urgency.rawValue)")
                .font(.caption2)
                .foregroundColor(.gray)

            if task.isLocationSensitive, let loc = task.location {
                Text("📍 \(loc)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
