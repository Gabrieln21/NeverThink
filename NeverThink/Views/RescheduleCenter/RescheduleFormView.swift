import SwiftUI

struct RescheduleFormView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    @Binding var rescheduleQueue: [UserTask]
    var task: UserTask

    @State private var newTitle: String
    @State private var newDate: Date
    @State private var newTime: Date?
    @State private var urgency: UrgencyLevel

    init(task: UserTask, rescheduleQueue: Binding<[UserTask]>) {
        self.task = task
        self._rescheduleQueue = rescheduleQueue

        _newTitle = State(initialValue: task.title)
        _newDate = State(initialValue: task.date ?? Date())
        _newTime = State(initialValue: task.exactTime)
        _urgency = State(initialValue: task.urgency)
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
        updatedTask.urgency = urgency

        // Update task in its group
        if let groupIndex = groupManager.groups.firstIndex(where: {
            $0.tasks.contains(where: { $0.id == task.id })
        }),
        let taskIndex = groupManager.groups[groupIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            groupManager.groups[groupIndex].tasks[taskIndex] = updatedTask
            groupManager.saveToDisk() // Ensure persistence
        } else {
            // If task doesn't exist in any group, add it freshly
            groupManager.addTask(updatedTask)
        }

        // Remove from reschedule queue
        rescheduleQueue.removeAll { $0.id == task.id }

        presentationMode.wrappedValue.dismiss()
    }

}
