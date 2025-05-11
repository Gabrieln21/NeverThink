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
        _startTime = State(initialValue: {
            switch task.timeSensitivityType {
            case .startsAt:
                return task.exactTime ?? Date()
            case .busyFromTo:
                return task.timeRangeStart ?? Date()
            default:
                return Date()
            }
        }())
        _endTime = State(initialValue: task.timeRangeEnd ?? Date())
        _urgency = State(initialValue: task.urgency)
        _isAtHome = State(initialValue: task.location == "Home")
        _isAnywhere = State(initialValue: task.location == "Anywhere")
        _location = State(initialValue: task.location ?? "")
        _category = State(initialValue: task.category)
    }

    var body: some View {
        ZStack {
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
                    Text("Edit Task")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    Group {
                        Text("Title")
                            .font(.callout).foregroundColor(.secondary)
                        TextField("Enter task title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

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

                    Group {
                        Toggle("Time Sensitive", isOn: $isTimeSensitive)

                        if isTimeSensitive {
                            Picker("Time Sensitivity", selection: $timeSensitivityType) {
                                ForEach(TimeSensitivity.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

                            if timeSensitivityType == .dueBy {
                                DatePicker("Due by", selection: $exactTime, displayedComponents: [.hourAndMinute])
                            } else if timeSensitivityType == .startsAt {
                                DatePicker("Starts at", selection: $startTime, displayedComponents: [.hourAndMinute])
                            } else if timeSensitivityType == .busyFromTo {
                                DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                                DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                            }
                        }
                    }

                    Group {
                        Text("Task Importance")
                            .font(.callout).foregroundColor(.secondary)
                        Picker("", selection: $urgency) {
                            ForEach(UrgencyLevel.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    Group {
                        Text("Location")
                            .font(.callout).foregroundColor(.secondary)

                        Toggle("🏠 At Home?", isOn: $isAtHome)

                        if !isAtHome {
                            Toggle("🛫 Anywhere?", isOn: $isAnywhere)

                            if !isAnywhere {
                                TextField("Enter Address", text: $location)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }

                    Button(action: saveEdits) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(title.isEmpty || (!isAtHome && !isAnywhere && location.isEmpty) ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(title.isEmpty || (!isAtHome && !isAnywhere && location.isEmpty))
                }
                .padding(24)
            }
        }
    }

    func saveEdits() {
        var actualExactTime: Date? = nil
        var actualStartTime: Date? = nil
        var actualEndTime: Date? = nil
        var updatedSensitivityType: TimeSensitivity = .none

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
            case .none:
                updatedSensitivityType = .none
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

        if let groupIndex = groupManager.groups.firstIndex(where: { group in
            group.tasks.contains(where: { $0.id == originalTask.id })
        }),
           let taskIndexInGroup = groupManager.groups[groupIndex].tasks.firstIndex(where: { $0.id == originalTask.id }) {
            groupManager.groups[groupIndex].tasks[taskIndexInGroup] = updatedTask
        }

        presentationMode.wrappedValue.dismiss()
    }
}
