//
//  EditPlannedTaskView.swift
//  NeverThink
//

import SwiftUI

struct EditPlannedTaskView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var task: PlannedTask
    var onSave: (PlannedTask) -> Void

    // Editable fields
    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var reason: String
    @State private var durationHours: String
    @State private var durationMinutes: String

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    init(task: PlannedTask, onSave: @escaping (PlannedTask) -> Void) {
        self._task = State(initialValue: task)
        self.onSave = onSave

        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes ?? "")
        _reason = State(initialValue: task.reason ?? "")

        let now = Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        _startTime = State(initialValue: formatter.date(from: task.start_time) ?? now)
        _endTime = State(initialValue: formatter.date(from: task.end_time) ?? now)

        let duration = EditPlannedTaskView.calculateDurationMinutes(start: _startTime.wrappedValue, end: _endTime.wrappedValue)
        _durationHours = State(initialValue: "\(duration / 60)")
        _durationMinutes = State(initialValue: "\(duration % 60)")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Info")) {
                    TextField("Title", text: $title)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration:")
                        HStack {
                            TextField("Hours", text: $durationHours)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Text("hours")
                            TextField("Minutes", text: $durationMinutes)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Text("minutes")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                    }
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5))
                        )
                }

                Section(header: Text("AI Reason")) {
                    TextEditor(text: $reason)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5))
                        )
                }

                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                    Button("Delete Task", role: .destructive) {
                        deleteTask()
                    }
                }
            }
            .navigationTitle("Edit AI Task")
        }
    }

    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.start_time = timeFormatter.string(from: startTime)
        updatedTask.end_time = timeFormatter.string(from: endTime)
        updatedTask.notes = notes.isEmpty ? nil : notes
        updatedTask.reason = reason.isEmpty ? nil : reason

        onSave(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }

    private func deleteTask() {
        onSave(task)
        presentationMode.wrappedValue.dismiss()
    }

    private static func calculateDurationMinutes(start: Date, end: Date) -> Int {
        let minutes = Calendar.current.dateComponents([.minute], from: start, to: end).minute ?? 0
        return max(minutes, 0)
    }
}
