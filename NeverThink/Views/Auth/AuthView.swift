//
//  AuthView.swift
//  NeverThink
//
import SwiftUI

// The initial welcome screen for the NeverThink app
struct AuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        ZStack {
            // Real gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.85, green: 0.9, blue: 1.0), // Light lavender blue
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                // App title and subtitle
                VStack(spacing: 12) {
                    Text("Welcome to NeverThink")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Organize your day effortlessly.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
                // Sign In button triggers app's sign-in state
                Button(action: {
                    authManager.signIn()
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }

                Spacer()
            }
        }
    }
}
