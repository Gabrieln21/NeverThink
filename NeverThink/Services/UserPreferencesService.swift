//
//  UserPreferencesService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/3/25.
//

import Foundation

// Manages and persists user preferences such as home address, notification settings, and sleep schedule.
class UserPreferencesService: ObservableObject {
    @Published var homeAddress: String = ""
    @Published var commonLocations: [SavedLocation] = [] // List of user-saved locations
    @Published var wakeUpTime: Date = Date()
    @Published var sleepTime: Date = Date()
    @Published var notifyReminders: Bool = true
    @Published var notifyUpcomingTasks: Bool = true
    @Published var notifyTravelWarnings: Bool = false

    init() {
        load()
    }

    // Saves all user preference values to UserDefaults
    func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(commonLocations) {
            UserDefaults.standard.set(data, forKey: "commonLocations")
        }

        UserDefaults.standard.set(homeAddress, forKey: "homeAddress")
        UserDefaults.standard.set(wakeUpTime, forKey: "wakeUpTime")
        UserDefaults.standard.set(sleepTime, forKey: "sleepTime")
        UserDefaults.standard.set(notifyReminders, forKey: "notifyReminders")
        UserDefaults.standard.set(notifyUpcomingTasks, forKey: "notifyUpcomingTasks")
        UserDefaults.standard.set(notifyTravelWarnings, forKey: "notifyTravelWarnings")
    }
    
    // Loads all user preference values from UserDefaults
    func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "commonLocations"),
           let decoded = try? decoder.decode([SavedLocation].self, from: data) {
            self.commonLocations = decoded
        }

        homeAddress = UserDefaults.standard.string(forKey: "homeAddress") ?? ""
        wakeUpTime = UserDefaults.standard.object(forKey: "wakeUpTime") as? Date ?? Date()
        sleepTime = UserDefaults.standard.object(forKey: "sleepTime") as? Date ?? Date()
        notifyReminders = UserDefaults.standard.bool(forKey: "notifyReminders")
        notifyUpcomingTasks = UserDefaults.standard.bool(forKey: "notifyUpcomingTasks")
        notifyTravelWarnings = UserDefaults.standard.bool(forKey: "notifyTravelWarnings")
    }
}
