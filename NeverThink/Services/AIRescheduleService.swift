//
//  AIRescheduleService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//

import Foundation

struct AIRescheduleService {
    static func requestReschedulePlan(prompt: String) async throws -> String {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            throw URLError(.badURL)
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful scheduling assistant. Reply with a clear daily plan."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let firstChoice = decoded.choices.first else {
            throw URLError(.badServerResponse)
        }
        
        return firstChoice.message.content
    }
}

struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    
    let choices: [Choice]
}
