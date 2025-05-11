//
//  RescheduleCenterView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//

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
            VStack {
                Text("🛠️ Reschedule Center")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                List {
                    Section(header: Text("Tasks Needing Attention")) {
                        ForEach(rescheduleQueue) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.headline)
                                    HStack {
                                        if let time = task.exactTime ?? task.timeRangeStart {
                                            Text("⏰ \(time.formatted(date: .omitted, time: .shortened))")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        Text("| \(task.duration) min | \(task.urgency.rawValue)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                if isTaskConflict(task) {
                                    Text("⚡ Conflict")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                if selectMode {
                                    Image(systemName: selectedTasks.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectMode {
                                    toggleSelect(task)
                                } else {
                                    selectedTask = task
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)

                VStack(spacing: 12) {
                    Button(action: {
                        startOptimization(allTasks: true)
                    }) {
                        Text("✨ AI Optimize All Tasks")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)

                    Button(action: {
                        if selectMode {
                            startOptimization(allTasks: false)
                        } else {
                            selectMode = true
                        }
                    }) {
                        Text(selectMode ? "✔️ Optimize Selected Tasks" : "🖐️ Select Specific Tasks")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }
                .padding(.bottom)
                .sheet(isPresented: $showDeadlineScreen) {
                    HardDeadlineSelectionView(tasks: tasksForDeadline) { deadlines in
                        generateAIOptimizationPrompt(tasks: tasksForDeadline, deadlines: deadlines)
                    }
                }

                .sheet(isPresented: $showReviewScreen) {
                    AIRescheduleReviewView(
                        aiPlanText: aiGeneratedPlan,
                        onAccept: {
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
            .navigationTitle("📆 Reschedule Center")
            .overlay(
                Group {
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
            )
        }
    }

    // --- Helper Functions ---

    private func isTaskConflict(_ task: UserTask) -> Bool {
        // implement real time conflict checking here
        return false
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


    func startOptimization(allTasks: Bool) {
        if allTasks {
            tasksForDeadline = rescheduleQueue
        } else {
            tasksForDeadline = rescheduleQueue.filter { selectedTasks.contains($0.id) }
        }
        showDeadlineScreen = true
    }
    
    
    func generateAIOptimizationPrompt(tasks: [UserTask], deadlines: [UUID: Date]) {
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
}
