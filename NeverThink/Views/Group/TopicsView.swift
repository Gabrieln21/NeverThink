//
//  AddTopicView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//
import SwiftUI

struct TopicsView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @State private var showAddTopic = false

    var filteredGroups: [TaskGroup] {
        groupManager.groups.filter { !isDateBasedGroup($0.name) }
    }

    var body: some View {
        NavigationView {
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
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredGroups) { group in
                                NavigationLink(destination: TaskListViewForGroup(group: group)
                                    .environmentObject(groupManager)
                                    .environmentObject(todayPlanManager)) {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddTopic = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTopic) {
                AddTopicView()
                    .environmentObject(groupManager)
            }
        }
    }

    private func isDateBasedGroup(_ name: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter.date(from: name) != nil
    }
}
