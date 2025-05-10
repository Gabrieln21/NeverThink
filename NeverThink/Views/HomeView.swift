//
//  HomeView.swift
//  NeverThink
//

import SwiftUI
import UserNotifications

extension Date: Identifiable {
    public var id: Date { self }
}

struct HomeView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager

    @State private var selectedDate: Date = Date()
    @State private var dateForNewTask: Date? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var showOriginalTasks: Bool = false
    @State private var completedTasks: [UserTask] = []
    @State private var showConfetti: Bool = false

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
        .sorted { lhs, rhs in
            (lhs.exactTime ?? lhs.timeRangeStart ?? Date()) < (rhs.exactTime ?? rhs.timeRangeStart ?? Date())
        }
    }

    private var unscheduledTasks: [UserTask] {
        todayTasks.filter { task in
            !(task.isTimeSensitive && (task.exactTime != nil || (task.timeRangeStart != nil && task.timeRangeEnd != nil)))
        }
    }

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        calendarHeader

                        VStack(spacing: 16) {
                            let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
                            let todaysAIPlan = todayPlanManager.getTodayPlan(for: normalizedDate)

                            aiPlanSection(todaysAIPlan: todaysAIPlan)

                            if !todaysAIPlan.isEmpty {
                                DisclosureGroup(isExpanded: $showOriginalTasks) {
                                    originalTasksSection
                                } label: {
                                    Text("📝 Show Original Tasks")
                                        .font(.headline)
                                        .padding(.horizontal)
                                }
                                .padding()
                            } else {
                                originalTasksSection
                            }
                        }
                        .padding(.top)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: ScrollOffsetKey.self, value: -proxy.frame(in: .named("scroll")).origin.y)
                            }
                        )
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        NavigationLink(destination: TaskExpansionView().environmentObject(groupManager)) {
                            Image(systemName: "wand.and.stars.inverse")
                        }
                    }
                    
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: {
                            dateForNewTask = selectedDate
                        }) {
                            Image(systemName: "plus")
                        }

                        NavigationLink(destination: PlannerView()
                            .environmentObject(groupManager)
                            .environmentObject(todayPlanManager)) {
                                Image(systemName: "sparkles")
                        }
                    }
                }

                .sheet(item: $dateForNewTask) { date in
                    NewTaskView(targetDate: date)
                        .environmentObject(groupManager)
                }
                .overlay(
                    Group {
                        if showConfetti {
                            Text("🎉")
                                .font(.system(size: 60))
                                .transition(.scale)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .zIndex(1)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
                        }
                    }
                )
            }
        }
    }

    private var calendarHeader: some View {
        VStack {
            DatePicker("Select a day", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
        }
        .background(Color.white)
        .opacity(scrollOffset < 50 ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: scrollOffset)
    }

    private func completeAIPlanTask(_ task: PlannedTask) {
        todayPlanManager.markTaskCompleted(task) // mark as completed
        triggerConfetti()
    }

    private func aiPlanSection(todaysAIPlan: [PlannedTask]) -> some View {
        let activeAIPlans = todaysAIPlan.filter { !$0.isCompleted } // Only show active ones
        return Group {
            if !activeAIPlans.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🎯 AI Plan for This Day")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(activeAIPlans) { task in
                        taskCardView(
                            title: task.title,
                            subtitle: "\(task.start_time) - \(task.end_time)",
                            reason: task.reason ?? ""
                        ) {
                            scheduleAlarmForAI(task)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                completeAIPlanTask(task)
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    private var originalTasksSection: some View {
        Group {
            if scheduledTasks.isEmpty && unscheduledTasks.isEmpty {
                Text("No tasks for this day!")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                if !scheduledTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📅 Scheduled Tasks")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(scheduledTasks) { task in
                            taskRow(task) {
                                scheduleAlarmForCalendar(task)
                            }
                            .background(
                                NavigationLink(destination: TaskDetailView(task: task, taskIndex: 0).environmentObject(groupManager)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    completeTask(task)
                                } label: {
                                    Label("Complete", systemImage: "checkmark")
                                }
                            }
                        }
                    }
                }

                if !unscheduledTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🗓️ Unscheduled Tasks")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(unscheduledTasks) { task in
                            taskRow(task) {
                                scheduleAlarmForCalendar(task)
                            }
                            .background(
                                NavigationLink(destination: TaskDetailView(task: task, taskIndex: 0).environmentObject(groupManager)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    completeTask(task)
                                } label: {
                                    Label("Complete", systemImage: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                NavigationLink(destination: TaskExpansionView().environmentObject(groupManager)) {
                    Image(systemName: "wand.and.stars.inverse")
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    dateForNewTask = selectedDate
                }) {
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



    private func completeTask(_ task: UserTask) {
        completedTasks.append(task)
        groupManager.deleteTask(task)
        triggerConfetti()
    }

    private func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showConfetti = false
        }
    }
}

// Needed because SwiftUI needs them scoped properly
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Notifications
private func scheduleAlarmForAI(_ task: PlannedTask) {
    requestNotificationPermissionIfNeeded()
    scheduleNotification(title: "Upcoming Task", body: task.title, at: task.start_time)
}

private func scheduleAlarmForCalendar(_ task: UserTask) {
    guard let time = task.exactTime ?? task.timeRangeStart else { return }
    requestNotificationPermissionIfNeeded()
    scheduleNotification(title: "Calendar Event", body: task.title, at: time)
}

private func requestNotificationPermissionIfNeeded() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        if settings.authorizationStatus != .authorized {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
}

private func scheduleNotification(title: String, body: String, at dateOrString: Any) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    var triggerDateComponents: DateComponents

    if let date = dateOrString as? Date {
        triggerDateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
    } else if let timeString = dateOrString as? String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        if let date = formatter.date(from: timeString) {
            triggerDateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        } else {
            return
        }
    } else {
        return
    }

    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}

// task views
private func taskRow(_ task: UserTask, alarmAction: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
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
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color(.systemGray6))
    .cornerRadius(10)
    .padding(.horizontal)
}

private func taskCardView(title: String, subtitle: String, reason: String, alarmAction: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(title)
                    .font(.headline)
                if !reason.isEmpty {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: alarmAction) {
                Image(systemName: "bell")
                    .font(.title3)
            }
        }
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color(.systemGray6))
    .cornerRadius(10)
    .padding(.horizontal)
}
