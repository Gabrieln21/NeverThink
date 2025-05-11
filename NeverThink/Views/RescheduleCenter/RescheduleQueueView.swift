import SwiftUI

struct RescheduleQueueView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Binding var rescheduleQueue: [UserTask]
    @Binding var selectedTask: UserTask?
    @State private var showRescheduleForm = false

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
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reschedule Tasks")
                            .font(.largeTitle.bold())
                            .padding(.top)

                        if rescheduleQueue.isEmpty {
                            Text("No tasks in your reschedule queue.")
                                .foregroundColor(.gray)
                                .padding(.top)
                        } else {
                            ForEach(rescheduleQueue) { task in
                                Button {
                                    selectedTask = task
                                    showRescheduleForm = true
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(task.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text("\(task.duration) min • Urgency: \(task.urgency.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        if let time = task.exactTime ?? task.timeRangeStart {
                                            Text("Original time: \(time.formatted(date: .omitted, time: .shortened))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.95))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("🗓 Reschedule Queue")
            .sheet(isPresented: $showRescheduleForm) {
                if let task = selectedTask {
                    RescheduleFormView(task: task, rescheduleQueue: $rescheduleQueue)
                        .environmentObject(groupManager)
                }
            }
        }
    }
}
