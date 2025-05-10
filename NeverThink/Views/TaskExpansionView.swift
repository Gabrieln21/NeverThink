//
//  TaskExpansionView.swift
//  NeverThink
//

import SwiftUI

struct TaskExpansionView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager

    @State private var userInput: String = ""
    @State private var generatedTasks: [UserTask] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTask: UserTask? = nil

    var body: some View {
        NavigationView {
            VStack {
                if generatedTasks.isEmpty {
                    TextEditor(text: $userInput)
                        .frame(height: 150)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                }

                if isLoading {
                    ProgressView("Generating tasks...")
                        .padding()
                }

                if let errorMessage = errorMessage {
                    Text("⚠️ \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }

                if !generatedTasks.isEmpty {
                    List {
                        ForEach(generatedTasks.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                // Delete button
                                Button(action: {
                                    generatedTasks.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .padding(.top, 4)

                                // Tap to edit
                                Button(action: {
                                    selectedTask = generatedTasks[index]
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(generatedTasks[index].title)
                                            .font(.headline)

                                        Text("\(generatedTasks[index].duration) min • Urgency: \(generatedTasks[index].urgency.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if let date = generatedTasks[index].date {
                                            Text("📅 \(date.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("⚠️ No date set (will default to Today)")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 6)
                        }
                    }

                    Button(action: confirmAndSave) {
                        Text("✅ Confirm and Save Tasks")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }

                Spacer()

                if generatedTasks.isEmpty {
                    Button(action: generateTasks) {
                        Text("✨ Generate Tasks")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
            .navigationTitle("Magic Wand 🪄")
            .sheet(item: $selectedTask) { task in
                GeneratedTaskEditorView(task: task) { updatedTask in
                    if let index = generatedTasks.firstIndex(where: { $0.id == updatedTask.id }) {
                        generatedTasks[index] = updatedTask
                    }
                }
            }
        }
    }

    private func generateTasks() {
        guard !userInput.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        generatedTasks = []

        Task {
            do {
                // Step 1: Find relevant dates from userInput
                let relevantDates = try await TaskExpansionService.shared.findRelevantDates(from: userInput)

                // Step 2: Build a schedule only for those dates
                var snapshot: [Date: [String]] = [:]

                for task in groupManager.allTasks {
                    guard let date = task.date else { continue }
                    let dayStart = Calendar.current.startOfDay(for: date)

                    if relevantDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: dayStart) }) {
                        let taskSummary = task.title + (task.duration > 0 ? " (\(task.duration) min)" : "")
                        snapshot[dayStart, default: []].append(taskSummary)
                    }
                }

                // Step 3: Pass the filtered schedule into expandTextToTasks
                let tasks = try await TaskExpansionService.shared.expandTextToTasks(userInput, existingSchedule: snapshot)

                self.generatedTasks = tasks
                self.userInput = "" // Clear input after
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }


    private func buildScheduleSnapshot() -> [Date: [String]] {
        var snapshot: [Date: [String]] = [:]

        for task in groupManager.allTasks {
            guard let date = task.date else { continue }

            let dayStart = Calendar.current.startOfDay(for: date)

            let taskSummary = task.title + (task.duration > 0 ? " (\(task.duration) min)" : "")

            snapshot[dayStart, default: []].append(taskSummary)
        }

        return snapshot
    }

    private func confirmAndSave() {
        for task in generatedTasks {
            let finalDate = task.date ?? Calendar.current.startOfDay(for: Date())
            let newTask = UserTask(
                id: task.id,
                title: task.title,
                duration: task.duration,
                isTimeSensitive: task.isTimeSensitive,
                urgency: task.urgency,
                isLocationSensitive: task.isLocationSensitive,
                location: task.location,
                category: .doAnywhere,
                timeSensitivityType: task.timeSensitivityType,
                exactTime: task.exactTime,
                timeRangeStart: task.timeRangeStart,
                timeRangeEnd: task.timeRangeEnd,
                date: finalDate
            )
            groupManager.addTask(newTask)

            // Notify HomeView to reload
            NotificationCenter.default.post(name: .magicWandTaskSaved, object: finalDate)
        }

        generatedTasks = []
        userInput = ""
    }
}
