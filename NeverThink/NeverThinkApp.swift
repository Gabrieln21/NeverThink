//
//  NeverThinkApp.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

@main
struct NeverThinkApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var groupManager = TaskGroupManager()
    @StateObject private var todayPlanManager = TodayPlanManager()
    @StateObject private var recurringTaskManager = RecurringTaskManager()

    init() {
        PlannerService.shared.requestLocation()
    }

    var body: some Scene {
        WindowGroup {
            if !authManager.isSignedIn {
                AuthView()
                    .environmentObject(authManager)
            } else if !authManager.hasSetHomeAddress {
                HomeAddressView()
                    .environmentObject(authManager)
            } else {
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(groupManager)
                    .environmentObject(todayPlanManager)
                    .environmentObject(recurringTaskManager)
            }
        }
    }
}
