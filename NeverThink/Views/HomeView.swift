import SwiftUI
import UserNotifications

struct HomeView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var preferences: UserPreferencesService

    @State private var selectedDate: Date = Date()
    @State private var dateForNewTask: Date? = nil
    @State private var showConfetti: Bool = false
    @State private var selectedTask: UserTask? = nil
    @State private var showCompletedTasks: Bool = false
    @State private var showUserTasks: Bool = true
    @State private var selectedPlannedTask: PlannedTask? = nil
    @State private var showOriginalTasks = false
    @State private var showCompletedUserTasks: Bool = false


    private var todayPlannedTasks: [PlannedTask] {
        todayPlanManager.getTodayPlan(for: selectedDate)
    }

    private var todayTasks: [UserTask] {
        groupManager.allTasks.filter { task in
            guard let taskDate = task.date else { return false }
            return Calendar.current.isDate(taskDate, inSameDayAs: selectedDate)
                && !task.isCompleted
                && !groupManager.rescheduleQueue.contains(where: { $0.id == task.id })
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
                        emptyTasksSection
                    }

                    if !todayPlannedTasks.isEmpty {
                        aiPlanSection
                    }

                    initialTasksSection

                    // Show completed tasks at the end, with bottom padding if it's the only thing
                    if todayPlannedTasks.isEmpty && todayTasks.isEmpty {
                        completedTasksSection
                            .padding(.top, 80)
                            .padding(.bottom, 0)
                    } else {
                        completedTasksSection
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
    private var emptyTasksSection: some View {
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
    }

    @ViewBuilder
    private var completedTasksSection: some View {
        let completedUserTasks = groupManager.completedTasks(for: selectedDate)
        let completedAITasks = todayPlannedTasks.filter { $0.isCompleted }
        let hasCompletedTasks = !completedUserTasks.isEmpty || !completedAITasks.isEmpty

        if hasCompletedTasks {
            Section {
                DisclosureGroup("✅ Completed Tasks", isExpanded: $showCompletedTasks) {
                    ForEach(completedUserTasks, id: \.id) { task in
                        taskRow(task) {}
                    }

                    ForEach(completedAITasks, id: \.id) { task in
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
    }




    @ViewBuilder
    private var initialTasksSection: some View {
        if !todayTasks.isEmpty {
            if todayPlanManager.hasPlan(for: selectedDate) {
                // If AI plan exists, show original tasks in dropdown
                Section {
                    DisclosureGroup(isExpanded: $showOriginalTasks.animation(.easeInOut)) {
                        ForEach(todayTasks, id: \.id) { task in
                            taskRowWithSwipes(task)
                        }
                    } label: {
                        HStack {
                            Text(showOriginalTasks ? "Hide Original Tasks" : "Show Original Tasks")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: showOriginalTasks ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
            } else {
                // If no AI plan, just show original tasks normally
                Section {
                    ForEach(todayTasks, id: \.id) { task in
                        taskRowWithSwipes(task)
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
            }
        }
    }


    private var aiPlanSection: some View {
        let incompleteAITasks = todayPlannedTasks.filter { !$0.isCompleted }

        return Section(header: Text("🧠 AI Daily Plan")) {
            ForEach(incompleteAITasks, id: \.id) { task in
                AIPlannedTaskRow(
                    task: task,
                    onEdit: { selectedPlannedTask = task },
                    onComplete: {
                        todayPlanManager.markTaskCompleted(task)
                        triggerConfetti()
                    },
                    onReschedule: { }
                )
            }
        }
        .listRowBackground(Color.clear)
        .listSectionSeparator(.hidden)
    }



    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                }

                if !groupManager.rescheduleQueue.isEmpty {
                    NavigationLink(destination: RescheduleCenterView(
                        rescheduleQueue: Binding(get: { groupManager.rescheduleQueue }, set: { _ in }),
                        selectedTask: $selectedTask
                    )) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    dateForNewTask = selectedDate
                } label: {
                    Image(systemName: "plus")
                }

                Menu {
                    NavigationLink("AI Task Expansion", destination: TaskExpansionView())
                    NavigationLink("AI Day Planner", destination: PlannerView())
                } label: {
                    Image(systemName: "sparkles")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !todayPlannedTasks.isEmpty {
                    Button {
                        todayPlanManager.clearTodayPlan(for: selectedDate)
                    } label: {
                        Label("Remove Plan", systemImage: "trash")
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
        // Mark task as completed and persist it
        var updatedTask = task
        updatedTask.isCompleted = true
        groupManager.updateTask(updatedTask)

        triggerConfetti()
    }




    private func rescheduleTask(_ task: UserTask) {
        groupManager.manualRescheduleQueue.append(task)
        var updated = task
        updated.isCompleted = true
        groupManager.updateTask(updated) // make sure this updates in place
        groupManager.saveToDisk() // persist the change

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
    private func timeRangeText(for task: UserTask) -> String? {
        guard let start = task.exactTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startText = formatter.string(from: start)
        if let end = Calendar.current.date(byAdding: .minute, value: task.duration, to: start) {
            let endText = formatter.string(from: end)
            return "\(startText) – \(endText)"
        }
        return nil
    }
    
    private func displayLocation(_ raw: String?) -> String? {
        guard let loc = raw, !loc.isEmpty else { return nil }
        // Strip state/zip like "CA 94132"
        let parts = loc.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.prefix(2).joined(separator: ", ")
    }


    private func taskRow(_ task: UserTask, alarmAction: @escaping () -> Void) -> some View {
        HomeTaskCardView(
            task: task,
            onDelete: nil,
            onTap: { selectedTask = task }
        )
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
            if let start = DateFormatter.parseTimeString(task.start_time),
               let end = Calendar.current.date(byAdding: .minute, value: task.duration, to: start) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .dueBy:
            if let end = DateFormatter.parseTimeString(task.end_time),
               let start = Calendar.current.date(byAdding: .minute, value: -task.duration, to: end) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .busyFromTo:
            if let start = DateFormatter.parseTimeString(task.start_time),
               let end = DateFormatter.parseTimeString(task.end_time) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .none:
            if let start = DateFormatter.parseTimeString(task.start_time),
               let end = Calendar.current.date(byAdding: .minute, value: task.duration, to: start) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }

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
            reason: task.reason,
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
