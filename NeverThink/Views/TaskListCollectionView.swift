//
//  TaskListCollectionView.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/25/25.
//

import SwiftUI

// Displays a list of all user-created task groups
struct TaskListCollectionView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @State private var showingAddSheet = false
    @State private var newListName: String = ""
    
    var body: some View {
        NavigationView {
            List {
                // Display each task group with a NavigationLink to its detail view
                ForEach(groupManager.groups) { group in
                    NavigationLink(destination: TaskListViewForGroup(group: group)) {
                        Text(group.name)
                    }
                }
                .onDelete(perform: groupManager.deleteGroup) // Allow swipe-to-delete for groups
            }
            .navigationTitle("My Task Lists")
            .toolbar {
                // "+" button to create a new task list
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                VStack {
                    Text("New Task List")
                        .font(.headline)

                    TextField("List name", text: $newListName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("Create") {
                        groupManager.addGroup(name: newListName) // Add new list to manager
                        newListName = ""                         // Reset input
                        showingAddSheet = false                  // Dismiss sheet
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty) // Prevent empty names
                }
                .padding()
                .frame(width: 300)
            }
        }
    }
}
