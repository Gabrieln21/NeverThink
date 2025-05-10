//
//  HomeView.swift
//  NeverThink
//

import SwiftUI
import UserNotifications

extension Date: Identifiable {
    public var id: Date { self }
}

extension Notification.Name {
    static let magicWandTaskSaved = Notification.Name("magicWandTaskSaved")
}

struct HomeView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager

    @State private var selectedDate: Date = Date()
    @State private var dateForNewTask: Date? = nil
    @State private var completedTasksForDay: [Date: [UserTask]] = [:]
    @State private var rescheduleQueue: [UserTask] = []
    @State private var showConfetti: Bool = false
    @State private var selectedTask: UserTask? = nil
    @State private var showCompletedTasks: Bool = false

    private var todayTasks: [UserTask] {
        groupManager.allTasks.filter { task in
            guard let taskDate = task.date else { return false }
            return Calendar.current.isDate(taskDate, inSameDayAs: selectedDate)
        }
        .filter { task in
            !completedTasksForDay[selectedDate, default: []].contains(where: { $0.id == task.id })
            && !rescheduleQueue.contains(where: { $0.id == task.id })
        }
    }

    private var scheduledTasks: [UserTask] {
        todayTasks.filter { task in
            task.isTimeSensitive && (task.exactTime != nil || (task.timeRangeStart != nil && task.timeRangeEnd != nil))
        }
        .sorted { lhs, rhs in
            (lhs.exactTime ?? lhs.timeRangeStart ?? Date()) < (rhs.exactTime ?? rhs.timeRangeStart ?? Date())
        }
    }

    private var unscheduledTasks: [UserTask] {
        todayTasks.filter { task in
            !(task.isTimeSensitive && (task.exactTime != nil || task.timeRangeStart != nil))
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                calendarHeader

                List {
                    if !scheduledTasks.isEmpty {
                        Section(header: Text("📅 Scheduled Tasks")) {
                            ForEach(scheduledTasks) { task in
                                taskRowWithSwipes(task)
                            }
                        }
                    }

                    if !unscheduledTasks.isEmpty {
                        Section(header: Text("🗓️ Unscheduled Tasks")) {
                            ForEach(unscheduledTasks) { task in
                                taskRowWithSwipes(task)
                            }
                        }
                    }

                    if let completedToday = completedTasksForDay[selectedDate], !completedToday.isEmpty {
                        Section {
                            DisclosureGroup(isExpanded: $showCompletedTasks) {
                                ForEach(completedToday) { task in
                                    taskRow(task) { }
                                }
                            } label: {
                                Text("✅ Completed Tasks")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationDestination(for: UserTask.self) { task in
                TaskDetailView(task: task, taskIndex: 0)
                    .environmentObject(groupManager)
            }
            .toolbar { toolbarItems }
            .sheet(item: $dateForNewTask) { date in
                NewTaskView(targetDate: date)
                    .environmentObject(groupManager)
            }
            .overlay(confettiOverlay)
        }
    }

    private var calendarHeader: some View {
        DatePicker("Select a day", selection: $selectedDate, displayedComponents: [.date])
            .datePickerStyle(.graphical)
            .padding()
            .background(Color.white)
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                NavigationLink(destination: TaskExpansionView().environmentObject(groupManager)) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "wand.and.stars.inverse")
                            .font(.title2)
                        if !rescheduleQueue.isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    dateForNewTask = selectedDate
                } label: {
                    Image(systemName: "plus")
                }

                NavigationLink(destination: PlannerView()
                    .environmentObject(groupManager)
                    .environmentObject(todayPlanManager)) {
                        Image(systemName: "sparkles")
                }
            }
        }
    }


    private var confettiOverlay: some View {
        Group {
            if showConfetti {
                Text("🎉")
                    .font(.system(size: 60))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale)
            }
        }
    }

    private func completeTask(_ task: UserTask) {
        let day = Calendar.current.startOfDay(for: selectedDate)
        completedTasksForDay[day, default: []].append(task)
        groupManager.deleteTask(task)
        triggerConfetti()
    }

    private func rescheduleTask(_ task: UserTask) {
        rescheduleQueue.append(task)
        groupManager.deleteTask(task)
    }

    private func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showConfetti = false
        }
    }

    private func taskRowWithSwipes(_ task: UserTask) -> some View {
        NavigationLink(value: task) {
            taskRow(task) { }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                completeTask(task)
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                rescheduleTask(task)
            } label: {
                Label("Reschedule", systemImage: "calendar")
            }
            .tint(.blue)
        }
    }

    private func taskRow(_ task: UserTask, alarmAction: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if task.isTimeSensitive {
                    HStack {
                        Image(systemName: "clock")
                        if let time = task.exactTime {
                            Text(time.formatted(date: .omitted, time: .shortened))
                        } else if let start = task.timeRangeStart {
                            Text(start.formatted(date: .omitted, time: .shortened))
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Text(task.title)
                    .font(.headline)
                Text("\(task.duration) min | Urgency: \(task.urgency.rawValue)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                if task.isLocationSensitive, let loc = task.location, !loc.lowercased().contains("anywhere") {
                    Text("📍 \(loc)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: alarmAction) {
                Image(systemName: "bell")
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
    }
}
