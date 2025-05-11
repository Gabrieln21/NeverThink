import SwiftUI

struct RecurringTaskDetailView: View {
    @EnvironmentObject var recurringTaskManager: RecurringTaskManager
    @Environment(\.presentationMode) var presentationMode

    var task: RecurringTask
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
                    Text("Recurring Task")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    Group {
                        Text("Title")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text(task.title)
                            .font(.title2.bold())
                    }

                    Group {
                        Text("Recurrence")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "repeat")
                            Text(task.recurringInterval.rawValue)
                        }
                        .font(.body)
                    }

                    if task.isTimeSensitive {
                        Group {
                            Text("Time Info")
                                .font(.callout)
                                .foregroundColor(.secondary)

                            switch task.timeSensitivityType {
                            case .dueBy:
                                if let dueBy = task.exactTime {
                                    Label("Due by: \(dueBy.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                                }
                            case .startsAt:
                                if let startsAt = task.exactTime {
                                    Label("Starts at: \(startsAt.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                                }
                            case .busyFromTo:
                                if let start = task.timeRangeStart, let end = task.timeRangeEnd {
                                    Label("Busy: \(start.formatted(date: .omitted, time: .shortened)) → \(end.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                                }
                            case .none:
                                EmptyView()
                            }
                        }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: EditRecurringTaskView(taskIndex: taskIndex, task: task)
                        .environmentObject(recurringTaskManager)
                ) {
                    Image(systemName: "pencil")
                }
            }
        }
    }

    func deleteTask() {
        recurringTaskManager.deleteRecurringTask(at: IndexSet(integer: taskIndex))
        presentationMode.wrappedValue.dismiss()
    }
}
