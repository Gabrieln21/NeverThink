//
//  EditTaskView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

struct EditTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode

    var taskIndex: Int
    var originalTask: UserTask

    @State private var title: String
    @State private var duration: Int
    @State private var isTimeSensitive: Bool
    @State private var timeSensitivityType: TimeSensitivity
    @State private var exactTime: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var urgency: UrgencyLevel
    @State private var isLocationSensitive: Bool
    @State private var location: String
    @State private var category: TaskCategory

    init(taskIndex: Int, task: UserTask) {
        self.taskIndex = taskIndex
        self.originalTask = task

        _title = State(initialValue: task.title)
        _duration = State(initialValue: task.duration)
        _isTimeSensitive = State(initialValue: task.isTimeSensitive)
        _timeSensitivityType = State(initialValue: task.timeSensitivityType)
        _exactTime = State(initialValue: task.exactTime ?? Date())
        _startTime = State(initialValue: task.timeRangeStart ?? Date())
        _endTime = State(initialValue: task.timeRangeEnd ?? Date())
        _urgency = State(initialValue: task.urgency)
        _isLocationSensitive = State(initialValue: task.isLocationSensitive)
        _location = State(initialValue: task.location ?? "")
        _category = State(initialValue: task.category)
    }

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)

                Stepper(value: $duration, in: 5...240, step: 5) {
                    Text("Duration: \(duration) minutes")
                }

                Toggle("Time-sensitive", isOn: $isTimeSensitive)

                if isTimeSensitive {
                    Picker("When?", selection: $timeSensitivityType) {
                        ForEach(TimeSensitivity.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    switch timeSensitivityType {
                    case .dueBy:
                        DatePicker("Due by", selection: $exactTime, displayedComponents: [.hourAndMinute])
                    case .startsAt:
                        DatePicker("Starts at", selection: $exactTime, displayedComponents: [.hourAndMinute])
                    case .busyFromTo:
                        DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                    }
                }

                Picker("Urgency", selection: $urgency) {
                    ForEach(UrgencyLevel.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            } header: {
                Text("Task Info")
            }

            Section {
                Toggle("Needs location", isOn: $isLocationSensitive)

                if isLocationSensitive {
                    TextField("Location", text: $location)
                }

                Picker("Category", selection: $category) {
                    ForEach(TaskCategory.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
            } header: {
                Text("Location")
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
                actualExactTime = exactTime
                updatedSensitivityType = .startsAt
            case .busyFromTo:
                actualStartTime = startTime
                actualEndTime = endTime
                updatedSensitivityType = .busyFromTo
            }
        }

        let updatedTask = UserTask(
            id: originalTask.id,
            title: title,
            duration: duration,
            isTimeSensitive: isTimeSensitive,
            urgency: urgency,
            isLocationSensitive: isLocationSensitive,
            location: isLocationSensitive ? location : nil,
            category: category,
            timeSensitivityType: updatedSensitivityType,
            exactTime: actualExactTime,
            timeRangeStart: actualStartTime,
            timeRangeEnd: actualEndTime,
            date: originalTask.date
        )

        taskManager.tasks[taskIndex] = updatedTask
        presentationMode.wrappedValue.dismiss()
    }
}
