//
//  UserModel.swift
//  CallyFS
//
//  Created by Nishit Vats on 10/02/26.
//

import Foundation
import HealthKit
import SwiftUI

// MARK: - Nutrition Metrics
struct NutritionMetrics {
    var calories: Double = 0.0
    var protein: Double = 0.0
    var carbs: Double = 0.0
    var fat: Double = 0.0
}

// MARK: - User Profile
class UserProfile: ObservableObject {
    
    // MARK: - Identity
    @Published var name: String = "User"
    
    // MARK: - Demographics (From HealthKit & Onboarding)
    @Published var age: Int = 0
    @Published var dateOfBirth: Date = Date()
    @Published var biologicalSex: HKBiologicalSex = .notSet
    @Published var sex: Sex = .notSet
    
    // MARK: - Body Measurements (From HealthKit)
    @Published var height: Double = 0.0 // Meters
    @Published var weight: Double = 0.0 // Kilograms
    
    // MARK: - Activity Data (From HealthKit)
    @Published var stepCount: Int = 0
    @Published var activeEnergyBurned: Double = 0.0 // "Move" calories
    @Published var restingEnergyBurned: Double = 0.0 // BMR / "Exist" calories
    
    // MARK: - Fitness & Goals (From Onboarding)
    @Published var fitnessGoal: FitnessGoal = .notSet
    @Published var workoutFrequency: workoutRange = .nowAndThen
    @Published var hasUsedCalorieTrackingBefore: Bool = false
    @Published var barriers: Set<Barrier> = []
    @Published var dietaryRequirements: Set<DietRequirement> = []
    
    // MARK: - Diet Tracking (Shared TO HealthKit)
    @Published var consumed: NutritionMetrics = NutritionMetrics()
    @Published var goals: NutritionMetrics = NutritionMetrics(calories: 2000, protein: 150, carbs: 200, fat: 65)
    
    // MARK: - Onboarding Status
    @Published var hasCompletedOnboarding: Bool = false
    @Published var appleHealthConnected: Bool = false
    
    // MARK: - Computed Properties
    
    var bmi: Double {
        guard height > 0 else { return 0.0 }
        return weight / (height * height)
    }
    
    var bmiCategory: String {
        let bmiValue = bmi
        switch bmiValue {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    var totalEnergyExpenditure: Double {
        return activeEnergyBurned + restingEnergyBurned
    }
    
    var remainingCalories: Double {
        return goals.calories - consumed.calories
    }
    
    var calorieProgress: Double {
        guard goals.calories > 0 else { return 0.0 }
        return consumed.calories / goals.calories
    }
    
    var proteinProgress: Double {
        guard goals.protein > 0 else { return 0.0 }
        return consumed.protein / goals.protein
    }
    
    var carbsProgress: Double {
        guard goals.carbs > 0 else { return 0.0 }
        return consumed.carbs / goals.carbs
    }
    
    var fatProgress: Double {
        guard goals.fat > 0 else { return 0.0 }
        return consumed.fat / goals.fat
    }
    
    // Calculate TDEE (Total Daily Energy Expenditure) based on user data
    var estimatedTDEE: Double {
        let bmr = calculateBMR()
        let activityMultiplier = workoutFrequency.activityMultiplier
        return bmr * activityMultiplier
    }
    
    // MARK: - Methods
    
    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
    func calculateBMR() -> Double {
        guard height > 0, weight > 0, age > 0 else { return 0.0 }
        
        let heightInCm = height * 100
        let weightInKg = weight
        
        switch biologicalSex {
        case .male:
            // BMR = (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years) + 5
            return (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) + 5
        case .female:
            // BMR = (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years) − 161
            return (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) - 161
        default:
            // Use average of both formulas for other/not set
            let maleFormula = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) + 5
            let femaleFormula = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) - 161
            return (maleFormula + femaleFormula) / 2
        }
    }
    
    /// Calculate recommended calorie goals based on fitness goal
    func calculateCalorieGoals() {
        let tdee = estimatedTDEE
        
        switch fitnessGoal {
        case .lose:
            // 500 calorie deficit for ~1 lb/week loss
            goals.calories = tdee - 500
        case .gain:
            // 300-500 calorie surplus for muscle gain
            goals.calories = tdee + 400
        case .maintain, .improve:
            goals.calories = tdee
        case .notSet:
            goals.calories = 2000 // Default
        }
        
        // Calculate macros based on goal
        calculateMacroGoals()
    }
    
    /// Calculate recommended macro distribution
    func calculateMacroGoals() {
        switch fitnessGoal {
        case .lose:
            // Higher protein for satiety and muscle preservation
            goals.protein = weight * 2.0 // 2g per kg bodyweight
            goals.fat = weight * 0.8 // 0.8g per kg
            let remainingCalories = goals.calories - (goals.protein * 4) - (goals.fat * 9)
            goals.carbs = remainingCalories / 4
            
        case .gain:
            // Balanced macros with emphasis on protein
            goals.protein = weight * 2.2 // 2.2g per kg bodyweight
            goals.fat = weight * 1.0 // 1g per kg
            let remainingCalories = goals.calories - (goals.protein * 4) - (goals.fat * 9)
            goals.carbs = remainingCalories / 4
            
        case .maintain, .improve:
            // Balanced approach
            goals.protein = weight * 1.8 // 1.8g per kg
            goals.fat = weight * 0.9 // 0.9g per kg
            let remainingCalories = goals.calories - (goals.protein * 4) - (goals.fat * 9)
            goals.carbs = remainingCalories / 4
            
        case .notSet:
            // Default balanced macros
            goals.protein = 150
            goals.carbs = 200
            goals.fat = 65
        }
    }
    
    /// Update demographics from HealthKit
    func updateDemographics(dob: DateComponents?, sex: HKBiologicalSexObject?) {
        // Calculate Age
        if let dobDate = Calendar.current.date(from: dob ?? DateComponents()) {
            let ageComponents = Calendar.current.dateComponents([.year], from: dobDate, to: Date())
            self.age = ageComponents.year ?? 0
            self.dateOfBirth = dobDate
        }
        
        // Update Sex
        if let sexObj = sex {
            self.biologicalSex = sexObj.biologicalSex
        }
    }
    
    /// Update from onboarding data
    func updateFromOnboarding(
        name: String,
        sex: Sex,
        heightInCm: Double,
        weightInKg: Double,
        dob: Date,
        goal: FitnessGoal,
        workouts: workoutRange,
        hasTrackedBefore: Bool,
        barriers: Set<Barrier>,
        dietRequirements: Set<DietRequirement>
    ) {
        self.name = name
        self.sex = sex
        self.biologicalSex = sex.healthKitValue
        self.height = heightInCm / 100.0 // Convert cm to meters
        self.weight = weightInKg
        self.dateOfBirth = dob
        self.fitnessGoal = goal
        self.workoutFrequency = workouts
        self.hasUsedCalorieTrackingBefore = hasTrackedBefore
        self.barriers = barriers
        self.dietaryRequirements = dietRequirements
        
        // Calculate age
        let ageComponents = Calendar.current.dateComponents([.year], from: dob, to: Date())
        self.age = ageComponents.year ?? 0
        
        // Calculate personalized goals
        calculateCalorieGoals()
        
        // Mark onboarding as complete
        self.hasCompletedOnboarding = true
    }
    
    /// Save user profile to UserDefaults (simple persistence)
    func saveToUserDefaults() {
        let encoder = JSONEncoder()
        // Note: You'll need to make UserProfile Codable for this to work
        // For now, save individual properties
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(height, forKey: "userHeight")
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(goals.calories, forKey: "goalCalories")
        UserDefaults.standard.set(goals.protein, forKey: "goalProtein")
        UserDefaults.standard.set(goals.carbs, forKey: "goalCarbs")
        UserDefaults.standard.set(goals.fat, forKey: "goalFat")
    }
    
    /// Load user profile from UserDefaults
    func loadFromUserDefaults() {
        name = UserDefaults.standard.string(forKey: "userName") ?? "User"
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        height = UserDefaults.standard.double(forKey: "userHeight")
        weight = UserDefaults.standard.double(forKey: "userWeight")
        goals.calories = UserDefaults.standard.double(forKey: "goalCalories")
        goals.protein = UserDefaults.standard.double(forKey: "goalProtein")
        goals.carbs = UserDefaults.standard.double(forKey: "goalCarbs")
        goals.fat = UserDefaults.standard.double(forKey: "goalFat")
    }
}





