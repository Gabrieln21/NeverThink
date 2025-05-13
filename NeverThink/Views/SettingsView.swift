//
//  SettingsView.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 05/04/25
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferencesService
    @AppStorage("travelMode") var travelMode: String = "driving"

    @State private var newLocationName = ""
    @State private var newLocationAddress = ""

    var body: some View {
        Form {
            // Home Address
            Section(header: Text("🏠 Home Address")) {
                TextField("Enter Home Address", text: $preferences.homeAddress)
            }

            // Common Locations
            Section(header: Text("📍 Common Locations")) {
                ForEach(preferences.commonLocations) { location in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(location.name).bold()
                            Text(location.address).font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            preferences.commonLocations.removeAll { $0.id == location.id }
                            preferences.save()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Name", text: $newLocationName)
                    TextField("Address", text: $newLocationAddress)
                    Button("Add Location") {
                        let new = SavedLocation(name: newLocationName, address: newLocationAddress)
                        preferences.commonLocations.append(new)
                        preferences.save()
                        newLocationName = ""
                        newLocationAddress = ""
                    }
                    .disabled(newLocationName.isEmpty || newLocationAddress.isEmpty)
                }
                .padding(.vertical, 4)
            }

            // Wake / Sleep Time
            Section(header: Text("⏰ Wake / Sleep Time")) {
                DatePicker("Wake Up Time", selection: $preferences.wakeUpTime, displayedComponents: .hourAndMinute)
                DatePicker("Sleep Time", selection: $preferences.sleepTime, displayedComponents: .hourAndMinute)
            }

            // Notification Toggles
            Section(header: Text("🔔 Notifications")) {
                Toggle("Task Reminders", isOn: $preferences.notifyReminders)
                Toggle("Upcoming Tasks", isOn: $preferences.notifyUpcomingTasks)
                Toggle("Travel Warnings", isOn: $preferences.notifyTravelWarnings)
            }

            // Travel Mode Settings
            Section(header: Text("🚗 Travel Mode")) {
                Picker("Mode", selection: $travelMode) {
                    Text("🚗 Driving").tag("driving")
                    Text("🚶 Walking").tag("walking")
                    Text("🚌 Transit").tag("transit")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("Settings")
        .onDisappear {
            preferences.save()
        }
    }
}
