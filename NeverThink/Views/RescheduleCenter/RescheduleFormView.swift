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
            Form {
                Section(header: Text("Task Info")) {
                    TextField("Task Title", text: $newTitle)
                    
                    DatePicker("New Date", selection: $newDate, displayedComponents: .date)

                    DatePicker("Optional Time", selection: Binding(
                        get: { newTime ?? Date() },
                        set: { newTime = $0 }
                    ), displayedComponents: .hourAndMinute)

                    Picker("Urgency", selection: $urgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue)
                        }
                    }
                }

                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Reschedule Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = newTitle
        updatedTask.date = newDate
        updatedTask.exactTime = newTime
        updatedTask.urgency = urgency

        // Update groupManager
        if let todayGroupIndex = groupManager.groups.firstIndex(where: { group in
            group.tasks.contains(where: { $0.id == task.id })
        }),
        let taskIndexInGroup = groupManager.groups[todayGroupIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            groupManager.groups[todayGroupIndex].tasks[taskIndexInGroup] = updatedTask
        }

        // Remove from reschedule queue
        rescheduleQueue.removeAll(where: { $0.id == task.id })

        presentationMode.wrappedValue.dismiss()
    }
}
