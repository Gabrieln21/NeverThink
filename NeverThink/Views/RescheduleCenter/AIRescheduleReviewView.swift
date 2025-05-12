import SwiftUI

struct GPTPlannedTask: Codable {
    let id: String
    let title: String
    let start_time: String
    let duration: Int
    let urgency: UrgencyLevel
}

struct AIRescheduleReviewView: View {
    var aiPlanText: String
    var originalTasks: [UserTask]
    var onAccept: () -> Void
    var onRegenerate: (String) -> Void
    
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager


    @State private var userNotes: String = ""
    @State private var selectedTask: PlannedTask?

    private var parsedTasks: [PlannedTask] {
        guard let data = aiPlanText.data(using: .utf8) else {
            print("⚠️ Could not convert AI plan to Data")
            return []
        }

        let decoder = JSONDecoder()
        guard let gptTasks = try? decoder.decode([GPTPlannedTask].self, from: data) else {
            print("⚠️ Failed to decode GPTPlannedTask from JSON")
            return []
        }

        let formatter = ISO8601DateFormatter()

        return gptTasks.compactMap { gpt in
            let startDate = formatter.date(from: gpt.start_time) ?? Date()
            let endString = DateFormatter.timeStringByAddingMinutes(to: gpt.start_time, minutes: gpt.duration)
            let derivedDate = Calendar.current.startOfDay(for: startDate)

            // Look up original task
            let original = originalTasks.first(where: { $0.id.uuidString == gpt.id })
            let timeSensitivity: PlannedTask.TimeSensitivity = original
                .flatMap { PlannedTask.TimeSensitivity(rawValue: $0.timeSensitivityType.rawValue) } ?? .startsAt

            var task = PlannedTask(
                id: gpt.id,
                start_time: gpt.start_time,
                end_time: endString,
                title: original?.title ?? gpt.title,
                notes: nil,
                reason: "AI Scheduled",
                date: derivedDate,
                urgency: original?.urgency ?? gpt.urgency,
                timeSensitivityType: timeSensitivity,
                location: original?.location
            )

            task.duration = gpt.duration // manually set to prevent auto-zero

            return task
        }

    }



    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.85, green: 0.9, blue: 1.0), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("🧠 AI Proposed Plan")
                            .font(.largeTitle.bold())
                            .padding(.top)

                        planPreviewSection

                        Divider()

                        notesSection

                        buttonsSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Review Plan")
        }
    }

    @ViewBuilder
    private var planPreviewSection: some View {
        if parsedTasks.isEmpty {
            Text("⚠️ Could not parse GPT response. Showing raw output:")
                .font(.subheadline)
                .foregroundColor(.red)
            Text(aiPlanText)
                .font(.caption)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .foregroundColor(.black)
        } else {
            ForEach(parsedTasks, id: \.id) { task in
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.headline)

                        if let time = DateFormatter.iso8601Formatter.date(from: task.start_time) {
                            Text("📅 \(time.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("⏱️ \(task.duration) min | 🔥 Urgency: \(task.urgency.rawValue)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    selectedTask = task
                    print("🖊️ Edit \(task.title)")
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📝 Add Notes for GPT (Optional)")
                .font(.callout)
                .foregroundColor(.secondary)

            TextEditor(text: $userNotes)
                .frame(height: 160)
                .padding(10)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }


    private var buttonsSection: some View {
        VStack(spacing: 14) {
            Button(action: {
                for task in parsedTasks {
                    if let uuid = UUID(uuidString: task.id) {
                        groupManager.removeTaskById(uuid)

                        let mappedSensitivity: TimeSensitivity
                        switch task.timeSensitivityType {
                        case .startsAt:
                            mappedSensitivity = .startsAt
                        case .dueBy:
                            mappedSensitivity = .dueBy
                        case .busyFromTo:
                            mappedSensitivity = .busyFromTo
                        case .none:
                            mappedSensitivity = .none
                        }

                        let category: TaskCategory = (task.location != nil && !task.location!.lowercased().contains("anywhere")) ? .beSomewhere : .doAnywhere

                        let userTask = UserTask(
                            id: uuid,
                            title: task.title,
                            duration: task.duration,
                            isTimeSensitive: true,
                            urgency: task.urgency,
                            isLocationSensitive: task.location != nil,
                            location: task.location,
                            category: category,
                            timeSensitivityType: mappedSensitivity,
                            exactTime: DateFormatter.iso8601Formatter.date(from: task.start_time),
                            timeRangeStart: nil,
                            timeRangeEnd: nil,
                            date: task.date,
                            parentRecurringId: nil
                        )


                        groupManager.addTask(userTask)
                        todayPlanManager.removeTaskById(uuid)

                    }
                }

                onAccept()
            }) {
                Text("✅ Accept This Plan")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }




            Button(action: { onRegenerate(userNotes) }) {
                Text("🔄 Regenerate Plan With Notes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.accentColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    )
            }
        }
        .padding(.top)
    }
}

extension DateFormatter {
    static var iso8601Formatter: DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return f
    }

}
