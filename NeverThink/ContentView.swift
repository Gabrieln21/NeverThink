//
//  ContentView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//
import SwiftUI

// Root tab-based view of app
struct ContentView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var recurringTaskManager: RecurringTaskManager

    // Configure the AI planner service once when the app initializes
    init() {
        PlannerService.shared.configure(apiKey: "OPENAI_API_KEY_HERE")
        TravelService.shared.configure(apiKey: "GOOGLE_API_KEY_HERE")
    }


    var body: some View {
        TabView {
            // Tab 1: Today/Calendar View
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .environmentObject(groupManager)
                .environmentObject(todayPlanManager)
            // Tab 2: Topic-Based Task Lists
            TopicsView()
                .tabItem {
                    Label("Topics", systemImage: "list.bullet.rectangle.portrait")
                }
                .environmentObject(groupManager)
                .environmentObject(todayPlanManager)
            // Tab 3: Recurring Task Management
            RecurringTasksView()
                .tabItem {
                    Label("Recurring", systemImage: "arrow.2.circlepath")
                }
                .environmentObject(recurringTaskManager)
                .environmentObject(groupManager)
        }
        .onAppear {
            // Load saved state on app launch
            todayPlanManager.loadFromDisk()
            groupManager.loadFromDisk()
            recurringTaskManager.loadFromDisk()
        }
    }
}
