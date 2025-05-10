import SwiftUI

struct GeneratedTaskEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var task: UserTask
    var onSave: (UserTask) -> Void

    @State private var durationHours: String = "0"
    @State private var durationMinutes: String = "30"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Info")) {
                    TextField("Title", text: $task.title)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration:")
                        HStack {
                            TextField("Hours", text: $durationHours)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Text("hours")
                            TextField("Minutes", text: $durationMinutes)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Text("minutes")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Importance:")
                        Picker("", selection: $task.urgency) {
                            ForEach(UrgencyLevel.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    DatePicker("Date", selection: Binding(
                        get: { task.date ?? Date() },
                        set: { task.date = $0 }
                    ), displayedComponents: .date)

                    Toggle("Time-sensitive", isOn: $task.isTimeSensitive)

                    if task.isTimeSensitive {
                        Picker("Time Sensitivity", selection: $task.timeSensitivityType) {
                            ForEach(TimeSensitivity.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Group {
                            if task.timeSensitivityType == .dueBy {
                                DatePicker("Due by", selection: Binding(
                                    get: { task.exactTime ?? Date() },
                                    set: { task.exactTime = $0 }
                                ), displayedComponents: .hourAndMinute)
                            } else if task.timeSensitivityType == .startsAt {
                                DatePicker("Starts at", selection: Binding(
                                    get: { task.exactTime ?? Date() },
                                    set: { task.exactTime = $0 }
                                ), displayedComponents: .hourAndMinute)
                            } else if task.timeSensitivityType == .busyFromTo {
                                DatePicker("Start Time", selection: Binding(
                                    get: { task.timeRangeStart ?? Date() },
                                    set: { task.timeRangeStart = $0 }
                                ), displayedComponents: .hourAndMinute)
                                DatePicker("End Time", selection: Binding(
                                    get: { task.timeRangeEnd ?? Date() },
                                    set: { task.timeRangeEnd = $0 }
                                ), displayedComponents: .hourAndMinute)
                            }
                        }
                        .id(task.timeSensitivityType)
                    }
                }

                Section(header: Text("Location")) {
                    Toggle("🏠 At Home?", isOn: Binding(
                        get: { task.isLocationSensitive == false || (task.location ?? "").lowercased() == "home" },
                        set: { isHome in
                            if isHome {
                                task.isLocationSensitive = false
                                task.location = "Home"
                            } else {
                                task.isLocationSensitive = true
                            }
                        }
                    ))

                    if task.isLocationSensitive {
                        Toggle("🛫 Anywhere?", isOn: Binding(
                            get: { (task.location ?? "").lowercased() == "anywhere" },
                            set: { isAnywhere in
                                if isAnywhere {
                                    task.location = "Anywhere"
                                } else if task.location?.lowercased() == "anywhere" {
                                    task.location = nil
                                }
                            }
                        ))

                        if (task.location ?? "").lowercased() != "anywhere" {
                            TextField("Enter Address", text: Binding(
                                get: { task.location ?? "" },
                                set: { task.location = $0 }
                            ))
                        }
                    }
                }

                Section {
                    Button("Save Changes") {
                        saveTask()
                    }
                }
            }
            .navigationTitle("Edit Task")
            .onAppear {
                loadDurationFields()
            }
        }
    }

    private func loadDurationFields() {
        let hours = task.duration / 60
        let minutes = task.duration % 60
        durationHours = "\(hours)"
        durationMinutes = "\(minutes)"
    }

    private func saveTask() {
        let hours = Int(durationHours) ?? 0
        let minutes = Int(durationMinutes) ?? 0
        task.duration = (hours * 60) + minutes

        onSave(task)
        presentationMode.wrappedValue.dismiss()
    }
}
