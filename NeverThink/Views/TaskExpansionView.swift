//
//  TaskExpansionView.swift
//  NeverThink
//

import SwiftUI

struct TaskExpansionView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager

    @State private var userInput: String = ""
    @State private var generatedTasks: [UserTask] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $userInput)
                    .frame(height: 150)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding()

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
                    List(generatedTasks) { task in
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.headline)
                            Text("\(task.duration) min • Urgency: \(task.urgency.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: acceptTasks) {
                        Text("✅ Add to Today")
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
            .navigationTitle("Magic Wand 🪄")
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
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func acceptTasks() {
        let normalizedDate = Calendar.current.startOfDay(for: Date())

        let plannedTasks = generatedTasks.map { userTask in
            PlannedTask(
                start_time: userTask.exactTime != nil
                    ? DateFormatter.localizedString(from: userTask.exactTime!, dateStyle: .none, timeStyle: .short)
                    : "TBD",
                end_time: "TBD",
                title: userTask.title,
                notes: nil,
                reason: nil,
                date: normalizedDate
            )
        }

        todayPlanManager.saveTodayPlan(for: normalizedDate, plannedTasks)
        generatedTasks = []
        userInput = ""
    }


}
