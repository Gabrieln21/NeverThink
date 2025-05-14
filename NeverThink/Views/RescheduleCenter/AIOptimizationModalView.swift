//
//  AiOptimizationModalView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/02/25.
//

import SwiftUI

// A modal view that allows users to select tasks to include in AI optimization
struct AIOptimizationModalView: View {
    let tasks: [UserTask] // List of tasks passed in
    var onConfirm: ([UserTask]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var selected: Set<UUID> = [] // Tracks which tasks are selected
    @State private var selectAll: Bool = true // Controls "Select All" toggle

    var body: some View {
        NavigationStack {
            ZStack {
                // background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.85, green: 0.9, blue: 1.0),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Select All Toggle
                    Toggle(isOn: $selectAll) {
                        Text("Select All")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .onChange(of: selectAll) { newValue in
                        // Select or deselect all tasks when toggled
                        selected = newValue ? Set(tasks.map { $0.id }) : []
                    }

                    // Scrollable list of tasks
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(tasks) { task in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text("\(task.duration) min • \(task.urgency.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    // Checkmark for selected tasks
                                    Image(systemName: selected.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(.accentColor)
                                }
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .onTapGesture {
                                    toggle(task) // Toggle selection
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Confirm and Optimize Button
                    Button(action: {
                        let chosen = tasks.filter { selected.contains($0.id) }
                        onConfirm(chosen) // Return selected tasks to caller
                        dismiss()
                    }) {
                        Text("✨ Optimize")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .padding(.top)
            }
            .navigationTitle("AI Optimize")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss() // Close modal
                    }
                }
            }
            .onAppear {
                // Select all tasks by default on view load
                selected = Set(tasks.map { $0.id })
            }
        }
    }

    // Toggles individual task selection and syncs `selectAll` state
    private func toggle(_ task: UserTask) {
        if selected.contains(task.id) {
            selected.remove(task.id)
        } else {
            selected.insert(task.id)
        }
        // Update "Select All" if all are now selected
        selectAll = selected.count == tasks.count
    }
}
