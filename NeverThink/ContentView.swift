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
    }
}
