//
//  HomeView.swift
//  NeverThink
//

import SwiftUI
import UserNotifications

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
    @State private var showUserTasks: Bool = true
    @State private var selectedPlannedTask: PlannedTask? = nil


    private var todayPlannedTasks: [PlannedTask] {
        todayPlanManager.getTodayPlan(for: selectedDate)
    }

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

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.85, green: 0.9, blue: 1.0), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                List {
                    Section {
                        VStack(spacing: 8) {
                            Text("NeverThink")
                                .font(.largeTitle.bold())

                            if !Calendar.current.isDateInToday(selectedDate) {
                                Text("Stay ahead 🌟")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            calendarHeader
                        }
                        .listRowBackground(Color.clear)
                        .listSectionSeparator(.hidden)
                    }

                    if todayPlannedTasks.isEmpty && todayTasks.isEmpty {
                        Section {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Text("No tasks yet!")
                                        .font(.title3)
                                        .foregroundColor(.gray)

                                    Button(action: { dateForNewTask = selectedDate }) {
                                        Label("Add a Task", systemImage: "plus.circle.fill")
                                            .font(.headline)
                                            .padding()
                                            .background(Color.accentColor.opacity(0.9))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listSectionSeparator(.hidden)
                    } else {
                        if !todayPlannedTasks.isEmpty {
                            Section(header: Text("🧠 AI Daily Plan")) {
                                ForEach(todayPlannedTasks, id: \.id) { task in
                                    AIPlannedTaskRow(
                                        task: task,
                                        onEdit: { selectedPlannedTask = task },
                                        onComplete: { todayPlanManager.markTaskCompleted(task) },
                                        onReschedule: { }
                                    )
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                        }

                        if let completedToday = completedTasksForDay[selectedDate], !completedToday.isEmpty || !todayPlannedTasks.filter({ $0.isCompleted }).isEmpty {
                            Section {
                                DisclosureGroup("✅ Completed Tasks", isExpanded: $showCompletedTasks) {
                                    ForEach(completedToday, id: \.id) { task in
                                        taskRow(task) {}
                                    }

                                    ForEach(todayPlannedTasks.filter { $0.isCompleted }, id: \.id) { task in
                                        AIPlannedTaskRow(
                                            task: task,
                                            onEdit: { selectedPlannedTask = task },
                                            onComplete: {},
                                            onReschedule: {}
                                        )
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                        }

                        if !todayTasks.isEmpty {
                            Section {
                                if !todayPlannedTasks.isEmpty {
                                    DisclosureGroup("📋 Initial Tasks", isExpanded: $showUserTasks) {
                                        ForEach(todayTasks, id: \.id) { task in
                                            taskRowWithSwipes(task)
                                        }
                                    }
                                } else {
                                    ForEach(todayTasks, id: \.id) { task in
                                        taskRowWithSwipes(task)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)

            }
            .navigationTitle("")
            .toolbar { toolbarItems }
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(task: task, taskIndex: 0)
            }
            .sheet(isPresented: Binding(get: { dateForNewTask != nil }, set: { if !$0 { dateForNewTask = nil } })) {
                if let date = dateForNewTask {
                    NewTaskView(targetDate: date)
                        .environmentObject(groupManager)
                }
            }
            .sheet(item: $selectedPlannedTask) { task in
                EditPlannedTaskView(task: task) { updated in
                    todayPlanManager.updateTask(updated)
                    selectedPlannedTask = nil
                }
            }

            .overlay(confettiOverlay)
        }
    }

    private var calendarHeader: some View {
        VStack(spacing: 8) {
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .accentColor(.accentColor)
                .background(Color.clear)
                .padding(.horizontal)
        }
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                HStack(spacing: 16) {
                    NavigationLink(destination: TaskExpansionView().environmentObject(groupManager)) {
                        Image(systemName: "wand.and.stars.inverse")
                            .font(.title2)
                    }
                    if !rescheduleQueue.isEmpty {
                        NavigationLink(destination: RescheduleCenterView(rescheduleQueue: $rescheduleQueue, selectedTask: $selectedTask)) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
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
    }

    private var confettiOverlay: some View {
        Group {
            if showConfetti {
                VStack {
                    Spacer()
                    Text("🎉")
                        .font(.system(size: 80))
                        .opacity(1)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeOut(duration: 0.4), value: showConfetti)
                    Spacer()
                }
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
        taskRow(task) {}
            .contentShape(Rectangle())
            .onTapGesture { selectedTask = task }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) { completeTask(task) } label: {
                    Label("Complete", systemImage: "checkmark")
                }.tint(.green)
            }
            .swipeActions(edge: .leading) {
                Button { rescheduleTask(task) } label: {
                    Label("Reschedule", systemImage: "calendar")
                }.tint(.blue)
            }
    }

    private func taskRow(_ task: UserTask, alarmAction: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Circle().fill(task.urgency.color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.system(.headline, design: .rounded)).foregroundColor(.primary)
                HStack(spacing: 8) {
                    Text("\(task.duration) min")
                    Text("•")
                    Text("Urgency: \(task.urgency.rawValue)")
                }.font(.caption).foregroundColor(.secondary)
                if task.isLocationSensitive, let loc = task.location, !loc.lowercased().contains("anywhere") {
                    Text("📍 \(loc)").font(.caption2).foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: alarmAction) {
                Image(systemName: "bell").foregroundColor(.gray.opacity(0.7))
            }
        }
        .padding(16)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.88, green: 0.90, blue: 1.0)).shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))
        .padding(.horizontal, 6)
    }
    
    private func timeRangeString(for task: UserTask) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        switch task.timeSensitivityType {
        case .startsAt:
            if let start = task.exactTime,
               let end = Calendar.current.date(byAdding: .minute, value: task.duration, to: start) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }

        case .dueBy:
            if let end = task.exactTime,
               let start = Calendar.current.date(byAdding: .minute, value: -task.duration, to: end) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }

        case .busyFromTo:
            if let start = task.timeRangeStart,
               let end = task.timeRangeEnd {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }

        case .none:
            return nil
        }

        return nil
    }

}

struct AIPlannedTaskRow: View {
    let task: PlannedTask
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onReschedule: () -> Void
    
    private var timeRangeText: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        switch task.timeSensitivityType {
        case .startsAt:
            if let start = formatter.date(from: task.start_time),
               let end = Calendar.current.date(byAdding: .minute, value: task.duration, to: start) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .dueBy:
            if let end = formatter.date(from: task.end_time),
               let start = Calendar.current.date(byAdding: .minute, value: -task.duration, to: end) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .busyFromTo:
            if let start = formatter.date(from: task.start_time),
               let end = formatter.date(from: task.end_time) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .none:
            return nil
        }

        return nil
    }


    var body: some View {
        TaskCardView(
            title: task.title,
            urgencyColor: task.urgency.color,
            duration: task.duration,
            date: task.date,
            location: task.location,
            reason: nil,
            timeRangeText: timeRangeText,
            showDateWarning: false,
            onDelete: nil,
            onTap: onEdit
        )

        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onComplete()
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading) {
            Button {
                onReschedule()
            } label: {
                Label("Reschedule", systemImage: "calendar")
            }
            .tint(.blue)
        }
    }
    
}

