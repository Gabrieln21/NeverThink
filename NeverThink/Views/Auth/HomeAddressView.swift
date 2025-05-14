//
//  HomeAddressView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

// View for collecting the user's home address. Used for location-based scheduling
struct HomeAddressView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var address: String = ""

    var body: some View {
        ZStack {
            // Background Gradient (same as Sign In)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.85, green: 0.9, blue: 1.0), // Light pastel blue/lavender
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                // Title and instructions
                VStack(spacing: 12) {
                    Text("Set Your Home Base 🏡")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Your home location helps NeverThink create smarter routes and schedules. This only needs to be set once.")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                // Address entry and submission
                VStack(spacing: 16) {
                    TextField("Enter approximate address", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.top, 8)
                    // Save button stores the address via the AuthenticationManager
                    Button(action: {
                        authManager.saveHomeAddress(address)
                    }) {
                        Text("Save Address")
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
                    .disabled(address.isEmpty) // Disable save button if no input
                }
                .padding(.top, 24)

                Spacer()
            }
        }
    }
}
