import SwiftUI

struct NewTaskViewForGroup: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var preferences: UserPreferencesService
    @Environment(\.presentationMode) var presentationMode

    var groupId: UUID
    @Binding var tasks: [UserTask]

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
    @State private var selectedDate: Date = Date()

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

                    Group {
                        Text("Title")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        TextField("Enter task title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    Group {
                        Text("Date")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        DatePicker("Pick a date for this task", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }

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

    private func saveTask() {
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
            default:
                break
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
            date: selectedDate
        )

        tasks.append(newTask)
        groupManager.updateTasks(for: groupId, tasks: tasks)
        presentationMode.wrappedValue.dismiss()
    }
}
