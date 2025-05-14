//
//  PlannerView.swift
//  NeverThink
//

import SwiftUI

// Main view for generating and managing an AI-created daily schedule from a selected group of tasks.
struct PlannerView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var todayPlanManager: TodayPlanManager

    // State tracking for UI flow and task planning
    @State private var selectedGroup: TaskGroup? = nil
    @State private var generatedPlan: [PlannedTask] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showTransportModeSheet: Bool = false
    @State private var selectedTransportMode: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTaskForEditing: PlannedTask? = nil
    @State private var extraNotes: String = ""
    @State private var showRegenerateFields: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.9, green: 0.94, blue: 1.0), .white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    // If no group is selected yet
                    if selectedGroup == nil {
                        taskGroupSelection
                    }
                    // Display error if any
                    else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    // Main planner UI if group is selected
                    else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if !generatedPlan.isEmpty {
                                    taskCardListView
                                    
                                    // Accept and regenerate buttons
                                    HStack(spacing: 12) {
                                        acceptPlanButton
                                        Button(action: {
                                            withAnimation {
                                                showRegenerateFields.toggle()
                                            }
                                        }) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 18, weight: .semibold))
                                                .padding(10)
                                                .background(Color.blue.opacity(0.9))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(.horizontal)

                                    // Optional regenerate UI
                                    if showRegenerateFields {
                                        regenerateSection
                                    }
                                } else {
                                    // First-time plan generation UI
                                    generatePromptSection
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("AI Daily Planner")
            .navigationBarTitleDisplayMode(.inline)

            // Modal for editing an individual task
            .sheet(item: $selectedTaskForEditing) { task in
                EditPlannedTaskView(task: task) { updatedTask in
                    if let index = generatedPlan.firstIndex(where: { $0.id == updatedTask.id }) {
                        generatedPlan[index] = updatedTask
                    }
                    selectedTaskForEditing = nil
                }
            }

            // Modal for choosing transport mode
            .sheet(isPresented: $showTransportModeSheet) {
                transportModeSheet
            }

            // Show loading overlay during GPT call
            .overlay {
                if isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Generating...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                }
            }

            // Request user location for travel matrix when view loads
            .onAppear {
                PlannerService.shared.requestLocation()
            }
        }
    }

    // UI Sections

    // UI for selecting a task group to generate a plan from
    private var taskGroupSelection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Pick a Task List")
                    .font(.title.bold())
                    .padding(.horizontal)

                ForEach(groupManager.groups) { group in
                    Button(action: {
                        selectedGroup = group
                        if let parsedDate = DateFormatter.longFormatter.date(from: group.name) {
                            selectedDate = parsedDate
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(group.name).font(.headline)
                                Text("\(group.tasks.count) task\(group.tasks.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selectedGroup?.id == group.id {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }

                Button("Continue") {
                    showTransportModeSheet = true
                }
                .disabled(selectedGroup == nil)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedGroup == nil ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.top)
            }
        }
    }

    // UI shown before plan generation with optional note input
    private var generatePromptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optional: Add Notes")
                .font(.headline)
                .padding(.top)

            TextEditor(text: $extraNotes)
                .frame(height: 100)
                .padding(10)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            generatePlanButton
        }
        .padding(.horizontal)
    }

    // UI section shown after a plan is generated for optional tweaks
    private var regenerateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Want tweaks? Add Notes and Regenerate")
                .font(.headline)

            TextEditor(text: $extraNotes)
                .frame(height: 100)
                .padding(10)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            Button(action: regeneratePlan) {
                Text("Regenerate Plan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    // Saves current AI-generated plan to TodayPlanManager
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
            Text("Accept This Plan")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(generatedPlan.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(generatedPlan.isEmpty)
    }

    // Launches transport mode sheet for plan generation
    private var generatePlanButton: some View {
        Button(action: {
            showTransportModeSheet = true
        }) {
            Text("Generate Plan")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(selectedGroup == nil || isLoading)
    }

    // Modal view for selecting how the user plans to travel
    private var transportModeSheet: some View {
        VStack(spacing: 20) {
            Text("How will you get around?")
                .font(.title2)
                .padding(.top)

            ForEach(["Walk", "Drive", "Public Transit"], id: \.self) { option in
                Button(option) {
                    selectedTransportMode = option.lowercased()
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

    // MARK: - Plan Logic

    // Generates an AI plan from the selected group and transport mode
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
                self.generatedPlan = rawPlan
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // Regenerates the plan with additional user notes
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
                self.generatedPlan = rawPlan
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // Computes a time range string based on task sensitivity type
    private func timeRangeString(for task: PlannedTask) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        switch task.timeSensitivityType {
        case .startsAt:
            if let start = formatter.date(from: task.start_time),
               let end = Calendar.current.date(byAdding: .minute, value: task.duration, to: start) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .dueBy:
            if let end = formatter.date(from: task.end_time),
               let start = Calendar.current.date(byAdding: .minute, value: -task.duration, to: end) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .busyFromTo:
            if let start = formatter.date(from: task.start_time),
               let end = formatter.date(from: task.end_time) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }
        case .none:
            return nil
        }

        return nil
    }

    // Displays the full list of AI-generated tasks
    private var taskCardListView: some View {
        ForEach(generatedPlan.indices, id: \.self) { index in
            let task = generatedPlan[index]
            TaskCardView(
                title: task.title,
                urgencyColor: task.urgency.color,
                duration: task.duration,
                date: task.date,
                location: task.location,
                reason: task.reason,
                timeRangeText: timeRangeString(for: task),
                showDateWarning: false,
                onDelete: { generatedPlan.remove(at: index) },
                onTap: { selectedTaskForEditing = task }
            )
        }
    }
}

// A UI card representing a single planned task with urgency indicator, time range, and location info.
// Supports editing (tap the card) and deleting (tap the red x button).
private struct PlannerTaskCardView: View {
    let task: PlannedTask
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    // Formats a readable time range string based on the task’s sensitivity type and duration
    private func timeRangeString(for task: PlannedTask) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        switch task.timeSensitivityType {
        case .startsAt:
            if let start = formatter.date(from: task.start_time),
               let end = Calendar.current.date(byAdding: .minute, value: task.duration, to: start) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }

        case .dueBy:
            if let end = formatter.date(from: task.end_time),
               let start = Calendar.current.date(byAdding: .minute, value: -task.duration, to: end) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }

        case .busyFromTo:
            if let start = formatter.date(from: task.start_time),
               let end = formatter.date(from: task.end_time) {
                return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
            }

        case .none:
            return nil
        }

        return nil
    }


    var body: some View {
        // Tapping the entire card allows editing the task
        Button(action: onEdit) {
            HStack(alignment: .top, spacing: 10) {
                // Urgency color indicator (small circle)
                Circle()
                    .fill(task.urgency.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
                // Task details section
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Group {
                        // Shows date and duration
                        Text("\(task.date.formatted(date: .abbreviated, time: .omitted)) • \(task.duration) min")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        // Shows location if available
                        if let loc = task.location, !loc.isEmpty {
                            Text("📍 \(loc)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        // Shows reasoning text if available
                        if let reason = task.reason, !reason.isEmpty {
                            Text(reason)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()
                // Red delete icon on the right
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial) // Semi-transparent card background
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle()) // Prevent tap highlighting
    }
}

// Style for the "Walk", "Drive", "Public Transit" buttons in the transport mode selector
struct TransportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

extension DateFormatter {
    static let longFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}
