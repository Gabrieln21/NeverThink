//
//  NeverThinkApp.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/25/25.
//

import SwiftUI

@main
struct NeverThinkApp: App {
    
    // Global environment objects for shared state across views
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var groupManager = TaskGroupManager()
    @StateObject private var todayPlanManager = TodayPlanManager()
    @StateObject private var recurringTaskManager = RecurringTaskManager()
    @StateObject private var preferences = UserPreferencesService()
    @StateObject private var locationService = LocationService.shared

    init() {
        // Global environment objects for shared state across views
        PlannerService.shared.requestLocation()
    }

    var body: some Scene {
        WindowGroup {
            // Determine which view to show based on authentication and setup status
            if !authManager.isSignedIn {
                // First-time users or logged-out users see the auth screen
                AuthView()
                    .environmentObject(authManager)
                    .environmentObject(preferences)
                    .environmentObject(locationService)
            } else if !authManager.hasSetHomeAddress {
                // Ask for home base if not yet configured
                HomeAddressView()
                    .environmentObject(authManager)
                    .environmentObject(preferences)
                    .environmentObject(locationService)
            } else {
                // Main app view
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
