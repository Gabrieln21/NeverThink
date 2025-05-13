//
//  RescheduelFormView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/02/25.
//
import SwiftUI

struct RescheduleFormView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var preferences: UserPreferencesService
    @Environment(\..presentationMode) var presentationMode

    @Binding var rescheduleQueue: [UserTask]
    var task: UserTask

    @State private var newTitle: String
    @State private var newDate: Date
    @State private var newTime: Date?
    @State private var urgency: UrgencyLevel
    @State private var location: String
    @State private var selectedLocationType: LocationType = .home
    @State private var selectedSavedLocationId: UUID? = nil

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

    init(task: UserTask, rescheduleQueue: Binding<[UserTask]>) {
        self.task = task
        self._rescheduleQueue = rescheduleQueue

        _newTitle = State(initialValue: task.title)
        _newDate = State(initialValue: task.date ?? Date())
        _newTime = State(initialValue: task.exactTime)
        _urgency = State(initialValue: task.urgency)
        _location = State(initialValue: task.location ?? "")

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

                        Group {
                            Text("Task Title")
                                .font(.callout).foregroundColor(.secondary)

                            TextField("Enter task title", text: $newTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Group {
                            Text("New Date")
                                .font(.callout).foregroundColor(.secondary)

                            DatePicker("Select Date", selection: $newDate, displayedComponents: .date)
                                .labelsHidden()
                        }

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

                        Group {
                            Text("Location")
                                .font(.callout).foregroundColor(.secondary)

                            Picker("Location Type", selection: $selectedLocationType) {
                                Text("\u{1F3E0} Home").tag(LocationType.home)
                                Text("\u{1F6EB} Anywhere").tag(LocationType.anywhere)
                                ForEach(preferences.commonLocations) { loc in
                                    Text(loc.name).tag(LocationType.saved(loc.id))
                                }
                                Text("\u{1F4CD} Custom").tag(LocationType.custom)
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

        if let groupIndex = groupManager.groups.firstIndex(where: {
            $0.tasks.contains(where: { $0.id == task.id })
        }),
        let taskIndex = groupManager.groups[groupIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            groupManager.groups[groupIndex].tasks[taskIndex] = updatedTask
            groupManager.saveToDisk()
        } else {
            groupManager.addTask(updatedTask)
        }

        rescheduleQueue.removeAll { $0.id == task.id }

        presentationMode.wrappedValue.dismiss()
    }
}
