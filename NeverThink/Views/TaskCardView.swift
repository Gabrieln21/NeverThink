import SwiftUI

struct TaskCardView: View {
    let title: String
    let urgencyColor: Color
    let duration: Int
    let date: Date?
    let location: String?
    let reason: String?
    let timeRangeText: String?
    let showDateWarning: Bool
    let onDelete: (() -> Void)?
    let onTap: (() -> Void)?


    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(urgencyColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let timeText = timeRangeText {
                        Text(timeText)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    if let date = date {
                        Text("\(date.formatted(date: .abbreviated, time: .omitted)) • \(duration) min")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        Text("⚠️ No date set — will be added to today • \(duration) min")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    if let loc = location, !loc.lowercased().contains("anywhere"), !loc.isEmpty {
                        Text("📍 \(loc)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    if let reason = reason, !reason.isEmpty {
                        Text(reason)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
