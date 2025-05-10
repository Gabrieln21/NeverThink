import Foundation

struct PlannedTask: Codable, Identifiable {
    var id = UUID()
    var start_time: String
    var end_time: String
    var title: String
    var notes: String?
    var reason: String?
    var date: Date
    var isCompleted: Bool = false

    private enum CodingKeys: String, CodingKey {
        case start_time, end_time, title, notes, reason
    }

    init(
        start_time: String,
        end_time: String,
        title: String,
        notes: String? = nil,
        reason: String? = nil,
        date: Date
    ) {
        self.start_time = start_time
        self.end_time = end_time
        self.title = title
        self.notes = notes
        self.reason = reason
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start_time = try container.decode(String.self, forKey: .start_time)
        end_time = try container.decode(String.self, forKey: .end_time)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        date = Date() // later overwritten correctly!
    }
}
