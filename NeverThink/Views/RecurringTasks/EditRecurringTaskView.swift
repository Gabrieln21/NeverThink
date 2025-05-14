//
//  EditReccuringTaskView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//
import SwiftUI

// View for editing an existing recurring task.
struct EditRecurringTaskView: View {
    @EnvironmentObject var recurringManager: RecurringTaskManager
    @EnvironmentObject var preferences: UserPreferencesService

    @Environment(\.presentationMode) var presentationMode

    var taskIndex: Int
    var originalTask: RecurringTask

    // Editable Fields
    @State private var title: String
    @State private var durationHours: String
    @State private var durationMinutes: String
    @State private var isTimeSensitive: Bool
    @State private var timeSensitivityType: TimeSensitivity
    @State private var exactTime: Date
    @State private var endTime: Date
    @State private var urgency: UrgencyLevel
    @State private var location: String
    @State private var category: TaskCategory
    @State private var recurringInterval: RecurringInterval
    @State private var selectedSavedLocationId: UUID? = nil
    @State private var selectedLocationType: LocationType = .custom

    // categorize how the location was selected
    enum LocationType: Identifiable, Hashable {
        case home
        case anywhere
        case saved(UUID)
        case custom

        var id: String {
            switch self {
            case .home: return "home"
            case .anywhere: return "anywhere"
            case .saved(let id): return id.uuidString
            case .custom: return "custom"
            }
        }
    }

    // Initializes the form with the original task values
    init(taskIndex: Int, task: RecurringTask) {
        self.taskIndex = taskIndex
        self.originalTask = task

        _title = State(initialValue: task.title)
        _durationHours = State(initialValue: "\(task.duration / 60)")
        _durationMinutes = State(initialValue: "\(task.duration % 60)")
        _isTimeSensitive = State(initialValue: task.isTimeSensitive)
        _timeSensitivityType = State(initialValue: task.timeSensitivityType)
        _exactTime = State(initialValue: task.exactTime ?? Date())
        _endTime = State(initialValue: task.timeRangeEnd ?? Date())
        _urgency = State(initialValue: task.urgency)
        _category = State(initialValue: task.category)
        _recurringInterval = State(initialValue: task.recurringInterval)
        _location = State(initialValue: task.location ?? "")

        // Match saved location types
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
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.85, green: 0.9, blue: 1.0),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Edit Recurring Task")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    // Title input
                    Group {
                        Text("Title")
                            .font(.callout).foregroundColor(.secondary)
                        TextField("Enter task title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    // Duration input
                    Group {
                        Text("Duration")
                            .font(.callout).foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            TextField("0", text: $durationHours)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                            Text("hrs")

                            TextField("30", text: $durationMinutes)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                            Text("min")
                        }
                    }
                    // Time sensitivity section
                    Group {
                        Toggle("Time Sensitive", isOn: $isTimeSensitive)

                        if isTimeSensitive {
                            Picker("Time Sensitivity", selection: $timeSensitivityType) {
                                ForEach(TimeSensitivity.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            // Display relevant date pickers
                            if timeSensitivityType == .dueBy {
                                DatePicker("Due by", selection: $exactTime, displayedComponents: [.hourAndMinute])
                            } else if timeSensitivityType == .startsAt {
                                DatePicker("Starts at", selection: $exactTime, displayedComponents: [.hourAndMinute])
                            } else if timeSensitivityType == .busyFromTo {
                                DatePicker("Start Time", selection: $exactTime, displayedComponents: [.hourAndMinute])
                                DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                            }
                        }
                    }

                    // Urgency picker
                    Group {
                        Text("Urgency")
                            .font(.callout).foregroundColor(.secondary)
                        Picker("", selection: $urgency) {
                            ForEach(UrgencyLevel.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // Urgency picker
                    Group {
                        Text("Location")
                            .font(.callout).foregroundColor(.secondary)

                        Picker("Location Type", selection: $selectedLocationType) {
                            Text("🏠 Home").tag(LocationType.home)
                            Text("🛫 Anywhere").tag(LocationType.anywhere)
                            ForEach(preferences.commonLocations) { loc in
                                Text(loc.name).tag(LocationType.saved(loc.id))
                            }
                            Text("📍 Custom").tag(LocationType.custom)
                        }
                        .onChange(of: selectedLocationType) { type in
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
                        // Custom location input field
                        if selectedLocationType == .custom {
                            TextField("Enter Address", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Recurrence interval picker
                    Group {
                        Text("Recurrence")
                            .font(.callout).foregroundColor(.secondary)

                        Picker("Repeats", selection: $recurringInterval) {
                            ForEach(RecurringInterval.allCases) { interval in
                                Text(interval.rawValue)
                                    .tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Save button
                    Button(action: saveEdits) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(title.isEmpty || (selectedLocationType == .custom && location.isEmpty) ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(title.isEmpty || (selectedLocationType == .custom && location.isEmpty))
                }
                .padding(24)
            }
        }
    }
    
    // Saves the user's edits back to the recurring task list.
    func saveEdits() {
        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

        let updatedTask = RecurringTask(
            id: originalTask.id,
            title: title,
            duration: totalDurationMinutes,
            isTimeSensitive: isTimeSensitive,
            timeSensitivityType: timeSensitivityType,
            exactTime: isTimeSensitive && (timeSensitivityType == .startsAt || timeSensitivityType == .dueBy)
                ? exactTime : nil,
            timeRangeStart: isTimeSensitive && timeSensitivityType == .busyFromTo ? exactTime : nil,
            timeRangeEnd: isTimeSensitive && timeSensitivityType == .busyFromTo ? endTime : nil,
            urgency: urgency,
            location: {
                switch selectedLocationType {
                case .home: return "Home"
                case .anywhere: return "Anywhere"
                case .custom: return location.isEmpty ? nil : location
                case .saved: return location.isEmpty ? nil : location
                }
            }(),
            category: category,
            recurringInterval: recurringInterval,
            selectedWeekdays: originalTask.selectedWeekdays // Keep same weekdays
        )

        recurringManager.updateTask(updatedTask, at: taskIndex)
        presentationMode.wrappedValue.dismiss()
    }
}
