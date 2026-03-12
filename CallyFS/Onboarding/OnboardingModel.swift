//
//  OnboardingModel.swift
//  CallyFS
//
//  Single source of truth for all shared enums used across Onboarding, UserModel, and VM.
//  Do NOT declare these enums anywhere else in the project.
//

import Foundation
import HealthKit

// MARK: - Sex

enum Sex: String, CaseIterable {
    case notSet = "Prefer not to say"
    case male   = "Male"
    case female = "Female"
    case other  = "Other"

    var healthKitValue: HKBiologicalSex {
        switch self {
        case .notSet:  return .notSet
        case .male:    return .male
        case .female:  return .female
        case .other:   return .other
        }
    }
}

// MARK: - Workout Range

enum workoutRange: String, CaseIterable {
    case nowAndThen = "Workouts now and then"
    case few        = "A few workouts per week"
    case athelete   = "Dedicated Athlete"

    var activityMultiplier: Double {
        switch self {
        case .nowAndThen: return 1.2
        case .few:        return 1.55
        case .athelete:   return 1.725
        }
    }

    var description: String {
        switch self {
        case .nowAndThen: return "1-2 workouts per week"
        case .few:        return "3-5 workouts per week"
        case .athelete:   return "6+ workouts per week"
        }
    }

    var summaryLabel: String {
        switch self {
        case .nowAndThen: return "Casual"
        case .few:        return "Regular"
        case .athelete:   return "Athlete"
        }
    }
}

// MARK: - Fitness Goal

enum FitnessGoal: String, CaseIterable {
    case notSet   = "Not Set"
    case lose     = "Lose Weight"
    case gain     = "Gain Muscle"
    case maintain = "Maintain Weight"
    case improve  = "Improve Fitness"

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .notSet:   return ""
        case .lose:     return "Achieve a caloric deficit"
        case .gain:     return "Build muscle with surplus"
        case .maintain: return "Stay at current weight"
        case .improve:  return "Get stronger and healthier"
        }
    }
}

// MARK: - Barrier

enum Barrier: String, CaseIterable {
    case timeConstraints   = "Time Constraints"
    case motivation        = "Staying Motivated"
    case tracking          = "Consistent Tracking"
    case cookingSkills     = "Cooking Skills"
    case budgetConstraints = "Budget Constraints"
    case socialSituations  = "Social Situations"
}

// MARK: - Diet Requirement

enum DietRequirement: String, CaseIterable {
    case none        = "No Restrictions"
    case vegetarian  = "Vegetarian"
    case vegan       = "Vegan"
    case glutenFree  = "Gluten-Free"
    case dairyFree   = "Dairy-Free"
    case keto        = "Keto"
    case paleo       = "Paleo"
    case halal       = "Halal"
    case kosher      = "Kosher"
}

// MARK: - Onboarding Screens

enum OnboardingScreens: CaseIterable {
    case applehealth
    case gender
    case workouts
    case previousExperience
    case weightScreen
    case height
    case dob
    case goalSelection
    case barriers
    case specificDietRequirements
    case userName
    case thankyou

    var stepNumber: Int {
        OnboardingScreens.allCases.firstIndex(of: self) ?? 0
    }

    func next() -> OnboardingScreens? {
        let all = OnboardingScreens.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    func back() -> OnboardingScreens? {
        let all = OnboardingScreens.allCases
        guard let idx = all.firstIndex(of: self), idx > 0 else { return nil }
        return all[idx - 1]
    }
}
