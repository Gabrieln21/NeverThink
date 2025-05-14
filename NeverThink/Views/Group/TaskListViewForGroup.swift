//
//  TaskListViewForGroup.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

// View that displays all tasks within a task group.
struct TaskListViewForGroup: View {
    @EnvironmentObject var groupManager: TaskGroupManager

    var group: TaskGroup
    @State private var tasks: [UserTask]

    // Initialize with the current task group and copy its tasks into state
    init(group: TaskGroup) {
        self.group = group
        _tasks = State(initialValue: group.tasks)
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.85, green: 0.9, blue: 1.0), // pastel blue
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // If there are no tasks in the group
            if tasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray.opacity(0.4))

                    Text("No Tasks")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .offset(y: -60)
            } else {
                // Display tasks in a scrollable list
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            // Each task is tappable and links to a detail view
                            NavigationLink(destination: TaskDetailView(task: task, taskIndex: index)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(task.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("\(task.duration) min • \(task.urgency.rawValue)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(0.2))
                                        .background(.ultraThinMaterial) // adds blur/glass effect
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                        }
                        // Swipe-to-delete for task cards (custom implementation required for ScrollView)
                        .onDelete { offsets in
                            tasks.remove(atOffsets: offsets)
                            groupManager.updateTasks(for: group.id, tasks: tasks)
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle(group.name) // Show group name as nav title
        .toolbar {
            // Add new task to the group
            NavigationLink(destination: NewTaskViewForGroup(groupId: group.id, tasks: $tasks)) {
                Image(systemName: "plus")
            }
        }
    }
}
