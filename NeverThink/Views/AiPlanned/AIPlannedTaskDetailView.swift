//
//  AIPlannedTaskDetailView.swift
//  NeverThink
//

import SwiftUI

// Displays detailed info for a single AI-planned task
struct AIPlannedTaskDetailView: View {
    @State private var task: PlannedTask
    @State private var showingEdit = false

    // Initializes the view with a specific planned task
    init(task: PlannedTask) {
        _task = State(initialValue: task)
    }

    var body: some View {
        Form {
            // displaying basic task details
            Section(header: Text("Task Info")) {
                Text(task.title)
                    .font(.headline)

                HStack {
                    Text("Time:")
                    Spacer()
                    Text("\(task.start_time) - \(task.end_time)")
                }

                // Show user notes if present
                if let notes = task.notes, !notes.isEmpty {
                    HStack {
                        Text("Notes:")
                        Spacer()
                        Text(notes)
                    }
                }
                
                // Show GPT-generated reasoning if present
                if let reason = task.reason, !reason.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Reasoning")
                            .font(.headline)
                        Text(reason)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("Task Details")
        .toolbar {
            // Edit button in the top-right of navigation bar
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        // Show editable modal view for updating task
        .sheet(isPresented: $showingEdit) {
            EditPlannedTaskView(task: task) { updatedTask in
                self.task = updatedTask
            }
        }
    }
}
