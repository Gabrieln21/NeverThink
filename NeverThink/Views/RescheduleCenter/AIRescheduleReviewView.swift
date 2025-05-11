//
//  AIRescheduleReviewView.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//

import SwiftUI

struct AIRescheduleReviewView: View {
    var aiPlanText: String
    var onAccept: () -> Void
    var onRegenerate: (String) -> Void
    
    @State private var userNotes: String = ""
    

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("🧠 AI Proposed Plan")
                        .font(.title2)
                        .bold()

                    Text(aiPlanText)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("📝 Add Notes for GPT (Optional)")
                            .font(.headline)
                        TextEditor(text: $userNotes)
                            .frame(height: 150)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                    }
                    
                    VStack(spacing: 12) {
                        Button("✅ Accept This Plan") {
                            onAccept()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)

                        Button("🔄 Regenerate Plan With Notes") {
                            onRegenerate(userNotes)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Review Plan")
        }
    }
}
