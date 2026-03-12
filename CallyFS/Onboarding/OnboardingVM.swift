//
//  OnboardingVM.swift
//  CallyFS
//

import Foundation
import SwiftUI
import HealthKit

@MainActor
final class OnboardingVM: ObservableObject {

    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    @Published var userName: String = ""
    @Published var age: String = ""
    @Published var weight: String = ""
    @Published var height: String = ""
    @Published var sex: Sex = .notSet

    @Published var targetCalories: Double = 2000
    @Published var targetProtein: Double = 150
    @Published var targetCarbs: Double = 200
    @Published var targetFat: Double = 65

    private let healthManager = HealthKitManager.shared

    // MARK: - HealthKit

    func requestHealthAccessAndFetch() async {
        isLoading = true
        errorMessage = nil
        do {
            try await healthManager.requestPermissions()
            let snapshot = try await healthManager.fetchInitialData()
            print("🔍 HealthKit Snapshot - Age: \(snapshot.age), Weight: \(snapshot.weight), Height: \(snapshot.height), Sex: \(snapshot.biologicalSex.rawValue)")
            populateFromSnapshot(snapshot)
            print("✅ After population - Age: \(age), Weight: \(weight), Height: \(height), Sex: \(sex.rawValue)")
        } catch {
            print("❌ HealthKit Error: \(error)")
            errorMessage = "Health data unavailable. You can enter details manually."
        }
        isLoading = false
    }

    private func populateFromSnapshot(_ snapshot: HealthKitManager.HealthSnapshot) {
        if snapshot.age > 0    { 
            age = String(snapshot.age)
            print("📝 Set age: \(age)")
        }
        if snapshot.weight > 0 { 
            weight = String(format: "%.1f", snapshot.weight)
            print("📝 Set weight: \(weight)")
        }
        if snapshot.height > 0 { 
            height = String(format: "%.4f", snapshot.height)
            print("📝 Set height: \(height)")
        }
        switch snapshot.biologicalSex {
        case .male:   
            sex = .male
            print("📝 Set sex: male")
        case .female: 
            sex = .female
            print("📝 Set sex: female")
        case .other:  
            sex = .other
            print("📝 Set sex: other")
        default:      
            sex = .notSet
            print("📝 Set sex: notSet")
        }
    }

    // MARK: - Finalize

    func finalizeAndSave(
        workouts: workoutRange,
        goal: FitnessGoal,
        hasTrackedBefore: Bool,
        barriers: Set<Barrier>,
        dietRequirements: Set<DietRequirement>
    ) {
        let ageYears = Int(age) ?? 25
        calculateGoals(workouts: workouts, goal: goal, ageYears: ageYears)
        persist(workouts: workouts, goal: goal, hasTrackedBefore: hasTrackedBefore,
                barriers: barriers, dietRequirements: dietRequirements)
        hasCompletedOnboarding = true
    }

    private func calculateGoals(workouts: workoutRange, goal: FitnessGoal, ageYears: Int) {
        let weightKg = Double(weight) ?? 70.0
        let heightCm = (Double(height) ?? 1.70) * 100

        let bmr: Double
        switch sex {
        case .male:
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears)) + 5
        case .female:
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears)) - 161
        default:
            let m = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears)) + 5
            let f = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears)) - 161
            bmr = (m + f) / 2
        }

        let tdee = bmr * workouts.activityMultiplier
        switch goal {
        case .lose:               targetCalories = tdee - 500
        case .gain:               targetCalories = tdee + 400
        case .maintain, .improve: targetCalories = tdee
        case .notSet:             targetCalories = 2000
        }

        switch goal {
        case .lose:
            targetProtein = weightKg * 2.0; targetFat = weightKg * 0.8
        case .gain:
            targetProtein = weightKg * 2.2; targetFat = weightKg * 1.0
        default:
            targetProtein = weightKg * 1.8; targetFat = weightKg * 0.9
        }
        targetCarbs = max((targetCalories - targetProtein * 4 - targetFat * 9) / 4, 0)
    }

    private func persist(workouts: workoutRange, goal: FitnessGoal, hasTrackedBefore: Bool,
                         barriers: Set<Barrier>, dietRequirements: Set<DietRequirement>) {
        let profile: [String: Any] = [
            "userName": userName, "age": age, "weight": weight, "height": height,
            "sex": sex.rawValue, "workouts": workouts.rawValue, "goal": goal.rawValue,
            "hasTrackedBefore": hasTrackedBefore,
            "barriers": barriers.map { $0.rawValue },
            "dietRequirements": dietRequirements.map { $0.rawValue },
            "calories": targetCalories, "protein": targetProtein,
            "carbs": targetCarbs, "fat": targetFat
        ]
        UserDefaults.standard.set(profile, forKey: "userProfile")
    }
}
