//
//  HardDeadlineSettingView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/02/25.
//

import SwiftUI

// View that allows the user to assign hard deadlines to tasks
struct HardDeadlineSelectionView: View {
    var tasks: [UserTask]                             // The list of tasks to assign deadlines to
    var onFinish: (_ deadlines: [UUID: Date]) -> Void // Callback when the user finishes selection

    @Environment(\.presentationMode) var presentationMode

    // Dictionary to track selected deadlines per task
    @State private var deadlines: [UUID: Date] = [:]

    // Dictionary to track whether time should be included per task
    @State private var showTimePicker: [UUID: Bool] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                //  Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.85, green: 0.9, blue: 1.0),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("📆 Set Hard Deadlines")
                            .font(.largeTitle.bold())
                            .padding(.top)

                        // Fallback if no tasks provided
                        if tasks.isEmpty {
                            Text("No tasks to set deadlines for.")
                                .foregroundColor(.gray)
                        } else {
                            // Loop through each task and show UI for deadline input
                            ForEach(tasks) { task in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(task.title)
                                        .font(.headline)

                                    HStack {
                                        // Date only picker
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { deadlines[task.id] ?? Date() },
                                                set: { deadlines[task.id] = $0 }
                                            ),
                                            displayedComponents: [.date]
                                        )
                                        .labelsHidden()

                                        Spacer()

                                        // Toggle to allow time-based precision
                                        Toggle("Exact Time", isOn: Binding(
                                            get: { showTimePicker[task.id] ?? false },
                                            set: { showTimePicker[task.id] = $0 }
                                        ))
                                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                        .font(.caption)
                                    }

                                    // Optional time picker if enabled
                                    if showTimePicker[task.id] ?? false {
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { deadlines[task.id] ?? Date() },
                                                set: { deadlines[task.id] = $0 }
                                            ),
                                            displayedComponents: [.hourAndMinute]
                                        )
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.horizontal, 16)
                            }
                        }

                        Spacer(minLength: 30)

                        // Buttons: Cancel and Continue
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)

                            Button("Continue") {
                                // Pass selected deadlines back and dismiss
                                onFinish(deadlines)
                                presentationMode.wrappedValue.dismiss()
                            }
                            .disabled(tasks.isEmpty)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(tasks.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Set Deadlines")
        }
    }
}
