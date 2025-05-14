//
//  AIRescheduleService.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//
import Foundation

// Handles sending rescheduling requests to OpenAI using GPT
struct AIRescheduleService {
    // Sends a prompt to GPT and returns the JSON-formatted rescheduled task list
    static func requestReschedulePlan(prompt: String) async throws -> String {
        print("🚀 Starting GPT reschedule request")
        
        // Ensure the API key is available
        guard let apiKey = PlannerService.shared.apiKey else {
            print("❌ Missing OpenAI API key from PlannerService")
            throw URLError(.userAuthenticationRequired)
        }


        let urlString = "https://api.openai.com/v1/chat/completions"
        print("🌍 Targeting URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            throw URLError(.badURL)
        }

        // Prepare the API request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are a helpful scheduling assistant. Your job is to schedule only the tasks provided under 'Here are the tasks' based on the user's time constraints and urgency.

                    Do not include any events from 'scheduled events' or use them in your output — they are just for context to avoid conflicts.

                    Each scheduled task should be returned in this format:

                    {
                      "id": "UUID-string-matching-the-task-id",
                      "title": "Task title",
                      "start_time": "ISO8601 datetime string",
                      "duration": number (in minutes),
                      "urgency": "Low" | "Medium" | "High",
                      "location": "String (or 'Anywhere')",
                      "timeSensitivityType": "startsAt" | "dueBy" 
                    }

                    ✅ Only return a JSON array of these scheduled tasks. Do not include any explanation, markdown, or commentary — just the JSON array.
                    """
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7
        ]

        // Serialize the JSON request body
        print("🧪 Attempting to serialize request body")
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted])
            request.httpBody = bodyData

            if let jsonString = String(data: bodyData, encoding: .utf8) {
                print("📤 GPT Request JSON Body:\n\(jsonString)")
            } else {
                print("⚠️ Could not convert bodyData to UTF-8 string")
            }
        } catch {
            print("❌ JSON encoding failed: \(error.localizedDescription)")
            throw error
        }
        // Perform the network request
        do {
            print("📡 Sending request to GPT...")
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📬 Response status code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "<non-UTF8 response>"
                    print("❌ GPT Error Response:\n\(errorMessage)")
                    throw URLError(.badServerResponse)
                }
            }

            print("✅ Got data back from GPT")
            
            // Decode the OpenAI chat response
            let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            guard let firstChoice = decoded.choices.first else {
                print("❌ GPT response had no choices")
                throw URLError(.badServerResponse)
            }

            print("📥 GPT Response Content:\n\(firstChoice.message.content)")
            return firstChoice.message.content
        } catch {
            print("❌ GPT request failed: \(error.localizedDescription)")
            throw error
        }
    }
}
// Model to decode GPT chat responses
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
