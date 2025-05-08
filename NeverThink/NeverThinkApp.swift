//
//  NeverThinkApp.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

@main
struct NeverThinkApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var groupManager = TaskGroupManager()
    @StateObject private var todayPlanManager = TodayPlanManager()

    init() {
        PlannerService.shared.requestLocation()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(groupManager)
                .environmentObject(todayPlanManager)
        }
    }
}
