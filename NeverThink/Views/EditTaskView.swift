import SwiftUI

struct EditTaskView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    var taskIndex: Int
    var originalTask: UserTask

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

    init(taskIndex: Int, task: UserTask) {
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

                Section {
                    Button("Save Changes") {
                        saveEdits()
                    }
                    .fontWeight(.bold)
                }
            }
            .navigationTitle("Edit Task")
        }
    }

    func saveEdits() {
        var actualExactTime: Date? = nil
        var actualStartTime: Date? = nil
        var actualEndTime: Date? = nil
        var updatedSensitivityType: TimeSensitivity = .dueBy

        if isTimeSensitive {
            switch timeSensitivityType {
            case .dueBy:
                actualExactTime = exactTime
                updatedSensitivityType = .dueBy
            case .startsAt:
                actualExactTime = startTime
                updatedSensitivityType = .startsAt
            case .busyFromTo:
                actualStartTime = startTime
                actualEndTime = endTime
                updatedSensitivityType = .busyFromTo
            }
        }

        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

        let updatedTask = UserTask(
            id: originalTask.id,
            title: title,
            duration: totalDurationMinutes,
            isTimeSensitive: isTimeSensitive,
            urgency: urgency,
            isLocationSensitive: !isAtHome,
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
            timeSensitivityType: updatedSensitivityType,
            exactTime: actualExactTime,
            timeRangeStart: actualStartTime,
            timeRangeEnd: actualEndTime,
            date: originalTask.date
        )

        if let todayGroupIndex = groupManager.groups.firstIndex(where: { group in
            group.tasks.contains(where: { $0.id == originalTask.id })
        }),
           let taskIndexInGroup = groupManager.groups[todayGroupIndex].tasks.firstIndex(where: { $0.id == originalTask.id }) {
            groupManager.groups[todayGroupIndex].tasks[taskIndexInGroup] = updatedTask
        }

        presentationMode.wrappedValue.dismiss()
    }
}
