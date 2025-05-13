//
//  NeverThinkApp.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/25/25.
//

import SwiftUI

@main
struct NeverThinkApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var groupManager = TaskGroupManager()
    @StateObject private var todayPlanManager = TodayPlanManager()
    @StateObject private var recurringTaskManager = RecurringTaskManager()
    @StateObject private var preferences = UserPreferencesService()
    @StateObject private var locationService = LocationService.shared

    init() {
        PlannerService.shared.requestLocation()
    }

    var body: some Scene {
        WindowGroup {
            if !authManager.isSignedIn {
                AuthView()
                    .environmentObject(authManager)
                    .environmentObject(preferences)
                    .environmentObject(locationService)
            } else if !authManager.hasSetHomeAddress {
                HomeAddressView()
                    .environmentObject(authManager)
                    .environmentObject(preferences)
                    .environmentObject(locationService)
            } else {
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(groupManager)
                    .environmentObject(todayPlanManager)
                    .environmentObject(recurringTaskManager)
                    .environmentObject(preferences)
                    .environmentObject(locationService)
            }
        }
    }
}
