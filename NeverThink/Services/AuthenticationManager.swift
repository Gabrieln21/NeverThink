// AuthenticationManager.swift
import SwiftUI

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isSignedIn: Bool = false
    @Published var hasSetHomeAddress: Bool = false
    @Published var homeAddress: String = ""

    func signIn() {
        isSignedIn = true
    }

    func signOut() {
        isSignedIn = false
        hasSetHomeAddress = false
        homeAddress = ""
    }

    func saveHomeAddress(_ address: String) {
        homeAddress = address
        hasSetHomeAddress = true
    }
}
