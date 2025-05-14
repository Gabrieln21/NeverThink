//
//  NewTaskView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

// Defines the type of time sensitivity a task can have
enum TimeSensitivity: String, CaseIterable, Identifiable, Codable {
    case none = "none"
    case dueBy = "dueBy"
    case startsAt = "startsAt"
    case busyFromTo = "busyFromTo"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .dueBy: return "Due by"
        case .startsAt: return "Starts at"
        case .busyFromTo: return "Busy from-to"
        }
    }
}

// View for creating and saving a new task into a group
struct NewTaskView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var preferences: UserPreferencesService
    @Environment(\.presentationMode) var presentationMode

    var targetDate: Date
    var targetGroupId: UUID? = nil

    // Task input fields
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
    @State private var selectedLocationType: LocationType = .home
    @State private var selectedSavedLocationId: UUID? = nil

    // Represents different types of locations the user can select
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
            // Gradient background
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
                    Text("New Task")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    // Title input
                    Group {
                        Text("Title")
                            .font(.callout).foregroundColor(.secondary)
                        TextField("Enter task title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Duration input
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

                    // Time sensitivity toggle and options
                    Group {
                        Toggle("Time Sensitive", isOn: $isTimeSensitive)

                        if isTimeSensitive {
                            Picker("Time Sensitivity", selection: $timeSensitivityType) {
                                ForEach(TimeSensitivity.allCases) { type in
                                    Text(type.displayName).tag(type)
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

                    // Urgency selection
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

                    // Location picker
                    Group {
                        Text("Location")
                            .font(.callout).foregroundColor(.secondary)

                        Picker("Location Type", selection: $selectedLocationType) {
                            Text("🏠 Home").tag(LocationType.home)
                            Text("🛫 Anywhere").tag(LocationType.anywhere)
                            ForEach(preferences.commonLocations) { loc in
                                Text(loc.name).tag(LocationType.saved(loc.id))
                            }
                            Text("📍 Custom").tag(LocationType.custom)
                        }
                        .onChange(of: selectedLocationType) { type in
                            switch type {
                            case .home:
                                location = "Home"
                            case .anywhere:
                                location = "Anywhere"
                            case .saved(let id):
                                if let saved = preferences.commonLocations.first(where: { $0.id == id }) {
                                    location = saved.address
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

                    // Save task button
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
        .onAppear {
            resetTimesToTargetDate()
        }
    }

    // Adjusts the selected time values to align with the `targetDate`
    private func resetTimesToTargetDate() {
        let calendar = Calendar.current

        func adjust(_ original: Date) -> Date {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: original)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: targetDate) ?? targetDate
        }

        if !isTimeSensitive { return }

        switch timeSensitivityType {
        case .startsAt:
            startTime = adjust(startTime)
        case .dueBy:
            exactTime = adjust(exactTime)
        case .busyFromTo:
            startTime = adjust(startTime)
            endTime = adjust(endTime)
        default: break
        }
    }

    // Constructs a UserTask and saves it to the group manager
    private func saveTask() {
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
            default: break
            }
        }

        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

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
            date: normalizedDate
        )

        groupManager.addTask(newTask)
        presentationMode.wrappedValue.dismiss()
    }
}
