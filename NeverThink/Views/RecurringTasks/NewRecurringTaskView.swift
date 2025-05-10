import SwiftUI

struct NewRecurringTaskView: View {
    @EnvironmentObject var recurringManager: RecurringTaskManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var durationHours: String = "0"
    @State private var durationMinutes: String = "0"
    @State private var isTimeSensitive: Bool = false
    @State private var timeSensitivityType: TimeSensitivity = .startsAt
    @State private var exactTime: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urgency: UrgencyLevel = .medium
    @State private var isAtHome: Bool = true
    @State private var isAnywhere: Bool = true
    @State private var location: String = ""
    @State private var recurringInterval: RecurringInterval = .daily

    // 🆕 New for Weekly Selection
    @State private var selectedWeekdays: Set<Int> = []

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

                Section(header: Text("Recurring Interval")) {
                    Picker("Repeat every:", selection: $recurringInterval) {
                        ForEach(RecurringInterval.allCases) { interval in
                            Text(interval.rawValue)
                                .tag(interval)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    // Show weekday picker if Weekly
                    if recurringInterval == .weekly {
                        VStack {
                            HStack {
                                ForEach(0..<7, id: \.self) { index in
                                    let letters = ["S", "M", "T", "W", "T", "F", "S"]

                                    Button(action: {
                                        if selectedWeekdays.contains(index) {
                                            selectedWeekdays.remove(index)
                                        } else {
                                            selectedWeekdays.insert(index)
                                        }
                                    }) {
                                        Text(letters[index])
                                            .font(.headline)
                                            .frame(width: 32, height: 32)
                                            .background(selectedWeekdays.contains(index) ? Color.blue : Color.clear)
                                            .foregroundColor(selectedWeekdays.contains(index) ? .white : .blue)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.blue, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                        }
                        .padding(.top)
                    }
                }

                Section {
                    Button("Save Recurring Task") {
                        saveRecurringTask()
                    }
                    .fontWeight(.bold)
                }
            }
            .navigationTitle("New Recurring Task")
        }
    }

    func saveRecurringTask() {
        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

        let newRecurringTask = RecurringTask(
            title: title,
            duration: totalDurationMinutes,
            isTimeSensitive: isTimeSensitive,
            timeSensitivityType: timeSensitivityType,
            exactTime: isTimeSensitive ? (timeSensitivityType == .dueBy ? exactTime : nil) : nil,
            timeRangeStart: isTimeSensitive ? (timeSensitivityType == .busyFromTo ? startTime : nil) : nil,
            timeRangeEnd: isTimeSensitive ? (timeSensitivityType == .busyFromTo ? endTime : nil) : nil,
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
            category: .doAnywhere,
            recurringInterval: recurringInterval,
            selectedWeekdays: recurringInterval == .weekly ? selectedWeekdays : nil,
            startTime: isTimeSensitive ? (timeSensitivityType == .startsAt ? startTime : nil) : nil 
        )



        recurringManager.addTask(newRecurringTask)
        recurringManager.generateFutureTasks(for: newRecurringTask, into: groupManager)
        presentationMode.wrappedValue.dismiss()
    }
}
