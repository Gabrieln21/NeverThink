//
//  RescheduelCenterView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/02/25.
//
import SwiftUI

// Central hub where users review and resolve scheduling conflicts using AI or manual tools.
struct RescheduleCenterView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Binding var rescheduleQueue: [UserTask]
    @Binding var selectedTask: UserTask?

    // UI and flow control states
    @State private var selectMode = false
    @State private var selectedTasks: Set<UUID> = []
    @State private var showHardDeadlinePrompt = false
    @State private var isLoadingAIPlan = false
    @State private var showDeadlineScreen = false
    @State private var tasksForDeadline: [UserTask] = []
    @State private var showReviewScreen = false
    @State private var aiGeneratedPlan: String = ""
    @State private var showOptimizationModal = false
    @State private var taskToEdit: UserTask?
    @State private var showTaskEditor = false
    @State private var refreshID = UUID()




    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.85, green: 0.9, blue: 1.0),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("🛠️ Reschedule Center")
                        .font(.largeTitle.bold())
                        .padding(.top)
                    // Task conflict display
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Tasks Needing Attention")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            ForEach(rescheduleQueue) { task in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)

                                            HStack(spacing: 10) {
                                                if let time = task.exactTime ?? task.timeRangeStart {
                                                    Text("⏰ \(time.formatted(date: .omitted, time: .shortened))")
                                                }
                                                Text("\(task.duration) min • \(task.urgency.rawValue)")
                                            }
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                        }

                                        Spacer()
                                        // Conflict marker
                                        if isTaskConflict(task) {
                                            Text("⚡ Conflict")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }
                                        // Selectable for batch optimization
                                        if selectMode {
                                            Image(systemName: selectedTasks.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.horizontal)
                                .onTapGesture {
                                    if selectMode {
                                        toggleSelect(task)
                                    } else {
                                        taskToEdit = task
                                        showTaskEditor = true
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .id(refreshID)
                    
                    // AI Optimize Button
                    Button {
                        showOptimizationModal = true
                    } label: {
                        Text("✨ AI Optimize Tasks")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showOptimizationModal) {
                        AIOptimizationModalView(
                            tasks: rescheduleQueue,
                            onConfirm: { selected in
                                tasksForDeadline = selected
                                showDeadlineScreen = true
                            }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                // Loading overlay during AI generation
                if isLoadingAIPlan {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2)

                            Text("Generating your optimized plan...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isLoadingAIPlan)
                }
            }
            .navigationTitle("📆 Reschedule Center")
            .sheet(isPresented: $showReviewScreen) {
                reviewSheet
            }
            .sheet(isPresented: $showDeadlineScreen, content: {
                HardDeadlineSelectionView(tasks: tasksForDeadline) { deadlines in
                    print("📬 Got deadlines: \(deadlines)")
                    generateAIOptimizationPrompt(tasks: tasksForDeadline, deadlines: deadlines)
                    showDeadlineScreen = false
                }
                .id(UUID()) // Force refresh
            })
            .sheet(isPresented: $showTaskEditor) {
                editorSheetContent
            }
        }
    }

    // Detects if a given task conflicts with others
    private func isTaskConflict(_ task: UserTask) -> Bool {
        let allScheduled = groupManager.allTasks.filter {
            $0.id != task.id && $0.exactTime != nil
        }

        func overlaps(_ startA: Date, _ durationA: Int, _ startB: Date, _ durationB: Int) -> Bool {
            let endA = startA.addingTimeInterval(TimeInterval(durationA * 60))
            let endB = startB.addingTimeInterval(TimeInterval(durationB * 60))
            return startA < endB && endA > startB
        }

        // startsAt — fixed time
        // Check for overlaps depending on type of time sensitivity
        if let taskStart = task.exactTime {
            for scheduled in allScheduled {
                if let scheduledStart = scheduled.exactTime {
                    if overlaps(taskStart, task.duration, scheduledStart, scheduled.duration) {
                        return true
                    }
                }
            }
        }

        // busyFromTo — flexible range
        else if let rangeStart = task.timeRangeStart,
                let rangeEnd = task.timeRangeEnd {
            let latestStart = rangeEnd.addingTimeInterval(TimeInterval(-task.duration * 60))

            var earliestConflict = false
            var latestConflict = false

            for scheduled in allScheduled {
                if let scheduledStart = scheduled.exactTime {
                    if overlaps(rangeStart, task.duration, scheduledStart, scheduled.duration) {
                        earliestConflict = true
                    }
                    if overlaps(latestStart, task.duration, scheduledStart, scheduled.duration) {
                        latestConflict = true
                    }
                }
            }

            if earliestConflict && latestConflict {
                return true // No safe placement
            }
        }

        return false
    }


    // Toggle task selection for batch optimization
    private func toggleSelect(_ task: UserTask) {
        if selectedTasks.contains(task.id) {
            selectedTasks.remove(task.id)
        } else {
            selectedTasks.insert(task.id)
        }
    }

    // Returns events with fixed times in a range
    private func getScheduledEvents(start: Date, end: Date) -> [UserTask] {
        return groupManager.allTasks.filter { task in
            guard let taskDate = task.date else { return false }
            return (taskDate >= start && taskDate <= end) && task.exactTime != nil
        }
    }
    
    // Prepares deadline entry flow
    private func startOptimization(allTasks: Bool) {
        print("🔥 startOptimization called with allTasks: \(allTasks)")

        if allTasks {
            tasksForDeadline = rescheduleQueue
        } else {
            tasksForDeadline = rescheduleQueue.filter { selectedTasks.contains($0.id) }
        }
        showDeadlineScreen = true
        print("🧭 Showing deadline screen for \(tasksForDeadline.count) tasks")

    }
    
    // Applies AI-generated plan back into group manager
    private func applyAIPlan(_ response: String) {
        guard let data = response.data(using: .utf8) else {
            print("❌ Failed to convert response to data")
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let gptTasks = try decoder.decode([GPTPlannedTask].self, from: data)
            let isoFormatter = ISO8601DateFormatter()

            for gpt in gptTasks {
                guard let parsedExactTime = isoFormatter.date(from: gpt.start_time),
                      let uuid = UUID(uuidString: gpt.id) else {
                    print("❌ Invalid UUID or time: \(gpt.id), \(gpt.start_time)")
                    continue
                }

                let derivedDate = Calendar.current.startOfDay(for: parsedExactTime)

                if let groupIndex = groupManager.groups.firstIndex(where: {
                    $0.tasks.contains(where: { $0.id == uuid })
                }),
                let taskIndex = groupManager.groups[groupIndex].tasks.firstIndex(where: {
                    $0.id == uuid
                }) {
                    // Update existing task
                    var updated = groupManager.groups[groupIndex].tasks[taskIndex]
                    updated.exactTime = parsedExactTime
                    updated.date = derivedDate
                    updated.duration = gpt.duration
                    updated.urgency = gpt.urgency
                    groupManager.groups[groupIndex].tasks[taskIndex] = updated
                } else {
                    // Add new task if it doesn't already exist
                    let newUserTask = UserTask(
                        id: uuid,
                        title: gpt.title,
                        duration: gpt.duration,
                        isTimeSensitive: true,
                        urgency: gpt.urgency,
                        isLocationSensitive: false,
                        location: "Anywhere",
                        category: .general,
                        timeSensitivityType: .startsAt,
                        exactTime: parsedExactTime,
                        timeRangeStart: nil,
                        timeRangeEnd: nil,
                        date: derivedDate,
                        parentRecurringId: nil
                    )
                    groupManager.addTask(newUserTask)
                }

                // Always remove from reschedule queue, no matter what
                rescheduleQueue.removeAll(where: { $0.id == uuid })
                refreshID = UUID()
            }

            print("✅ Applied AI plan and updated group manager & reschedule queue.")
        } catch {
            print("❌ Failed to decode GPTPlannedTask list: \(error)")
        }
    }




    // Builds GPT prompt and fetches optimized plan
    private func generateAIOptimizationPrompt(tasks: [UserTask], deadlines: [UUID: Date]) {
        let earliest = Date()
        let latest = deadlines.values.sorted().last ?? Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let events = getScheduledEvents(start: earliest, end: latest)
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        let wakeUpTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: today)!
        let bedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: today)!
        let existingEvents = getScheduledEvents(start: today, end: endDate)

        let prompt = GPTPromptBuilder.buildPrompt(
            tasks: tasks,
            deadlines: deadlines,
            scheduledEvents: existingEvents,
            from: today,
            to: endDate,
            wakeTime: wakeUpTime,
            sleepTime: bedtime
        )


        isLoadingAIPlan = true

        Task {
            do {
                let aiResponse = try await AIRescheduleService.requestReschedulePlan(prompt: prompt)
                isLoadingAIPlan = false

                aiGeneratedPlan = aiResponse
                showReviewScreen = true
                print("✅ Received AI Plan:\n\(aiResponse)")
            } catch {
                isLoadingAIPlan = false
                print("❌ Failed to fetch AI plan: \(error)")
            }
        }
    }
    
    // Review Sheet for user to accept or regenerate plan
    @ViewBuilder
    private var reviewSheet: some View {
        AIRescheduleReviewView(
            aiPlanText: aiGeneratedPlan,
            originalTasks: tasksForDeadline,
            onAccept: {
                applyAIPlan(aiGeneratedPlan)
                showReviewScreen = false
            },
            onRegenerate: { userNotes in
                Task {
                    isLoadingAIPlan = true
                    let now = Date()
                    let start = Calendar.current.startOfDay(for: now)
                    let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!

                    let wakeTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: start)!
                    let sleepTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: start)!

                    let newPrompt = GPTPromptBuilder.buildPrompt(
                        tasks: tasksForDeadline,
                        deadlines: [:],
                        scheduledEvents: getScheduledEvents(start: start, end: end),
                        from: start,
                        to: end,
                        wakeTime: wakeTime,
                        sleepTime: sleepTime
                    ) + "\n\nUser Notes: \(userNotes)"



                    do {
                        let newResponse = try await AIRescheduleService.requestReschedulePlan(prompt: newPrompt)
                        isLoadingAIPlan = false
                        aiGeneratedPlan = newResponse
                    } catch {
                        isLoadingAIPlan = false
                        print("❌ Failed to regenerate AI plan.")
                    }
                }
            }
        )
    }
    
    // Shows task editor when tapping individual task
    @ViewBuilder
    private var editorSheetContent: some View {
        if let editable = taskToEdit {
            GeneratedTaskEditorView(task: Binding(
                get: { editable },
                set: { taskToEdit = $0 }
            )) {
                groupManager.manualRescheduleQueue.removeAll { $0.id == editable.id }
                groupManager.autoConflictQueue.removeAll { $0.id == editable.id }
                groupManager.addTask(editable)
                groupManager.saveToDisk()
                refreshID = UUID()
            }
        } else {
            EmptyView()
        }
    }
}


