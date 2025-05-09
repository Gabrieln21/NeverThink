import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    var task: UserTask
    var taskIndex: Int

    var body: some View {
        Form {
            Section {
                Text(task.title)
                    .font(.title)
                    .bold()

                HStack {
                    Image(systemName: "clock")
                    Text("Duration: \(task.duration) minutes")
                }

                if task.isTimeSensitive {
                    switch task.timeSensitivityType {
                    case .dueBy:
                        if let dueBy = task.exactTime {
                            Text("Due by: \(dueBy.formatted(date: .omitted, time: .shortened))")
                        }
                    case .startsAt:
                        if let startsAt = task.exactTime {
                            Text("Starts at: \(startsAt.formatted(date: .omitted, time: .shortened))")
                        }
                    case .busyFromTo:
                        if let start = task.timeRangeStart, let end = task.timeRangeEnd {
                            Text("Busy from: \(start.formatted(date: .omitted, time: .shortened)) to \(end.formatted(date: .omitted, time: .shortened))")
                        }
                    }
                }

                Text("Urgency: \(task.urgency.rawValue)")
            } header: {
                Text("Task Info")
            }

            if task.isLocationSensitive, let loc = task.location {
                Section {
                    Text(loc)
                } header: {
                    Text("Location")
                }
            }

            Section {
                Text(task.category.rawValue)
            } header: {
                Text("Category")
            }

            Section {
                Button(role: .destructive) {
                    deleteTask()
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Task Details")
        .toolbar {
            NavigationLink(destination: EditTaskView(taskIndex: taskIndex, task: task)
                .environmentObject(groupManager)
            ) {
                Image(systemName: "pencil")
            }
        }
    }

    func deleteTask() {
        if let todayGroupIndex = groupManager.groups.firstIndex(where: { group in
            group.tasks.contains(where: { $0.id == task.id })
        }),
           let taskIndexInGroup = groupManager.groups[todayGroupIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            groupManager.groups[todayGroupIndex].tasks.remove(at: taskIndexInGroup)
        }

        presentationMode.wrappedValue.dismiss()
    }
}
