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
        _endTime = State(initialValue: task.timeRangeEnd ?? Date())
        _urgency = State(initialValue: task.urgency)
        _isAtHome = State(initialValue: task.location == "Home")
        _isAnywhere = State(initialValue: task.location == "Anywhere")
        _location = State(initialValue: task.location ?? "")
        _category = State(initialValue: task.category)
        _recurringInterval = State(initialValue: task.recurringInterval)
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
                    Text("Edit Recurring Task")
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
                                DatePicker("Starts at", selection: $exactTime, displayedComponents: [.hourAndMinute])
                            } else if timeSensitivityType == .busyFromTo {
                                DatePicker("Start Time", selection: $exactTime, displayedComponents: [.hourAndMinute])
                                DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                            }
                        }
                    }

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
                if isAtHome {
                    return "Home"
                } else if isAnywhere {
                    return "Anywhere"
                } else {
                    return location.isEmpty ? nil : location
                }
            }(),
            category: category,
            recurringInterval: recurringInterval,
            selectedWeekdays: originalTask.selectedWeekdays
        )

        recurringManager.updateTask(updatedTask, at: taskIndex)
        presentationMode.wrappedValue.dismiss()
    }
}
