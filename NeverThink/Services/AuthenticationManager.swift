//
//  AuthenticationManager 2.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/30/25.
//
import SwiftUI
import Foundation


class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isSignedIn: Bool = false
    @Published private(set) var hasSetHomeAddress: Bool = false

    @Published var homeAddress: String {
        didSet {
            let trimmed = homeAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            hasSetHomeAddress = !trimmed.isEmpty
            UserDefaults.standard.set(trimmed, forKey: "homeAddress")
        }
    }

    private init() {
        let savedAddress = UserDefaults.standard.string(forKey: "homeAddress") ?? ""
        self.homeAddress = savedAddress
        self.hasSetHomeAddress = !savedAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func signIn() {
        isSignedIn = true
    }

    func signOut() {
        isSignedIn = false
        homeAddress = ""
        hasSetHomeAddress = false
        UserDefaults.standard.removeObject(forKey: "homeAddress")
    }

    func saveHomeAddress(_ address: String) {
        self.homeAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
