//
//  HomeView.swift
//  NeverThink
//

import SwiftUI
import UserNotifications

struct HomeView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var taskManager: TaskManager

    @State private var selectedDate: Date = Date()
    @State private var showAddTask = false
    @State private var scrollOffset: CGFloat = 0

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
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        VStack {
                            DatePicker(
                                "Select a day",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                        }
                        .background(Color.white)
                        .opacity(scrollOffset < 50 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.25), value: scrollOffset)

                        VStack(spacing: 16) {
                            if !todayPlanManager.todayPlan.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("🎯 Today's AI Plan")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    ForEach(todayPlanManager.todayPlan) { task in
                                        taskCardView(title: task.title, subtitle: "\(task.start_time) - \(task.end_time)", reason: task.reason ?? "") {
                                            scheduleAlarmForAI(task)
                                        }
                                    }
                                }
                            }

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

                                        ForEach(Array(scheduledTasks.enumerated()), id: \.1.id) { index, task in
                                            NavigationLink(destination: TaskDetailView(task: task, taskIndex: index)
                                                .environmentObject(taskManager)
                                            ) {
                                                taskRow(task) {
                                                    scheduleAlarmForCalendar(task)
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

                                        ForEach(Array(unscheduledTasks.enumerated()), id: \.1.id) { index, task in
                                            NavigationLink(destination: TaskDetailView(task: task, taskIndex: index)
                                                .environmentObject(groupManager)) {
                                                    taskRow(task) {
                                                        scheduleAlarmForCalendar(task)
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: ScrollOffsetKey.self, value: -proxy.frame(in: .named("scroll")).origin.y)
                            }
                        )
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
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

                    if task.isLocationSensitive, let loc = task.location {
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
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Notification permission error: \(error.localizedDescription)")
                    }
                }
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
                print("Invalid time format for notification.")
                return
            }
        } else {
            return
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
