//
//  AddTopicView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//
import SwiftUI

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

                Group {
                    Text("New Topic")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    TextField("Enter topic name", text: $topicName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Spacer()

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
                .disabled(topicName.isEmpty)
            }
            .padding(24)
        }
    }
}
