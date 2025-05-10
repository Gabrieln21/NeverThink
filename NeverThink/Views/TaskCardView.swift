//
//  TaskCardView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//
import SwiftUI

struct TaskCardView: View {
    let task: PlannedTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(task.start_time) - \(task.end_time)")
                .font(.caption)
                .foregroundColor(.gray)
            Text(task.title)
                .font(.headline)
                .padding(.bottom, 2)

            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }

            if let reason = task.reason, !reason.isEmpty {
                DisclosureGroup("AI Reasoning") {
                    Text(reason)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

