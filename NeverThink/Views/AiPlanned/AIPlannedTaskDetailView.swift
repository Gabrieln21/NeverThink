//
//  AIPlannedTaskDetailView.swift
//  NeverThink
//

import SwiftUI

struct AIPlannedTaskDetailView: View {
    @State private var task: PlannedTask
    @State private var showingEdit = false

    init(task: PlannedTask) {
        _task = State(initialValue: task)
    }

    var body: some View {
        Form {
            Section(header: Text("Task Info")) {
                Text(task.title)
                    .font(.headline)

                HStack {
                    Text("Time:")
                    Spacer()
                    Text("\(task.start_time) - \(task.end_time)")
                }

                if let notes = task.notes, !notes.isEmpty {
                    HStack {
                        Text("Notes:")
                        Spacer()
                        Text(notes)
                    }
                }

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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditPlannedTaskView(task: task) { updatedTask in
                self.task = updatedTask
            }
        }
    }
}
