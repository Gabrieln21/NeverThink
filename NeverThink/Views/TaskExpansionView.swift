//
//  TaskExpansionView.swift
//  planMee
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
                let tasks = try await TaskExpansionService.shared.expandTextToTasks(userInput)
                self.generatedTasks = tasks
                self.userInput = "" // Clear input after generation
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func confirmAndSave() {
        for task in generatedTasks {
            let finalDate = task.date ?? Calendar.current.startOfDay(for: Date()) // Default to today if missing

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = dateFormatter.string(from: finalDate)

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

            if let dateGroupIndex = groupManager.groups.firstIndex(where: { $0.name == dateString }) {
                groupManager.groups[dateGroupIndex].tasks.append(newTask)
            } else {
                let newDateGroup = TaskGroup(name: dateString, tasks: [newTask])
                groupManager.groups.append(newDateGroup)
            }
        }

        generatedTasks = []
        userInput = ""
    }
}
