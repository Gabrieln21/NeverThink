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
        NavigationView {
            Form {
                Section(header: Text("New Topic")) {
                    TextField("Enter topic name", text: $topicName)
                }

                Button("Save Topic") {
                    groupManager.addGroup(name: topicName)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(topicName.isEmpty)
            }
            .navigationTitle("Add Topic")
        }
    }
}


