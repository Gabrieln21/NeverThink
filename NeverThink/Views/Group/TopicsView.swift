//
//  AddTopicView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

// Displays all non date based task groups as topics and allows the user to add new ones.
struct TopicsView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var todayPlanManager: TodayPlanManager

    @State private var showAddTopic = false

    // Filters out groups whose names match a recognizable date
    var filteredGroups: [TaskGroup] {
        groupManager.groups.filter { !isDateBasedGroup($0.name) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.85, green: 0.9, blue: 1.0), // pastel blue
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Empty state UI
                if filteredGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray.opacity(0.4))

                        Text("No Topics")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .offset(y: -60)
                } else {
                    // List of non date groups
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredGroups) { group in
                                // Tapping a topic navigates to its associated task list
                                NavigationLink(
                                    destination: TaskListViewForGroup(group: group)
                                        .environmentObject(groupManager)
                                        .environmentObject(todayPlanManager)
                                ) {
                                    HStack {
                                        Text(group.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.2))
                                            .background(.ultraThinMaterial)
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Topics 📚")
            .toolbar {
                // Toolbar button to trigger topic creation
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddTopic = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTopic) {
                // Presents a modal to add a new topic
                AddTopicView()
                    .environmentObject(groupManager)
            }
        }
    }

    // Helper to check if a group's name matches a recognizable date string
    private func isDateBasedGroup(_ name: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter.date(from: name) != nil
    }
}
