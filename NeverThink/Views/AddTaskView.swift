//
//  AddTaskView.swift
//  NeverThink
//

import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    @State private var title = ""
    @State private var duration = 30
    @State private var selectedDate = Date()
    @State private var isTimeSensitive = false
    @State private var timeSensitivityType: TimeSensitivity = .dueBy
    @State private var exactTime = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()

    // Custom initializer to prefill the date
    init(selectedDate: Date?) {
        _selectedDate = State(initialValue: selectedDate ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Info")) {
                    TextField("Title", text: $title)

                    Stepper("Duration: \(duration) minutes", value: $duration, in: 5...240, step: 5)

                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])

                    Toggle("Time-sensitive", isOn: $isTimeSensitive)

                    if isTimeSensitive {
                        Picker("When?", selection: $timeSensitivityType) {
                            ForEach(TimeSensitivity.allCases) { type in
                                Text(type.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        switch timeSensitivityType {
                        case .dueBy:
                            DatePicker("Due by", selection: $exactTime, displayedComponents: [.hourAndMinute])
                        case .startsAt:
                            DatePicker("Starts at", selection: $startTime, displayedComponents: [.hourAndMinute])
                        case .busyFromTo:
                            DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                            DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                        case .none:
                            EmptyView()
                        }

                    }
                }

                Section {
                    Button("Save Task") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add New Task")
        }
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
            case .none:
                sensitivityTypeForSaving = .none
            }

        }

        let newTask = UserTask(
            title: title,
            duration: duration,
            isTimeSensitive: isTimeSensitive,
            urgency: .medium,
            isLocationSensitive: false,
            location: nil,
            category: .doAnywhere,
            timeSensitivityType: sensitivityTypeForSaving,
            exactTime: actualExactTime,
            timeRangeStart: actualStartTime,
            timeRangeEnd: actualEndTime,
            date: selectedDate
        )

        groupManager.addTask(newTask)
        presentationMode.wrappedValue.dismiss()
    }
}
