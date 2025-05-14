//
//  AuthenticationManager 2.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/30/25.
//

import SwiftUI
import Foundation

// Manages simple authentication state and persistent storage of the user's home address.
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isSignedIn: Bool = false
    @Published private(set) var hasSetHomeAddress: Bool = false

    // The user’s saved home address; automatically persisted to UserDefaults
    @Published var homeAddress: String {
        didSet {
            let trimmed = homeAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            hasSetHomeAddress = !trimmed.isEmpty
            UserDefaults.standard.set(trimmed, forKey: "homeAddress")
        }
    }

    // Loads the saved home address from disk and checks if it's valid
    private init() {
        let savedAddress = UserDefaults.standard.string(forKey: "homeAddress") ?? ""
        self.homeAddress = savedAddress
        self.hasSetHomeAddress = !savedAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Marks the user as signed in
    func signIn() {
        isSignedIn = true
    }

    // Signs the user out and clears the stored home address
    func signOut() {
        isSignedIn = false
        homeAddress = ""
        hasSetHomeAddress = false
        UserDefaults.standard.removeObject(forKey: "homeAddress")
    }

    // Manually updates the stored home address (trims and stores it)
    func saveHomeAddress(_ address: String) {
        self.homeAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
