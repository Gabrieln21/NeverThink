//
//  HardDeadlineSettingView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//

import SwiftUI

struct HardDeadlineSelectionView: View {
    var tasks: [UserTask]
    var onFinish: (_ deadlines: [UUID: Date]) -> Void

    @Environment(\.presentationMode) var presentationMode
    @State private var deadlines: [UUID: Date] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Set Hard Deadlines (Optional)")) {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title)
                                .font(.headline)
                            
                            DatePicker(
                                "Deadline (Optional)",
                                selection: Binding(
                                    get: {
                                        deadlines[task.id] ?? Date()
                                    },
                                    set: { newValue in
                                        deadlines[task.id] = newValue
                                    }
                                ),
                                displayedComponents: [.date]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("📆 Set Deadlines")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        onFinish(deadlines)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(tasks.isEmpty)
                }
            }
        }
    }
}

