import SwiftUI

enum TimeSensitivity: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case dueBy = "Due by"
    case startsAt = "Starts at"
    case busyFromTo = "Busy from-to"

    var id: String { self.rawValue }
}

struct NewTaskView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode
    
    var targetDate: Date

    var targetGroupId: UUID? = nil

    @State private var title: String = ""
    @State private var durationHours: String = "0"
    @State private var durationMinutes: String = "30"
    @State private var isTimeSensitive: Bool = false
    @State private var timeSensitivityType: TimeSensitivity = .startsAt
    @State private var exactTime: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urgency: UrgencyLevel = .medium

    @State private var isAtHome: Bool = true
    @State private var isAnywhere: Bool = false
    @State private var location: String = ""

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
                                Text(type.rawValue).tag(type)
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
                    Button(action: saveTask) {
                        HStack {
                            Spacer()
                            Text("Save Task")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty || (!isAtHome && !isAnywhere && location.isEmpty))
                }
            }
            .navigationTitle("New Task")
            .onAppear {
                resetTimesToTargetDate()
            }
        }
    }
    
    func resetTimesToTargetDate() {
        let calendar = Calendar.current

        func adjust(_ original: Date) -> Date {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: original)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: targetDate) ?? targetDate
        }

        if !isTimeSensitive {
            return
        }

        if timeSensitivityType == .startsAt {
            startTime = adjust(startTime)
        } else if timeSensitivityType == .dueBy {
            exactTime = adjust(exactTime)
        } else if timeSensitivityType == .busyFromTo {
            startTime = adjust(startTime)
            endTime = adjust(endTime)
        }
    }




    func saveTask() {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: targetDate)

        var actualExactTime: Date? = nil
        var actualStartTime: Date? = nil
        var actualEndTime: Date? = nil
        var sensitivityTypeForSaving: TimeSensitivity = .startsAt

        if isTimeSensitive {
            switch timeSensitivityType {
            case .dueBy:
                actualExactTime = exactTime
                sensitivityTypeForSaving = .dueBy
            case .startsAt:
                actualExactTime = startTime
                sensitivityTypeForSaving = .startsAt
            case .busyFromTo:
                actualStartTime = startTime
                actualEndTime = endTime
                sensitivityTypeForSaving = .busyFromTo
            case .none:
                sensitivityTypeForSaving = .none
            }

        }

        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

        let newTask = UserTask(
            id: UUID(),
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
            category: .doAnywhere,
            timeSensitivityType: sensitivityTypeForSaving,
            exactTime: actualExactTime,
            timeRangeStart: actualStartTime,
            timeRangeEnd: actualEndTime,
            date: normalizedDate
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: normalizedDate)

        if let dateGroupIndex = groupManager.groups.firstIndex(where: { $0.name == dateString }) {
            groupManager.groups[dateGroupIndex].tasks.append(newTask)
        } else {
            let newDateGroup = TaskGroup(name: dateString, tasks: [newTask])
            groupManager.groups.append(newDateGroup)
        }

        presentationMode.wrappedValue.dismiss()
    }

}
