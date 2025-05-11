import SwiftUI

struct RescheduleTasksView: View {
    @Binding var rescheduleQueue: [UserTask]

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
                        Text("📆 Reschedule Tasks")
                            .font(.largeTitle.bold())
                            .padding(.top)

                        if rescheduleQueue.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.5))

                                Text("🎉 No tasks to reschedule!")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            ForEach(rescheduleQueue) { task in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(task.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    if let date = task.date {
                                        Text("Original Date: \(date.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
    }
}
