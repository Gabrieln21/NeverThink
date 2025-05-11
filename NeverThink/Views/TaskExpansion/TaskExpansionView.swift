import SwiftUI

extension Notification.Name {
    static let magicWandTaskSaved = Notification.Name("magicWandTaskSaved")
}

struct TaskExpansionView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.dismiss) private var dismiss

    @State private var userInput: String = ""
    @State private var generatedTasks: [UserTask] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTask: UserTask? = nil

    var body: some View {
        NavigationView {
            ZStack {
                // background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.9, green: 0.94, blue: 1.0), .white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ZStack(alignment: .bottom) {
                    VStack(spacing: 20) {
                        Text("Task Generator")
                            .font(.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        if generatedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Paste assignments, emails, notes, anything. AI will make tasks for you:")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)

                                TextEditor(text: $userInput)
                                    .frame(height: 150)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                                    .padding(.horizontal)
                            }
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        if !generatedTasks.isEmpty {
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(generatedTasks.indices, id: \.self) { index in
                                        TaskCardView(
                                            title: generatedTasks[index].title,
                                            urgencyColor: generatedTasks[index].urgency.color,
                                            duration: generatedTasks[index].duration,
                                            date: generatedTasks[index].date,
                                            location: generatedTasks[index].location,
                                            reason: nil,
                                            timeRangeText: timeRangeString(for: generatedTasks[index]),
                                            showDateWarning: generatedTasks[index].date == nil,
                                            onDelete: { generatedTasks.remove(at: index) },
                                            onTap: { selectedTask = generatedTasks[index] }
                                        )
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.bottom, 80)
                        }

                        Spacer()
                    }

                    VStack {
                        Spacer()
                        Button(action: {
                            generatedTasks.isEmpty ? generateTasks() : confirmAndSave()
                        }) {
                            Text(generatedTasks.isEmpty ? "Generate Tasks" : "Confirm and Save")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background((generatedTasks.isEmpty && userInput.isEmpty) ? Color.gray : Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                        }
                        .disabled(generatedTasks.isEmpty && userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedTask) { task in
                GeneratedTaskEditorView(task: task) { updatedTask in
                    if let index = generatedTasks.firstIndex(where: { $0.id == updatedTask.id }) {
                        generatedTasks[index] = updatedTask
                    }
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    ProgressView("Generating...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
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
                let relevantDates = try await TaskExpansionService.shared.findRelevantDates(from: userInput)
                var snapshot: [Date: [String]] = [:]

                for task in groupManager.allTasks {
                    guard let date = task.date else { continue }
                    let dayStart = Calendar.current.startOfDay(for: date)

                    if relevantDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: dayStart) }) {
                        snapshot[dayStart, default: []].append(task.title)
                    }
                }

                let tasks = try await TaskExpansionService.shared.expandTextToTasks(userInput, existingSchedule: snapshot)
                self.generatedTasks = tasks
                self.userInput = ""
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
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
            NotificationCenter.default.post(name: .magicWandTaskSaved, object: finalDate)
        }

        generatedTasks = []
        userInput = ""
        dismiss() // Return Home
    }
}

