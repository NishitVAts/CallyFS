//
//  OpenRouterService.swift
//  CallyFS
//

import Foundation

struct NutritionResponse: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

class OpenRouterService {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey.isEmpty ? (ProcessInfo.processInfo.environment["openRouterKey"] ?? "") : apiKey
    }
    
    func getNutritionInfo(for mealName: String) async throws -> NutritionResponse {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        Analyze the following meal and provide nutritional information in JSON format.
        
        Meal: \(mealName)
        
        Respond ONLY with a valid JSON object in this exact format (no markdown, no explanations):
        {
            "calories": <number>,
            "protein": <number>,
            "carbs": <number>,
            "fat": <number>
        }
        
        Provide realistic estimates based on typical serving sizes.
        """
        
        let requestBody: [String: Any] = [
            "model": "openai/gpt-3.5-turbo",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 150
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message.content else {
            throw URLError(.cannotParseResponse)
        }
        
        let cleanedContent = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        let nutrition = try JSONDecoder().decode(NutritionResponse.self, from: jsonData)
        return nutrition
    }
}

struct OpenRouterResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}
