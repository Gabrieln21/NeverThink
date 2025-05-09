// AuthView.swift
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to PlanMee!")
                .font(.largeTitle)
                .bold()

            Text("Please sign in to continue.")
                .foregroundColor(.gray)

            Button(action: {
                authManager.signIn()
            }) {
                Text("Sign In")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}
