//
//  ContentView.swift
//  NeverThink
//

import SwiftUI

struct ContentView: View {
    @StateObject var todayPlanManager = TodayPlanManager()
    @StateObject var groupManager = TaskGroupManager()

    init() {
        //Unpushable API key config
        //PlannerService.shared.configure()
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .environmentObject(groupManager)
                .environmentObject(todayPlanManager)

            TopicsView()
                .tabItem {
                    Label("Topics", systemImage: "list.bullet.rectangle.portrait")
                }
                .environmentObject(groupManager)
                .environmentObject(todayPlanManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TaskGroupManager())
        .environmentObject(TodayPlanManager())
}
