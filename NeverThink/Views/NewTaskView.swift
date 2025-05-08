//
//  NewTaskView.swift
//  NeverThink
//

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
    @State private var timeSensitivityType: TimeSensitivity = .startsAt // 🧠 STARTS AT SELECTED BY DEFAULT
    @State private var exactTime: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urgency: UrgencyLevel = .medium
    @State private var isLocationSensitive: Bool = false
    @State private var location: String = ""
    @State private var category: TaskCategory = .doAnywhere

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
                    Toggle("Needs location", isOn: $isLocationSensitive)

                    if isLocationSensitive {
                        TextField("Enter location", text: $location)
                    }

                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue)
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
                    .disabled(title.isEmpty)
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
            isLocationSensitive: isLocationSensitive,
            location: isLocationSensitive ? location : nil,
            category: category,
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
