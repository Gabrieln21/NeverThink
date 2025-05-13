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

    var cleanLocation: String? {
        guard let location else { return nil }
        let stripped = location.replacingOccurrences(of: #"(?i),?\s*CA\s*\d{5}(-\d{4})?"#, with: "", options: .regularExpression)
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(urgencyColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let date = date {
                    if let time = timeRangeText, !time.isEmpty {
                        Text("📅 \(formattedDate(for: date)) • \(time) • \(duration) min")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        Text("📅 \(formattedDate(for: date)) • \(duration) min")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                if let loc = cleanLocation, !loc.lowercased().contains("anywhere"), !loc.isEmpty {
                    Text("📍 \(loc)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                if showDateWarning {
                    Text("⚠️ No date set — added to today")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }

                if let reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if let onDelete {
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
        .contentShape(Rectangle()) // Make the whole area tappable
        .onTapGesture {
            onTap?()
        }
    }

    private func formattedDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
