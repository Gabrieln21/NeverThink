import SwiftUI

enum TimeSensitivity: String, CaseIterable, Identifiable, Codable {
    case dueBy = "Due by"
    case startsAt = "Starts at"
    case busyFromTo = "Busy from-to"

    var id: String { self.rawValue }
}

struct NewTaskView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    var targetGroupId: UUID? = nil

    @State private var title: String = ""
    @State private var duration: Int = 30
    @State private var isTimeSensitive: Bool = false
    @State private var timeSensitivityType: TimeSensitivity = .startsAt
    @State private var exactTime: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urgency: UrgencyLevel = .medium

    // 🏠 New Location States
    @State private var isAtHome: Bool = true
    @State private var isAnywhere: Bool = true
    @State private var location: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Info")) {
                    TextField("Title", text: $title)

                    Stepper(value: $duration, in: 5...240, step: 5) {
                        HStack {
                            Image(systemName: "clock")
                            Text("Duration: \(duration) minutes")
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

                    Picker("Urgency", selection: $urgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Location")) {
                    Toggle("🏠 At Home?", isOn: $isAtHome)

                    if !isAtHome {
                        Toggle("🛫 Anywhere?", isOn: $isAnywhere)

                        if !isAnywhere {
                            TextField("Enter address", text: $location)
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
                    .disabled(title.isEmpty || (!isAtHome && !isAnywhere && location.isEmpty)) // 🧠 Prevent saving if required location missing
                }
            }
            .navigationTitle("New Task")
        }
    }

    func saveTask() {
        let now = Date()

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
            }
        }

        let newTask = UserTask(
            id: UUID(),
            title: title,
            duration: duration,
            isTimeSensitive: isTimeSensitive,
            urgency: urgency,
            isLocationSensitive: !isAtHome, // 🏠 Only true if not at home
            location: {
                if isAtHome {
                    return "Home"
                } else if isAnywhere {
                    return "Anywhere"
                } else {
                    return location.isEmpty ? nil : location
                }
            }(),
            category: .doAnywhere, // 🔥 Category stays "do anywhere" — no need for picker anymore
            timeSensitivityType: sensitivityTypeForSaving,
            exactTime: actualExactTime,
            timeRangeStart: actualStartTime,
            timeRangeEnd: actualEndTime,
            date: now
        )

        if let groupId = targetGroupId,
           let groupIndex = groupManager.groups.firstIndex(where: { $0.id == groupId }) {
            groupManager.groups[groupIndex].tasks.append(newTask)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: now)

        if let dateGroupIndex = groupManager.groups.firstIndex(where: { $0.name == dateString }) {
            groupManager.groups[dateGroupIndex].tasks.append(newTask)
        } else {
            let newDateGroup = TaskGroup(name: dateString, tasks: [newTask])
            groupManager.groups.append(newDateGroup)
        }

        presentationMode.wrappedValue.dismiss()
    }
}
