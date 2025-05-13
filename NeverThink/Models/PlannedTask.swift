import Foundation

struct PlannedTask: Codable, Identifiable {
    var id: String = UUID().uuidString
    var start_time: String
    var end_time: String
    var title: String
    var notes: String?
    var reason: String?
    var date: Date = Calendar.current.startOfDay(for: Date())
    var isCompleted: Bool = false
    var duration: Int
    var urgency: UrgencyLevel
    var timeSensitivityType: TimeSensitivity = .startsAt
    var location: String?

    enum TimeSensitivity: String, Codable, CaseIterable {
        case none
        case dueBy
        case startsAt
        case busyFromTo
    }

    private enum CodingKeys: String, CodingKey {
        case id, start_time, end_time, title, notes, reason, date, isCompleted, duration, urgency, timeSensitivityType, location
    }

    init(
        id: String = UUID().uuidString,
        start_time: String,
        end_time: String,
        title: String,
        notes: String? = nil,
        reason: String? = nil,
        date: Date = Calendar.current.startOfDay(for: Date()),
        urgency: UrgencyLevel = .medium,
        timeSensitivityType: TimeSensitivity = .startsAt,
        location: String? = nil
    ) {
        self.id = id
        self.start_time = start_time
        self.end_time = end_time
        self.title = title
        self.notes = notes
        self.reason = reason
        self.date = date
        self.isCompleted = false
        self.duration = PlannedTask.calculateDuration(from: start_time, to: end_time)
        self.urgency = urgency
        self.timeSensitivityType = timeSensitivityType
        self.location = location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        start_time = try container.decode(String.self, forKey: .start_time)
        end_time = try container.decode(String.self, forKey: .end_time)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Calendar.current.startOfDay(for: Date())
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        urgency = try container.decodeIfPresent(UrgencyLevel.self, forKey: .urgency) ?? .medium
        timeSensitivityType = try container.decodeIfPresent(TimeSensitivity.self, forKey: .timeSensitivityType) ?? .startsAt

        // calculate duration if missing
        if let providedDuration = try container.decodeIfPresent(Int.self, forKey: .duration) {
            duration = providedDuration
        } else {
            duration = PlannedTask.calculateDuration(from: start_time, to: end_time)
        }
    }

    static func calculateDuration(from start: String, to end: String) -> Int {
        guard
            let startDate = DateFormatter.parseTimeString(start),
            let endDate = DateFormatter.parseTimeString(end)
        else {
            return 0
        }

        let diff = Calendar.current.dateComponents([.minute], from: startDate, to: endDate)
        return max(diff.minute ?? 0, 0)
    }
}
