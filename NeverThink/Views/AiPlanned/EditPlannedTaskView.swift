import SwiftUI

struct EditPlannedTaskView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var task: PlannedTask
    var onSave: (PlannedTask) -> Void

    @State private var title: String
    @State private var isTimeSensitive: Bool = true
    @State private var timeSensitivityType: TimeSensitivity = .startsAt
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var exactTime: Date
    @State private var durationHours: String
    @State private var durationMinutes: String
    @State private var urgency: UrgencyLevel
    @State private var notes: String
    @State private var reason: String

    @State private var showNotes: Bool = false
    @State private var showReason: Bool = false

    init(task: PlannedTask, onSave: @escaping (PlannedTask) -> Void) {
        self.task = task
        self.onSave = onSave

        _title = State(initialValue: task.title)
        _urgency = State(initialValue: task.urgency)
        _notes = State(initialValue: task.notes ?? "")
        _reason = State(initialValue: task.reason ?? "")

        let now = Date()
        let start = DateFormatter.parseTimeString(task.start_time) ?? now
        let end = DateFormatter.parseTimeString(task.end_time) ?? now

        _startTime = State(initialValue: start)
        _endTime = State(initialValue: end)
        _exactTime = State(initialValue: start)

        let duration = Calendar.current.dateComponents([.minute], from: start, to: end).minute ?? 30
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

                    Toggle("Time Sensitive", isOn: $isTimeSensitive)

                    if isTimeSensitive {
                        Picker("Time Type", selection: $timeSensitivityType) {
                            ForEach(TimeSensitivity.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        Group {
                            if timeSensitivityType == .dueBy {
                                DatePicker("Due by", selection: $exactTime, displayedComponents: .hourAndMinute)
                            } else if timeSensitivityType == .startsAt {
                                DatePicker("Starts at", selection: $startTime, displayedComponents: .hourAndMinute)
                            } else if timeSensitivityType == .busyFromTo {
                                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                            }
                        }
                        .id(timeSensitivityType)
                    }

                    Picker("Urgency", selection: $urgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                DisclosureGroup("📝 Notes", isExpanded: $showNotes) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                        .padding(.vertical, 4)
                }

                DisclosureGroup("🤖 AI Reason", isExpanded: $showReason) {
                    TextEditor(text: $reason)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                        .padding(.vertical, 4)
                }

                Section {
                    Button("Save Changes") {
                        saveEdits()
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

    func saveEdits() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.urgency = urgency
        updatedTask.notes = notes.isEmpty ? nil : notes
        updatedTask.reason = reason.isEmpty ? nil : reason

        let totalMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)
        updatedTask.duration = max(totalMinutes, 0)

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        if isTimeSensitive {
            switch timeSensitivityType {
            case .dueBy:
                updatedTask.start_time = formatter.string(from: exactTime)
                updatedTask.end_time = formatter.string(from: exactTime.addingTimeInterval(Double(totalMinutes) * 60))
            case .startsAt:
                updatedTask.start_time = formatter.string(from: startTime)
                updatedTask.end_time = formatter.string(from: startTime.addingTimeInterval(Double(totalMinutes) * 60))
            case .busyFromTo:
                updatedTask.start_time = formatter.string(from: startTime)
                updatedTask.end_time = formatter.string(from: endTime)
            case .none:
                break
            }
        }

        onSave(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }

    func deleteTask() {
        onSave(task)
        presentationMode.wrappedValue.dismiss()
    }
}
