//
//  TopicsView.swift
//  NeverThink
//

import SwiftUI

struct TopicsView: View {
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @State private var showAddTopic = false

    var body: some View {
        NavigationView {
            List {
                ForEach(groupManager.groups.filter { !isDateBasedGroup($0.name) }) { group in
                    NavigationLink(destination: TaskListViewForGroup(group: group)
                        .environmentObject(groupManager)
                        .environmentObject(todayPlanManager)
                    ) {
                        Text(group.name)
                    }
                }
            }
            .navigationTitle("Topics 📚")
            .toolbar {
                ToolbarItem(placement: .automatic) {
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

    func isDateBasedGroup(_ name: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter.date(from: name) != nil
    }
}
