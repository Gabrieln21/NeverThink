import SwiftUI

struct HardDeadlineSelectionView: View {
    var tasks: [UserTask]
    var onFinish: (_ deadlines: [UUID: Date]) -> Void

    @Environment(\.presentationMode) var presentationMode
    @State private var deadlines: [UUID: Date] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
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

                        if tasks.isEmpty {
                            Text("No tasks to set deadlines for.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(tasks) { task in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(task.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    DatePicker(
                                        "Deadline",
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
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                }
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                        }

                        Spacer(minLength: 30)

                        HStack {
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)

                            Button("Continue") {
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
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Set Deadlines")
        }
    }
}
