//
//  AIService.swift
//  CallyFS
//

import Foundation

struct NutritionResponse: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct MealPlanResponse: Codable {
    let plan: String
    let dailyBreakdown: [DayMeals]?
    
    struct DayMeals: Codable {
        let day: Int
        let breakfast: String
        let lunch: String
        let dinner: String
        let snacks: String?
    }
}

final class AIService {
    static let shared = AIService()
    
    private var apiKey: String {
        APIKeyManager.shared.getAPIKey() ?? ""
    }
    
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    private init() {}
    
    // MARK: - Nutrition Analysis
    
    func getNutritionInfo(for mealName: String) async throws -> NutritionResponse {
        guard !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
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
        
        Provide realistic estimates based on typical serving sizes. Be accurate and conservative.
        """
        
        let requestBody: [String: Any] = [
            "model": "openai/gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 150
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }
        
        let cleanedContent = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw AIServiceError.parsingFailed
        }
        
        let nutrition = try JSONDecoder().decode(NutritionResponse.self, from: jsonData)
        return nutrition
    }
    
    // MARK: - Meal Plan Generation
    
    func generateMealPlan(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        goal: FitnessGoal,
        dietaryRestrictions: [String],
        duration: Int = 7
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let restrictions = dietaryRestrictions.isEmpty ? "None" : dietaryRestrictions.joined(separator: ", ")
        
        let prompt = """
        Create a detailed \(duration)-day meal plan for someone with the following requirements:
        
        Daily Targets:
        - Calories: \(Int(calories)) kcal
        - Protein: \(Int(protein))g
        - Carbs: \(Int(carbs))g
        - Fat: \(Int(fat))g
        
        Fitness Goal: \(goal.rawValue)
        Dietary Restrictions: \(restrictions)
        
        Please provide:
        1. A complete \(duration)-day meal plan with breakfast, lunch, dinner, and snacks
        2. Each meal should include specific foods and approximate portions
        3. Ensure meals are varied, delicious, and easy to prepare
        4. Include approximate macros for each meal
        5. Add helpful cooking tips where relevant
        
        Format the response in a clear, readable way with day-by-day breakdown.
        """
        
        let requestBody: [String: Any] = [
            "model": "openai/gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a professional nutritionist and meal planning expert. Create detailed, practical meal plans that are delicious and easy to follow."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 3000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }
        
        return content
    }
    
    // MARK: - Personalized Insights
    
    func generateInsights(
        weeklyCalories: Double,
        weeklyProtein: Double,
        weeklyCarbs: Double,
        weeklyFat: Double,
        goal: FitnessGoal,
        targetCalories: Double
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let avgDaily = weeklyCalories / 7
        let variance = ((avgDaily - targetCalories) / targetCalories) * 100
        
        let prompt = """
        Analyze this week's nutrition data and provide personalized insights:
        
        Weekly Totals:
        - Calories: \(Int(weeklyCalories)) kcal (avg \(Int(avgDaily))/day)
        - Protein: \(Int(weeklyProtein))g
        - Carbs: \(Int(weeklyCarbs))g
        - Fat: \(Int(weeklyFat))g
        
        Target: \(Int(targetCalories)) kcal/day
        Variance: \(String(format: "%.1f", variance))%
        Goal: \(goal.rawValue)
        
        Provide:
        1. Brief assessment of progress (2-3 sentences)
        2. 2-3 specific actionable recommendations
        3. One motivational insight
        
        Keep it concise, positive, and actionable. Maximum 150 words.
        """
        
        let requestBody: [String: Any] = [
            "model": "openai/gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a supportive fitness coach providing brief, actionable nutrition insights."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 300
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }
        
        return content
    }
}

// MARK: - Supporting Types

struct OpenRouterResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case serverError(statusCode: Int)
    case noContent
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured. Please add your OpenRouter API key in Settings."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let code):
            return "Server error (code: \(code)). Please try again."
        case .noContent:
            return "No content received from AI service."
        case .parsingFailed:
            return "Failed to parse AI response."
        }
    }
}
