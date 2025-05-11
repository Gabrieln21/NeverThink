import SwiftUI

struct GeneratedTaskEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var task: UserTask
    var onSave: (UserTask) -> Void

    @State private var durationHours: String = "0"
    @State private var durationMinutes: String = "30"

    var body: some View {
        NavigationView {
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
                        Text("Edit Task")
                            .font(.largeTitle.bold())
                            .padding(.top)

                        Group {
                            Text("Title")
                                .font(.callout).foregroundColor(.secondary)
                            TextField("Enter task title", text: $task.title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Group {
                            DatePicker("Date", selection: Binding(
                                get: { task.date ?? Date() },
                                set: { task.date = $0 }
                            ), displayedComponents: .date)
                        }

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

                        Group {
                            Text("Task Importance")
                                .font(.callout).foregroundColor(.secondary)
                            Picker("", selection: $task.urgency) {
                                ForEach(UrgencyLevel.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }


                        Group {
                            Toggle("Time Sensitive", isOn: $task.isTimeSensitive)

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
                                        ), displayedComponents: [.hourAndMinute])
                                    } else if task.timeSensitivityType == .startsAt {
                                        DatePicker("Starts at", selection: Binding(
                                            get: { task.exactTime ?? Date() },
                                            set: { task.exactTime = $0 }
                                        ), displayedComponents: [.hourAndMinute])
                                    } else if task.timeSensitivityType == .busyFromTo {
                                        DatePicker("Start Time", selection: Binding(
                                            get: { task.timeRangeStart ?? Date() },
                                            set: { task.timeRangeStart = $0 }
                                        ), displayedComponents: [.hourAndMinute])
                                        DatePicker("End Time", selection: Binding(
                                            get: { task.timeRangeEnd ?? Date() },
                                            set: { task.timeRangeEnd = $0 }
                                        ), displayedComponents: [.hourAndMinute])
                                    }
                                }
                                .id(task.timeSensitivityType)
                            }
                        }

                        Group {
                            Text("Location")
                                .font(.callout).foregroundColor(.secondary)

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

                        Button(action: saveTask) {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
        }
        .onAppear {
            loadDurationFields()
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
