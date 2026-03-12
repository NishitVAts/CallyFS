//
//  PersonalizedPlan.swift
//  CallyFS
//

import Foundation

struct PersonalizedPlan: Codable {
    let title: String
    let overview: String
    let weeklyGoals: [String]
    let nutritionTips: [String]
    let workoutSuggestions: [String]
    let motivationalMessage: String
    let createdAt: Date
    
    let macroBreakdown: MacroBreakdown
    let timeline: Timeline
    let smallSteps: [SmallStep]
    let insights: [Insight]
    
    init(title: String, overview: String, weeklyGoals: [String], nutritionTips: [String], workoutSuggestions: [String], motivationalMessage: String, macroBreakdown: MacroBreakdown, timeline: Timeline, smallSteps: [SmallStep], insights: [Insight], createdAt: Date = Date()) {
        self.title = title
        self.overview = overview
        self.weeklyGoals = weeklyGoals
        self.nutritionTips = nutritionTips
        self.workoutSuggestions = workoutSuggestions
        self.motivationalMessage = motivationalMessage
        self.macroBreakdown = macroBreakdown
        self.timeline = timeline
        self.smallSteps = smallSteps
        self.insights = insights
        self.createdAt = createdAt
    }
    
    struct MacroBreakdown: Codable {
        let dailyCalories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let reasoning: String
    }
    
    struct Timeline: Codable {
        let estimatedWeeks: Int
        let milestones: [Milestone]
        
        struct Milestone: Codable {
            let week: Int
            let description: String
            let expectedProgress: String
        }
    }
    
    struct SmallStep: Codable {
        let action: String
        let impact: String
        let difficulty: String
    }
    
    struct Insight: Codable {
        let category: String
        let message: String
        let priority: String
    }
}

struct OnboardingMetrics: Codable {
    let goal: String
    let workoutFrequency: String
    let hasTrackedBefore: Bool
    let barriers: [String]
    let dietRequirements: [String]
    let targetCalories: Double
    let targetProtein: Double
    let targetCarbs: Double
    let targetFat: Double
    let currentWeight: Double
    let goalWeight: Double
    let height: Double
    let age: Int
    let sex: String
    let desiredBodyFat: Double?
}
