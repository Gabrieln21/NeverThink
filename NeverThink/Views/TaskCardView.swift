//
//  TaskCardView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/29/25.
//

import SwiftUI

// Reusable card-style view to visually represent a task with metadata like duration, date, urgency, and location.
struct TaskCardView: View {
    let title: String                   // Task title
    let urgencyColor: Color             // A colored dot to represent urgency
    let duration: Int                   // Duration in minutes
    let date: Date?                     // Optional task date
    let location: String?               // Optional location string
    let reason: String?                 // Optional reason (e.g., "AI Scheduled")
    let timeRangeText: String?          // Optional time range string
    let showDateWarning: Bool           // Indicates if date is missing
    let onDelete: (() -> Void)?         // Optional delete action
    let onTap: (() -> Void)?            // Optional tap action

    // Cleans up the location string by removing state/zip codes like "CA 94044"
    var cleanLocation: String? {
        guard let location else { return nil }
        let stripped = location.replacingOccurrences(
            of: #"(?i),?\s*CA\s*\d{5}(-\d{4})?"#,
            with: "",
            options: .regularExpression
        )
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left-side urgency indicator
            Circle()
                .fill(urgencyColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            // Main task content stack
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Optional date + duration info
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

                // Optional location display
                if let loc = cleanLocation, !loc.lowercased().contains("anywhere"), !loc.isEmpty {
                    Text("📍 \(loc)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                // Warning if no date set
                if showDateWarning {
                    Text("⚠️ No date set — added to today")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }

                // Optional reason string
                if let reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Optional delete button on the right
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
        .contentShape(Rectangle())       // entire card tappable
        .onTapGesture {
            onTap?()
        }
    }

    // Formats the date to a medium-style readable string
    private func formattedDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
