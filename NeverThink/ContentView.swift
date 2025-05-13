//
//  ContentView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todayPlanManager: TodayPlanManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var recurringTaskManager: RecurringTaskManager

    init() {
        PlannerService.shared.configure(apiKey: "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")
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

            RecurringTasksView()
                .tabItem {
                    Label("Recurring", systemImage: "arrow.2.circlepath")
                }
                .environmentObject(recurringTaskManager)
                .environmentObject(groupManager)
        }
        .onAppear {
            todayPlanManager.loadFromDisk()
            groupManager.loadFromDisk()
            recurringTaskManager.loadFromDisk()
        }
    }
}
