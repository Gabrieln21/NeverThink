//
//  SavedLocation.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/3/25.
//
import Foundation

// Represents a user-saved location with a display name and address.
// Used for quick access to frequently used places (e.g., "Home", "Gym").
struct SavedLocation: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var address: String
}
