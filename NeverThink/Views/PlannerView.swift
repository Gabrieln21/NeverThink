import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var todayPlanManager: TodayPlanManager

    @State private var selectedGroup: TaskGroup? = nil
    @State private var generatedPlan: [PlannedTask] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showTransportModeSheet: Bool = false
    @State private var selectedTransportMode: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTaskForEditing: PlannedTask? = nil
    @State private var extraNotes: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if selectedGroup == nil {
                    taskGroupSelection
                } else if isLoading {
                    ProgressView("Generating your plan with AI...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("⚠️ \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !generatedPlan.isEmpty {
                                ForEach(generatedPlan.indices, id: \.self) { index in
                                    HStack {
                                        Button(action: {
                                            generatedPlan.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title2)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .padding(.trailing, 4)

                                        Button(action: {
                                            selectedTaskForEditing = generatedPlan[index]
                                        }) {
                                            TaskCardView(task: generatedPlan[index])
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                acceptPlanButton
                                regenerateSection
                            } else {
                                generatePromptSection
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("AI Daily Planner")
            .sheet(item: $selectedTaskForEditing) { task in
                EditPlannedTaskView(task: task) { updatedTask in
                    if let index = generatedPlan.firstIndex(where: { $0.id == updatedTask.id }) {
                        generatedPlan[index] = updatedTask
                    }
                    selectedTaskForEditing = nil
                }
            }
            .sheet(isPresented: $showTransportModeSheet) {
                transportModeSheet
            }
            .onAppear {
                PlannerService.shared.requestLocation()
            }
        }
    }

    private var taskGroupSelection: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("📋 Pick a Task List")
                    .font(.title2)
                    .padding(.top)

                ForEach(groupManager.groups) { group in
                    Button(action: {
                        selectedGroup = group
                        if let parsedDate = DateFormatter.longFormatter.date(from: group.name) {
                            selectedDate = parsedDate
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(group.name)
                                    .font(.headline)
                                Text("\(group.tasks.count) tasks")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selectedGroup?.id == group.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }

                Button("Continue") {
                    showTransportModeSheet = true
                }
                .disabled(selectedGroup == nil)
                .padding()
                .frame(maxWidth: .infinity)
                .background(selectedGroup == nil ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
        }
    }

    private var generatePromptSection: some View {
        VStack(spacing: 16) {
            Text("✨ Optional: Add Notes")
                .font(.headline)
                .padding(.top)

            TextEditor(text: $extraNotes)
                .frame(height: 100)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            generatePlanButton
        }
    }

    private var regenerateSection: some View {
        VStack(spacing: 16) {
            Text("🔁 Want tweaks? Add Notes and Regenerate")
                .font(.headline)
                .padding(.top)

            TextEditor(text: $extraNotes)
                .frame(height: 100)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            Button(action: {
                regeneratePlan()
            }) {
                Text("🔁 Regenerate Plan with Notes")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
    }

    private var acceptPlanButton: some View {
        Button(action: {
            let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
            let updatedTasks = generatedPlan.map { task in
                var newTask = task
                newTask.date = normalizedDate
                return newTask
            }
            todayPlanManager.saveTodayPlan(for: normalizedDate, updatedTasks)
            generatedPlan = []
            errorMessage = "✅ Plan saved for \(normalizedDate.formatted(date: .abbreviated, time: .omitted))!"
        }) {
            Text("✅ Accept This Plan")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(generatedPlan.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
        .disabled(generatedPlan.isEmpty)
    }

    private var generatePlanButton: some View {
        Button(action: {
            showTransportModeSheet = true
        }) {
            Text("Generate Plan")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
        .disabled(selectedGroup == nil || isLoading)
    }

    private var transportModeSheet: some View {
        VStack(spacing: 20) {
            Text("How will you get around?")
                .font(.title2)
                .padding()

            ForEach(["🚶‍♂️ Walk", "🚗 Drive", "🚋 Public Transit"], id: \.self) { option in
                Button(option) {
                    selectedTransportMode = option.contains("Walk") ? "walk" :
                                             option.contains("Drive") ? "drive" : "public transit"
                    showTransportModeSheet = false
                    generatePlan()
                }
                .buttonStyle(TransportButtonStyle())
            }

            Button("Cancel") {
                showTransportModeSheet = false
            }
            .foregroundColor(.red)
            .padding(.top)
        }
        .padding()
    }

    private func generatePlan() {
        guard let group = selectedGroup else { return }
        isLoading = true
        errorMessage = nil
        generatedPlan = []

        Task {
            do {
                let rawPlan = try await PlannerService.shared.generatePlan(
                    from: group.tasks,
                    for: selectedDate,
                    transportMode: selectedTransportMode
                )
                self.generatedPlan = rawPlan.map { var task = $0; task.date = selectedDate; return task }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func regeneratePlan() {
        guard let group = selectedGroup else { return }
        isLoading = true
        errorMessage = nil
        generatedPlan = []

        Task {
            do {
                let rawPlan = try await PlannerService.shared.generatePlan(
                    from: group.tasks,
                    for: selectedDate,
                    transportMode: selectedTransportMode,
                    extraNotes: extraNotes
                )
                self.generatedPlan = rawPlan.map { var task = $0; task.date = selectedDate; return task }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct TransportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

extension DateFormatter {
    static let longFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}
