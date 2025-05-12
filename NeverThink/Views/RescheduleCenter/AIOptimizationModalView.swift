import SwiftUI

struct AIOptimizationModalView: View {
    let tasks: [UserTask]
    var onConfirm: ([UserTask]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var selected: Set<UUID> = []
    @State private var selectAll: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
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
                        selected = newValue ? Set(tasks.map { $0.id }) : []
                    }

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

                                    Image(systemName: selected.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(.accentColor)
                                }
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .onTapGesture {
                                    toggle(task)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Button(action: {
                        let chosen = tasks.filter { selected.contains($0.id) }
                        onConfirm(chosen)
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
                        dismiss()
                    }
                }
            }
            .onAppear {
                selected = Set(tasks.map { $0.id }) // default: all selected
            }
        }
    }

    private func toggle(_ task: UserTask) {
        if selected.contains(task.id) {
            selected.remove(task.id)
        } else {
            selected.insert(task.id)
        }
        selectAll = selected.count == tasks.count
    }
}
