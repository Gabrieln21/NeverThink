//
//  NewReccuringTaskView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//
import SwiftUI

// View for creating a new recurring task
struct NewRecurringTaskView: View {
    @EnvironmentObject var recurringManager: RecurringTaskManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var preferences: UserPreferencesService
    @Environment(\.presentationMode) var presentationMode

    // Task Form State
    @State private var title: String = ""
    @State private var durationHours: String = "0"
    @State private var durationMinutes: String = "0"
    @State private var isTimeSensitive: Bool = false
    @State private var timeSensitivityType: TimeSensitivity = .startsAt
    @State private var exactTime: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var urgency: UrgencyLevel = .medium
    @State private var location: String = ""
    @State private var recurringInterval: RecurringInterval = .daily
    @State private var selectedWeekdays: Set<Int> = []
    @State private var selectedLocationType: LocationType = .home
    @State private var selectedSavedLocationId: UUID? = nil

    // Classifies how the user selected a location
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
            // Background gradient
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
                    Text("New Recurring Task")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    // Title Field
                    Group {
                        Text("Title")
                            .font(.callout).foregroundColor(.secondary)
                        TextField("Enter task title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Duration (in hours/minutes)
                    Group {
                        Text("Duration")
                            .font(.callout).foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            TextField("0", text: $durationHours)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                            Text("hrs")

                            TextField("0", text: $durationMinutes)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                            Text("min")
                        }
                    }

                    // Time Sensitivity Toggle & Pickers
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

                    // Urgency Picker
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

                    // Location Picker + Custom Input
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

                    // Recurrence Picker + Weekly Day Selection
                    Group {
                        Text("Recurring Interval")
                            .font(.callout).foregroundColor(.secondary)
                        Picker("Repeat every:", selection: $recurringInterval) {
                            ForEach(RecurringInterval.allCases) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        // Weekday buttons (only for .weekly)
                        if recurringInterval == .weekly {
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
                            .padding(.top, 4)
                        }
                    }

                    // Save Button
                    Button(action: saveRecurringTask) {
                        Text("Save Recurring Task")
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

    // Persists the new recurring task and generates future tasks from it
    func saveRecurringTask() {
        let totalDurationMinutes = (Int(durationHours) ?? 0) * 60 + (Int(durationMinutes) ?? 0)

        let newRecurringTask = RecurringTask(
            title: title,
            duration: totalDurationMinutes,
            isTimeSensitive: isTimeSensitive,
            timeSensitivityType: timeSensitivityType,
            exactTime: isTimeSensitive && (timeSensitivityType == .startsAt || timeSensitivityType == .dueBy) ? (timeSensitivityType == .startsAt ? startTime : exactTime) : nil,
            timeRangeStart: isTimeSensitive && timeSensitivityType == .busyFromTo ? startTime : nil,
            timeRangeEnd: isTimeSensitive && timeSensitivityType == .busyFromTo ? endTime : nil,
            urgency: urgency,
            location: {
                switch selectedLocationType {
                case .home: return "Home"
                case .anywhere: return "Anywhere"
                case .custom: return location.isEmpty ? nil : location
                case .saved: return location.isEmpty ? nil : location
                }
            }(),
            category: .doAnywhere,
            recurringInterval: recurringInterval,
            selectedWeekdays: recurringInterval == .weekly ? selectedWeekdays : nil
        )
        // Save task to recurring manager and auto-generate future tasks
        recurringManager.addTask(newRecurringTask)
        recurringManager.generateFutureTasks(for: newRecurringTask, into: groupManager)
        
        // Close the view
        presentationMode.wrappedValue.dismiss()
    }
}
