//
//  AddTopicView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//
import SwiftUI

// View for creating a new task group (called "Topics")
struct AddTopicView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @Environment(\.presentationMode) var presentationMode

    @State private var topicName: String = ""

    var body: some View {
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

            VStack(alignment: .leading, spacing: 24) {
                Text("Add Topic")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                // Input for the topic name
                Group {
                    Text("New Topic")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    TextField("Enter topic name", text: $topicName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Spacer()
                // Save button - adds group and dismisses view
                Button(action: {
                    groupManager.addGroup(name: topicName)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save Topic")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(topicName.isEmpty ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(topicName.isEmpty) // Prevent saving empty names
            }
            .padding(24)
        }
    }
}
