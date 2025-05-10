//
//  RescheduleTasksView.swift
//  NeverThink
//

import SwiftUI

struct RescheduleTasksView: View {
    @Binding var rescheduleQueue: [UserTask]

    var body: some View {
        NavigationView {
            List {
                if rescheduleQueue.isEmpty {
                    Text("🎉 No tasks to reschedule!")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(rescheduleQueue) { task in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title)
                                .font(.headline)
                            if let date = task.date {
                                Text("Original Date: \(date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("📆 Reschedule Tasks")
        }
    }
}
