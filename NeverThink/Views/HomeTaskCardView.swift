import SwiftUI

struct HomeTaskCardView: View {
    let task: UserTask
    let onDelete: (() -> Void)?
    let onTap: (() -> Void)?

    @State private var eta: Int?
    @State private var isLoading = false

    @EnvironmentObject var locationService: LocationService
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

private struct ETAButton: View {
    let eta: Int?
    let taskDate: Date?
    let isLoading: Bool
    let action: () -> Void

    var buttonColor: Color {
        guard let eta = eta,
              let arrival = taskDate,
              let fromNow = Calendar.current.dateComponents([.minute], from: Date(), to: arrival).minute else {
            return .blue
        }

        let leaveIn = fromNow - eta

        switch leaveIn {
        case ..<0:
            return .red
        case 0..<15:
            return .orange
        case 15...:
            return .blue
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
