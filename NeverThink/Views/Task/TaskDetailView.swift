import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    var task: UserTask
    var taskIndex: Int

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
                    Text("Task Details")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    Group {
                        Text("Title")
                            .font(.callout).foregroundColor(.secondary)
                        Text(task.title)
                            .font(.title2.bold())
                    }

                    Group {
                        Text("Duration")
                            .font(.callout).foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "clock")
                            Text("\(task.duration) minutes")
                        }
                        .font(.body)
                    }

                    if task.isTimeSensitive {
                        Group {
                            Text("Time Info")
                                .font(.callout).foregroundColor(.secondary)

                            switch task.timeSensitivityType {
                            case .dueBy:
                                if let dueBy = task.exactTime {
                                    Text("🕒 Due by: \(dueBy.formatted(date: .omitted, time: .shortened))")
                                }
                            case .startsAt:
                                if let startsAt = task.exactTime {
                                    Text("🚀 Starts at: \(startsAt.formatted(date: .omitted, time: .shortened))")
                                }
                            case .busyFromTo:
                                if let start = task.timeRangeStart, let end = task.timeRangeEnd {
                                    Text("📆 Busy: \(start.formatted(date: .omitted, time: .shortened)) → \(end.formatted(date: .omitted, time: .shortened))")
                                }
                            default:
                                EmptyView()
                            }
                        }
                    }

                    Group {
                        Text("Urgency")
                            .font(.callout).foregroundColor(.secondary)
                        Text(task.urgency.rawValue)
                            .font(.body)
                    }

                    if task.isLocationSensitive, let loc = task.location {
                        Group {
                            Text("Location")
                                .font(.callout).foregroundColor(.secondary)
                            Text(loc)
                        }
                    }

                    Group {
                        Text("Category")
                            .font(.callout).foregroundColor(.secondary)
                        Text(task.category.rawValue)
                    }

                    Divider()

                    Button(role: .destructive) {
                        deleteTask()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Task")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Task Details")
        .toolbar {
            NavigationLink(destination: EditTaskView(taskIndex: taskIndex, task: task)
                .environmentObject(groupManager)) {
                Image(systemName: "pencil")
            }
        }
    }

    private func deleteTask() {
        if let groupIndex = groupManager.groups.firstIndex(where: { group in
            group.tasks.contains(where: { $0.id == task.id })
        }),
           let taskIndexInGroup = groupManager.groups[groupIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            groupManager.groups[groupIndex].tasks.remove(at: taskIndexInGroup)
        }

        presentationMode.wrappedValue.dismiss()
    }
}
