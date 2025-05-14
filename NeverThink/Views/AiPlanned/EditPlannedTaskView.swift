//
//  EditPlannedTaskView.swift
//  NeverThink
//

import SwiftUI

// A view for editing the properties of a PlannedTask, including time, duration, urgency, and location.
struct EditPlannedTaskView: View {
    @EnvironmentObject var preferences: UserPreferencesService
    @Environment(\.presentationMode) var presentationMode

    @State var task: PlannedTask
    var onSave: (PlannedTask) -> Void

    // Editable fields for task properties
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

    @State private var location: String = ""
    @State private var selectedSavedLocationId: UUID? = nil
    @State private var selectedLocationType: LocationType = .custom

    @State private var showNotes: Bool = false
    @State private var showReason: Bool = false

    // Enum to represent user’s location selection style
    enum LocationType: Identifiable, Hashable {
        case home, anywhere, saved(UUID), custom

        var id: String {
            switch self {
            case .home: return "home"
            case .anywhere: return "anywhere"
            case .saved(let id): return id.uuidString
            case .custom: return "custom"
            }
        }
    }

    // Initializes the edit view with default state
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
        _location = State(initialValue: task.location ?? "")

        // Auto-detect location type based on value
        if task.location == "Home" {
            _selectedLocationType = State(initialValue: .home)
        } else if task.location == "Anywhere" {
            _selectedLocationType = State(initialValue: .anywhere)
        } else if let match = UserPreferencesService().commonLocations.first(where: { $0.address == task.location }) {
            _selectedLocationType = State(initialValue: .saved(match.id))
            _selectedSavedLocationId = State(initialValue: match.id)
        } else {
            _selectedLocationType = State(initialValue: .custom)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Basic task info
                Section(header: Text("Task Info")) {
                    TextField("Title", text: $title)

                    // Duration input
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

                    // If task is time-sensitive, allow type and time input
                    if isTimeSensitive {
                        Picker("Time Type", selection: $timeSensitivityType) {
                            ForEach(TimeSensitivity.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Dynamic time inputs based on sensitivity type
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

                    // Urgency selection
                    Picker("Urgency", selection: $urgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Location management section
                Section(header: Text("Location")) {
                    Picker("Location Type", selection: $selectedLocationType) {
                        Text("🏠 Home").tag(LocationType.home)
                        Text("🛫 Anywhere").tag(LocationType.anywhere)
                        ForEach(preferences.commonLocations) { loc in
                            Text(loc.name).tag(LocationType.saved(loc.id))
                        }
                        Text("📍 Custom").tag(LocationType.custom)
                    }
                    .onChange(of: selectedLocationType) { type in
                        // Update bound location field when picker changes
                        switch type {
                        case .home:
                            location = "Home"
                        case .anywhere:
                            location = "Anywhere"
                        case .saved(let id):
                            if let saved = preferences.commonLocations.first(where: { $0.id == id }) {
                                location = saved.address
                                selectedSavedLocationId = id
                            }
                        case .custom:
                            location = ""
                        }
                    }

                    if selectedLocationType == .custom {
                        TextField("Enter Address", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                // Optional notes and reasoning fields
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

                // Save/delete buttons
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

    // Apply current state to task and pass result back to parent
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

        updatedTask.location = {
            switch selectedLocationType {
            case .home: return "Home"
            case .anywhere: return "Anywhere"
            case .custom, .saved: return location.isEmpty ? nil : location
            }
        }()

        onSave(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }

    // Cancel editing and return original task
    func deleteTask() {
        onSave(task)
        presentationMode.wrappedValue.dismiss()
    }
}
