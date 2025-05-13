//
//  TaskListCollectionView.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/25/25.
//
import SwiftUI

struct TaskListCollectionView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @State private var showingAddSheet = false
    @State private var newListName: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(groupManager.groups) { group in
                    NavigationLink(destination: TaskListViewForGroup(group: group)) {
                        Text(group.name)
                    }
                }
                .onDelete(perform: groupManager.deleteGroup)
            }
            .navigationTitle("My Task Lists")
            .toolbar {
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
                        groupManager.addGroup(name: newListName)
                        newListName = ""
                        showingAddSheet = false
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .frame(width: 300)
            }
        }
    }
}

