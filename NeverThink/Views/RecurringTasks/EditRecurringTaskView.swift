import SwiftUI

struct EditRecurringTaskView: View {
    @EnvironmentObject var recurringManager: RecurringTaskManager
    @Environment(\.presentationMode) var presentationMode

    var taskIndex: Int
    var originalTask: RecurringTask

    @State private var title: String
    @State private var durationHours: String
    @State private var durationMinutes: String
    @State private var isTimeSensitive: Bool
    @State private var timeSensitivityType: TimeSensitivity
    @State private var exactTime: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var urgency: UrgencyLevel
    @State private var isAtHome: Bool
    @State private var isAnywhere: Bool
    @State private var location: String
    @State private var category: TaskCategory
    @State private var recurringInterval: RecurringInterval

    init(taskIndex: Int, task: RecurringTask) {
        self.taskIndex = taskIndex
        self.originalTask = task

        _title = State(initialValue: task.title)
        _durationHours = State(initialValue: "\(task.duration / 60)")
        _durationMinutes = State(initialValue: "\(task.duration % 60)")
        _isTimeSensitive = State(initialValue: task.isTimeSensitive)
        _timeSensitivityType = State(initialValue: task.timeSensitivityType)
        _exactTime = State(initialValue: task.exactTime ?? Date())
        _startTime = State(initialValue: task.timeRangeStart ?? Date())
        _endTime = State(initialValue: task.timeRangeEnd ?? Date())
        _urgency = State(initialValue: task.urgency)
        _isAtHome = State(initialValue: task.location == "Home")
        _isAnywhere = State(initialValue: task.location == "Anywhere")
        _location = State(initialValue: task.location ?? "")
        _category = State(initialValue: task.category)
        _recurringInterval = State(initialValue: task.recurringInterval)
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

                    Toggle("Time-sensitive", isOn: $isTimeSensitive)

                    if isTimeSensitive {
                        Picker("Time Sensitivity", selection: $timeSensitivityType) {
                            ForEach(TimeSensitivity.allCases) { type in
                                Text(type.rawValue)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Group {
                            if timeSensitivityType == .dueBy {
                                DatePicker("Due by", selection: $exactTime, displayedComponents: [.hourAndMinute])
                            } else if timeSensitivityType == .startsAt {
                                DatePicker("Starts at", selection: $startTime, displayedComponents: [.hourAndMinute])
                            } else if timeSensitivityType == .busyFromTo {
                                DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                                DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                            }
                        }
                        .id(timeSensitivityType)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Importance:")
                        Picker("", selection: $urgency) {
                            ForEach(UrgencyLevel.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                Section(header: Text("Location")) {
                    Toggle("🏠 At Home?", isOn: $isAtHome)

                    if !isAtHome {
                        Toggle("🛫 Anywhere?", isOn: $isAnywhere)

                        if !isAnywhere {
                            TextField("Enter Address", text: $location)
                        }
                    }
                }

                Section(header: Text("Recurrence")) {
                    Picker("Repeats", selection: $recurringInterval) {
                        ForEach(RecurringInterval.allCases) { interval in
                            Text(interval.rawValue)
                                .tag(interval)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Button("Save Changes") {
                        saveEdits()
                    }
                    .fontWeight(.bold)
                }
            }
            .navigationTitle("Edit Recurring Task")
        }
    }

    func saveEdits() {
        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

        let updatedTask = RecurringTask(
            id: originalTask.id,
            title: title,
            duration: totalDurationMinutes,
            isTimeSensitive: isTimeSensitive,
            timeSensitivityType: timeSensitivityType,
            exactTime: isTimeSensitive ? exactTime : nil,
            timeRangeStart: isTimeSensitive ? startTime : nil,
            timeRangeEnd: isTimeSensitive ? endTime : nil,
            urgency: urgency,
            location: {
                if isAtHome {
                    return "Home"
                } else if isAnywhere {
                    return "Anywhere"
                } else {
                    return location.isEmpty ? nil : location
                }
            }(),
            category: category,
            recurringInterval: recurringInterval
        )

        recurringManager.updateTask(updatedTask, at: taskIndex)
        presentationMode.wrappedValue.dismiss()
    }
}
