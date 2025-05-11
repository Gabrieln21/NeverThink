import SwiftUI

struct RescheduleQueueView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Binding var rescheduleQueue: [UserTask]
    @Binding var selectedTask: UserTask?
    @State private var showRescheduleForm = false

    
    var body: some View {
        List {
            ForEach(rescheduleQueue) { task in
                Button {
                    selectedTask = task
                    showRescheduleForm = true
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.headline)
                        Text("\(task.duration) min | Urgency: \(task.urgency.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let time = task.exactTime ?? task.timeRangeStart {
                            Text("Original time: \(time.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Reschedule Tasks")
        .sheet(isPresented: $showRescheduleForm) {
            if let task = selectedTask {
                RescheduleFormView(task: task, rescheduleQueue: $rescheduleQueue)
                    .environmentObject(groupManager)
            }
        }
    }
}
