//
//  MealLog.swift
//  CallyFS
//

import Foundation
import SwiftData

struct MealSlot {
    enum SlotType: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snacks = "Snacks"
        
        var emoji: String {
            switch self {
            case .breakfast: return "🌅"
            case .lunch: return "☀️"
            case .dinner: return "🌙"
            case .snacks: return "🍿"
            }
        }
    }
}

@Model
final class MealLog {
    var id: UUID
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var emoji: String
    var timestamp: Date
    var mealType: String
    var isAIGenerated: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        emoji: String,
        timestamp: Date = Date(),
        mealType: String,
        isAIGenerated: Bool = true
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.emoji = emoji
        self.timestamp = timestamp
        self.mealType = mealType
        self.isAIGenerated = isAIGenerated
    }
}

@Model
final class WaterLog {
    var id: UUID
    var amount: Double
    var timestamp: Date
    var unit: String
    
    init(
        id: UUID = UUID(),
        amount: Double,
        timestamp: Date = Date(),
        unit: String = "ml"
    ) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.unit = unit
    }
}

@Model
final class WorkoutLog {
    var id: UUID
    var name: String
    var duration: Int
    var caloriesBurned: Int
    var timestamp: Date
    var workoutType: String
    var notes: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        duration: Int,
        caloriesBurned: Int,
        timestamp: Date = Date(),
        workoutType: String,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.timestamp = timestamp
        self.workoutType = workoutType
        self.notes = notes
    }
}

@Model
final class DailyGoals {
    var id: UUID
    var date: Date
    var targetCalories: Double
    var targetProtein: Double
    var targetCarbs: Double
    var targetFat: Double
    var targetWater: Double
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        targetCalories: Double,
        targetProtein: Double,
        targetCarbs: Double,
        targetFat: Double,
        targetWater: Double = 2000
    ) {
        self.id = id
        self.date = date
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.targetWater = targetWater
    }
}

@Model
final class MealPlan {
    var id: UUID
    var name: String
    var aiGeneratedPlan: String
    var createdAt: Date
    var isActive: Bool
    var duration: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        aiGeneratedPlan: String,
        createdAt: Date = Date(),
        isActive: Bool = false,
        duration: Int = 7
    ) {
        self.id = id
        self.name = name
        self.aiGeneratedPlan = aiGeneratedPlan
        self.createdAt = createdAt
        self.isActive = isActive
        self.duration = duration
    }
}
