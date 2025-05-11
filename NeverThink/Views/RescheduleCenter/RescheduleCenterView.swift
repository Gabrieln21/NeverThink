import SwiftUI

struct RescheduleCenterView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Binding var rescheduleQueue: [UserTask]
    @Binding var selectedTask: UserTask?

    @State private var selectMode = false
    @State private var selectedTasks: Set<UUID> = []
    @State private var showHardDeadlinePrompt = false
    @State private var isLoadingAIPlan = false
    @State private var showDeadlineScreen = false
    @State private var tasksForDeadline: [UserTask] = []
    @State private var showReviewScreen = false
    @State private var aiGeneratedPlan: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
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

                                        if isTaskConflict(task) {
                                            Text("⚡ Conflict")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        }

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
                                        selectedTask = task
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }

                    VStack(spacing: 14) {
                        Button(action: { startOptimization(allTasks: true) }) {
                            Text("✨ AI Optimize All Tasks")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            if selectMode {
                                startOptimization(allTasks: false)
                            } else {
                                selectMode = true
                            }
                        }) {
                            Text(selectMode ? "✔️ Optimize Selected Tasks" : "🖐️ Select Specific Tasks")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.accentColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.accentColor, lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }

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
        }
    }

    // Helper Functions

    private func isTaskConflict(_ task: UserTask) -> Bool {
        return false // Replace with real logic
    }

    private func toggleSelect(_ task: UserTask) {
        if selectedTasks.contains(task.id) {
            selectedTasks.remove(task.id)
        } else {
            selectedTasks.insert(task.id)
        }
    }

    private func getScheduledEvents(start: Date, end: Date) -> [UserTask] {
        return groupManager.allTasks.filter { task in
            guard let taskDate = task.date else { return false }
            return (taskDate >= start && taskDate <= end) && task.exactTime != nil
        }
    }

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
                    // Create new task and add to calendar
                    let original = rescheduleQueue.first(where: { $0.id == uuid })

                    let newUserTask = UserTask(
                        id: uuid,
                        title: gpt.title,
                        duration: original?.duration ?? gpt.duration,
                        isTimeSensitive: true,
                        urgency: gpt.urgency,
                        isLocationSensitive: original?.isLocationSensitive ?? false,
                        location: original?.location ?? "Anywhere", // use original location
                        category: original?.category ?? .general,
                        timeSensitivityType: original?.timeSensitivityType ?? .startsAt,
                        exactTime: parsedExactTime,
                        timeRangeStart: nil,
                        timeRangeEnd: nil,
                        date: derivedDate,
                        parentRecurringId: nil
                    )

                    groupManager.addTask(newUserTask)
                }

                // Remove from reschedule center
                rescheduleQueue.removeAll(where: { $0.id == uuid })
            }

            print("✅ Applied AI plan and updated group manager & reschedule queue.")
        } catch {
            print("❌ Failed to decode GPTPlannedTask list: \(error)")
        }
    }





    private func generateAIOptimizationPrompt(tasks: [UserTask], deadlines: [UUID: Date]) {
        let earliest = Date()
        let latest = deadlines.values.sorted().last ?? Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let events = getScheduledEvents(start: earliest, end: latest)

        let prompt = GPTPromptBuilder.buildPrompt(
            tasks: tasks,
            deadlines: deadlines,
            scheduledEvents: events,
            from: earliest,
            to: latest
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
                    let newPrompt = GPTPromptBuilder.buildPrompt(
                        tasks: tasksForDeadline,
                        deadlines: [:],
                        scheduledEvents: getScheduledEvents(start: Date(), end: Date().addingTimeInterval(60*60*24*7)),
                        from: Date(),
                        to: Date().addingTimeInterval(60*60*24*7)
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


}


