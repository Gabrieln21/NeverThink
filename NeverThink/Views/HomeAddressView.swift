//
//  HomeAddressView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import SwiftUI

struct HomeAddressView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var address: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Set Your Home Address 🏡")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)

            Text("Your home address helps PlanMee create smarter, more accurate schedules and travel times. It only needs to be set once.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()

            TextField("Enter approximate address", text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                authManager.saveHomeAddress(address)
            }) {
                Text("Save Address")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .disabled(address.isEmpty)
        }
        .padding()
    }
}
