import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var todayPlanManager: TodayPlanManager

    @State private var selectedGroup: TaskGroup?
    @State private var generatedPlan: [PlannedTask] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showTransportModeSheet: Bool = false
    @State private var selectedTransportMode: String = ""

    var body: some View {
        NavigationView {
            VStack {
                taskListPicker

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            ProgressView("Generating your plan with AI...")
                                .padding()
                        } else if let errorMessage = errorMessage {
                            Text("⚠️ \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                        } else if !generatedPlan.isEmpty {
                            ForEach(generatedPlan) { task in
                                TaskCardView(task: task)
                            }

                            acceptPlanButton
                        } else {
                            emptyState
                        }

                        if generatedPlan.isEmpty {
                            generatePlanButton
                        }
                    }
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showTransportModeSheet) {
                    transportModeSheet
                }
            }
            .navigationTitle("AI Daily Planner")
            .onAppear {
                PlannerService.shared.requestLocation()
            }
        }
    }

    var taskListPicker: some View {
        Picker("Select Task List", selection: $selectedGroup) {
            ForEach(groupManager.groups) { group in
                Text(group.name).tag(Optional(group))
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding()
    }

    var acceptPlanButton: some View {
        Button(action: {
            todayPlanManager.saveTodayPlan(generatedPlan)
            generatedPlan = []
            errorMessage = "✅ Plan saved for today!"
        }) {
            Text("✅ Accept This Plan")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding([.horizontal, .bottom])
    }

    var generatePlanButton: some View {
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
        .padding([.horizontal, .bottom])
        .disabled(selectedGroup == nil || isLoading)
    }

    var emptyState: some View {
        VStack {
            Spacer()
            Text("🧠 Select a list and generate your plan")
                .foregroundColor(.gray)
            Spacer()
        }
    }

    var transportModeSheet: some View {
        VStack(spacing: 20) {
            Text("How will you get around?")
                .font(.title2)
                .padding()

            Button("🚶‍♂️ Walk") {
                selectedTransportMode = "walk"
                showTransportModeSheet = false
                generatePlan()
            }
            .buttonStyle(TransportButtonStyle())

            Button("🚗 Drive") {
                selectedTransportMode = "drive"
                showTransportModeSheet = false
                generatePlan()
            }
            .buttonStyle(TransportButtonStyle())

            Button("🚋 Public Transit") {
                selectedTransportMode = "public transit"
                showTransportModeSheet = false
                generatePlan()
            }
            .buttonStyle(TransportButtonStyle())

            Button("Cancel") {
                showTransportModeSheet = false
            }
            .foregroundColor(.red)
            .padding(.top, 10)
        }
        .padding()
    }

    func generatePlan() {
        guard let group = selectedGroup else { return }

        isLoading = true
        errorMessage = nil
        generatedPlan = []

        Task {
            do {
                let plan = try await PlannerService.shared.generatePlan(
                    from: group.tasks,
                    for: Date(),
                    transportMode: selectedTransportMode
                )
                self.generatedPlan = plan
            } catch {
                self.errorMessage = error.localizedDescription
                print("⚠️ Error generating plan: \(error)")
            }
            isLoading = false
        }
    }
}

struct TaskCardView: View {
    let task: PlannedTask

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(task.start_time) - \(task.end_time)")
                .font(.caption)
                .foregroundColor(.gray)
            Text(task.title)
                .font(.headline)
            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let reason = task.reason, !reason.isEmpty {
                DisclosureGroup("AI Reasoning") {
                    Text(reason)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
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
