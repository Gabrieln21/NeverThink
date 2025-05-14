//
//  RescheduelFormView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/02/25.
//

import SwiftUI

// A form view for manually updating/rescheduling a task’s properties like time, date, location, and urgency.
struct RescheduleFormView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var preferences: UserPreferencesService
    @Environment(\.presentationMode) var presentationMode

    @Binding var rescheduleQueue: [UserTask]
    var task: UserTask

    // Editable state properties
    @State private var newTitle: String
    @State private var newDate: Date
    @State private var newTime: Date?
    @State private var urgency: UrgencyLevel
    @State private var location: String
    @State private var selectedLocationType: LocationType = .home
    @State private var selectedSavedLocationId: UUID? = nil

    // Enum for tracking which type of location the user selects
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

    // Initializes the form state based on the passed-in task
    init(task: UserTask, rescheduleQueue: Binding<[UserTask]>) {
        self.task = task
        self._rescheduleQueue = rescheduleQueue

        _newTitle = State(initialValue: task.title)
        _newDate = State(initialValue: task.date ?? Date())
        _newTime = State(initialValue: task.exactTime)
        _urgency = State(initialValue: task.urgency)
        _location = State(initialValue: task.location ?? "")

        // location type from stored value
        if task.location == "Home" {
            _selectedLocationType = State(initialValue: .home)
        } else if task.location == "Anywhere" {
            _selectedLocationType = State(initialValue: .anywhere)
        } else if let match = preferences.commonLocations.first(where: { $0.address == task.location }) {
            _selectedLocationType = State(initialValue: .saved(match.id))
            _selectedSavedLocationId = State(initialValue: match.id)
        } else {
            _selectedLocationType = State(initialValue: .custom)
        }
    }

    var body: some View {
        NavigationStack {
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
                        Text("Reschedule Task")
                            .font(.largeTitle.bold())
                            .padding(.top)

                        // Title input
                        Group {
                            Text("Task Title")
                                .font(.callout).foregroundColor(.secondary)

                            TextField("Enter task title", text: $newTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // Date picker
                        Group {
                            Text("New Date")
                                .font(.callout).foregroundColor(.secondary)

                            DatePicker("Select Date", selection: $newDate, displayedComponents: .date)
                                .labelsHidden()
                        }

                        // Optional time picker
                        Group {
                            Text("Optional Time")
                                .font(.callout).foregroundColor(.secondary)

                            DatePicker(
                                "Select Time",
                                selection: Binding(
                                    get: { newTime ?? Date() },
                                    set: { newTime = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }

                        // Urgency selector
                        Group {
                            Text("Urgency")
                                .font(.callout).foregroundColor(.secondary)

                            Picker("", selection: $urgency) {
                                ForEach(UrgencyLevel.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        // Location selector
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

                            // Custom location text field
                            if selectedLocationType == .custom {
                                TextField("Enter Address", text: $location)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }

                        // Action buttons
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)

                            Button("Save Changes") {
                                saveChanges()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Reschedule Task")
        }
    }

    // Applies the updated fields to the original task and saves them
    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = newTitle
        updatedTask.date = newDate
        updatedTask.exactTime = newTime
        updatedTask.isLocationSensitive = selectedLocationType != .home
        updatedTask.location = {
            switch selectedLocationType {
            case .home: return "Home"
            case .anywhere: return "Anywhere"
            case .custom: return location.isEmpty ? nil : location
            case .saved: return location.isEmpty ? nil : location
            }
        }()
        updatedTask.urgency = urgency

        // Update the task if it already exists in a group, otherwise add it
        if let groupIndex = groupManager.groups.firstIndex(where: {
            $0.tasks.contains(where: { $0.id == task.id })
        }),
        let taskIndex = groupManager.groups[groupIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            groupManager.groups[groupIndex].tasks[taskIndex] = updatedTask
            groupManager.saveToDisk()
        } else {
            groupManager.addTask(updatedTask)
        }

        // Remove from reschedule queue
        rescheduleQueue.removeAll { $0.id == task.id }

        // Dismiss the form
        presentationMode.wrappedValue.dismiss()
    }
}
