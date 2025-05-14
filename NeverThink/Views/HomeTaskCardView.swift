//
//  HomeTaskCardView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/29/25.
//

import SwiftUI

// A special task card used in the Home screen that adds live ETA button
struct HomeTaskCardView: View {
    let task: UserTask
    let onDelete: (() -> Void)?
    let onTap: (() -> Void)?

    // Stores the calculated ETA in minutes
    @State private var eta: Int?
    @State private var isLoading = false

    // Access user's current location
    @EnvironmentObject var locationService: LocationService

    // Travel mode (from settings)
    @AppStorage("travelMode") var travelMode: String = "driving"

    var body: some View {
        TaskCardView(
            title: task.title,
            urgencyColor: task.urgency.color,
            duration: task.duration,
            date: task.date,
            location: task.location,
            reason: nil,
            timeRangeText: nil,
            showDateWarning: task.date == nil,
            onDelete: onDelete,
            onTap: onTap
        )
        .overlay(
            // Display ETA button only if the task has a valid location
            Group {
                if let loc = task.location,
                   loc != "Home", loc != "Anywhere", !loc.isEmpty {
                    ETAButton(
                        eta: eta,
                        taskDate: task.date,
                        isLoading: isLoading,
                        action: fetchETA
                    )
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                    .zIndex(10)
                }
            },
            alignment: .topTrailing
        )
    }

    // Calls TravelService to fetch ETA between the user's current location and the task's location
    private func fetchETA() {
        guard let from = locationService.currentAddress,
              let to = task.location else { return }

        isLoading = true
        Task {
            defer { isLoading = false }

            do {
                guard let fromCoord = locationService.currentLocation?.coordinate else { return }

                let info = try await TravelService.shared.fetchTravelTime(
                    from: fromCoord,
                    to: to,
                    mode: travelMode,
                    arrivalTime: task.date ?? Date()
                )

                eta = info.durationMinutes
            } catch {
                print("❌ ETA fetch failed: \(error.localizedDescription)")
            }
        }
    }
}

// Small button that displays ETA
private struct ETAButton: View {
    let eta: Int?
    let taskDate: Date?
    let isLoading: Bool
    let action: () -> Void

    // Dynamically determines button color based on urgency
    var buttonColor: Color {
        guard let eta = eta,
              let arrival = taskDate,
              let fromNow = Calendar.current.dateComponents([.minute], from: Date(), to: arrival).minute else {
            return .blue
        }

        let leaveIn = fromNow - eta

        switch leaveIn {
        case ..<0:
            return .red // You're already late
        case 0..<15:
            return .orange // Better leave soon
        case 15...:
            return .blue // You're good
        default:
            return .gray
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                }

                Text(eta != nil ? "\(eta!)m" : "ETA")
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(buttonColor.opacity(0.95))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
