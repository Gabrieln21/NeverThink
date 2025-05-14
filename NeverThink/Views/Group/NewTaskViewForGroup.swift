//
//  NewTaskViewForGroup.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

// View for creating a new task within a specific task group
struct NewTaskViewForGroup: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var preferences: UserPreferencesService
    @Environment(\.presentationMode) var presentationMode

    var groupId: UUID
    @Binding var tasks: [UserTask]

    // Form input states
    @State private var title: String = ""
    @State private var durationHours: String = "0"
    @State private var durationMinutes: String = "30"
    @State private var isTimeSensitive: Bool = false
    @State private var timeSensitivityType: TimeSensitivity = .startsAt
    @State private var exactTime: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urgency: UrgencyLevel = .medium
    @State private var location: String = ""
    @State private var selectedSavedLocationId: UUID? = nil
    @State private var selectedLocationType: LocationType = .home
    @State private var selectedDate: Date = Date() // Date picker value

    // Enum representing different types of location input
    enum LocationType: Identifiable, Hashable {
        case home
        case anywhere
        case saved(UUID)
        case custom

        var id: String {
            switch self {
            case .home: return "home"
            case .anywhere: return "anywhere"
            case .saved(let id): return id.uuidString
            case .custom: return "custom"
            }
        }
    }

    var body: some View {
        ZStack {
            // background gradient
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
                    Text("New Group Task")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    // Task Title
                    Group {
                        Text("Title")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        TextField("Enter task title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Date Picker
                    Group {
                        Text("Date")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        DatePicker("Pick a date for this task", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }

                    // Duration (hours & minutes)
                    Group {
                        Text("Duration")
                            .font(.callout)
                            .foregroundColor(.secondary)
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

                    // Time Sensitivity Section
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

                    // Urgency Level
                    Group {
                        Text("Task Importance")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Picker("", selection: $urgency) {
                            ForEach(UrgencyLevel.allCases, id: \.self) { level in
                                Text(level.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Location Selection
                    Group {
                        Text("Location")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Picker("Location Type", selection: $selectedLocationType) {
                            Text("🏠 Home").tag(LocationType.home)
                            Text("🛫 Anywhere").tag(LocationType.anywhere)
                            ForEach(preferences.commonLocations) { loc in
                                Text(loc.name).tag(LocationType.saved(loc.id))
                            }
                            Text("📍 Custom").tag(LocationType.custom)
                        }
                        .onChange(of: selectedLocationType) { type in
                            // Handle selection change
                            switch type {
                            case .home:
                                location = "Home"
                            case .anywhere:
                                location = "Anywhere"
                            case .saved(let id):
                                if let saved = preferences.commonLocations.first(where: { $0.id == id }) {
                                    location = saved.address
                                    selectedSavedLocationId = id
                                }
                            case .custom:
                                location = ""
                            }
                        }

                        if selectedLocationType == .custom {
                            TextField("Enter Address", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }

                    // Save Button
                    Button(action: saveTask) {
                        Text("Save Task")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(title.isEmpty || (selectedLocationType == .custom && location.isEmpty) ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(title.isEmpty || (selectedLocationType == .custom && location.isEmpty))
                }
                .padding(24)
            }
        }
    }

    // Builds a new `UserTask` and saves it to the selected group
    private func saveTask() {
        var actualExactTime: Date? = nil
        var actualStartTime: Date? = nil
        var actualEndTime: Date? = nil
        var sensitivityTypeForSaving: TimeSensitivity = .startsAt

        // Determine time sensitivity details
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
            default:
                break
            }
        }

        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

        // Construct task object
        let newTask = UserTask(
            id: UUID(),
            title: title,
            duration: totalDurationMinutes,
            isTimeSensitive: isTimeSensitive,
            urgency: urgency,
            isLocationSensitive: selectedLocationType != .home,
            location: {
                switch selectedLocationType {
                case .home: return "Home"
                case .anywhere: return "Anywhere"
                case .custom: return location.isEmpty ? nil : location
                case .saved: return location.isEmpty ? nil : location
                }
            }(),
            category: .doAnywhere,
            timeSensitivityType: sensitivityTypeForSaving,
            exactTime: actualExactTime,
            timeRangeStart: actualStartTime,
            timeRangeEnd: actualEndTime,
            date: selectedDate
        )

        // Save and dismiss
        tasks.append(newTask)
        groupManager.updateTasks(for: groupId, tasks: tasks)
        presentationMode.wrappedValue.dismiss()
    }
}
