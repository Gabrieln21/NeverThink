//
//  NewTaskViewForGroup.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

struct NewTaskViewForGroup: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    var groupId: UUID
    @Binding var tasks: [UserTask]

    @State private var title: String = ""
    @State private var duration: Int = 30
    @State private var isTimeSensitive: Bool = false
    @State private var timeSensitivityType: TimeSensitivity = .dueBy
    @State private var exactTime: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urgency: UrgencyLevel = .medium
    @State private var isLocationSensitive: Bool = false
    @State private var location: String = ""
    @State private var category: TaskCategory = .doAnywhere

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)

                Stepper("Duration: \(duration) min", value: $duration, in: 5...240, step: 5)

                Toggle("Time-sensitive", isOn: $isTimeSensitive)

                if isTimeSensitive {
                    Picker("When?", selection: $timeSensitivityType) {
                        ForEach(TimeSensitivity.allCases) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if timeSensitivityType == .dueBy {
                        DatePicker("Due by", selection: $exactTime, displayedComponents: [.hourAndMinute])
                    } else if timeSensitivityType == .startsAt {
                        DatePicker("Starts at", selection: $startTime, displayedComponents: [.hourAndMinute])
                    } else if timeSensitivityType == .busyFromTo {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                    }
                }


                Picker("Urgency", selection: $urgency) {
                    ForEach(UrgencyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            } header: {
                Text("Task Info")
            }

            Section {
                Toggle("Needs location", isOn: $isLocationSensitive)

                if isLocationSensitive {
                    TextField("Enter location", text: $location)
                }

                Picker("Category", selection: $category) {
                    ForEach(TaskCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue)
                    }
                }
            } header: {
                Text("Location")
            }

            Section {
                Button("Save Task") {
                    saveTask()
                }
            }
        }
        .navigationTitle("New Task")
    }

    func saveTask() {
        var actualExactTime: Date? = nil
        var actualStartTime: Date? = nil
        var actualEndTime: Date? = nil
        var sensitivityTypeForSaving: TimeSensitivity = .dueBy

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
            date: nil
        )

        tasks.append(newTask)
        groupManager.updateTasks(for: groupId, tasks: tasks)
        presentationMode.wrappedValue.dismiss()
    }
}
