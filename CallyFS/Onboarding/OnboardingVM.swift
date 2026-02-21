//
//  OnboardingVM.swift
//  CallyFS
//

import Foundation
import SwiftUI
import HealthKit

@MainActor
final class OnboardingVM: ObservableObject {
    
    // MARK: - Published State
    
//    @Published var currentStep: OnboardingStep = .welcome
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
    
    // MARK: - Navigation
    
    
   
    
    // MARK: - HealthKit
    
    func requestHealthAccessAndFetch() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await healthManager.requestPermissions()
            let snapshot = try await healthManager.fetchInitialData()
            populateFromHealthSnapshot(snapshot)
//            nextStep()
        } catch {
            
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func populateFromHealthSnapshot(_ snapshot: HealthKitManager.HealthSnapshot) {
        
        if snapshot.age > 0 {
            age = String(snapshot.age)
        }
        
        if snapshot.weight > 0 {
            weight = String(format: "%.1f", snapshot.weight)
        }
        
        if snapshot.height > 0 {
            height = String(format: "%.2f", snapshot.height)
        }
        
        switch snapshot.biologicalSex {
        case .male: sex = .male
        case .female: sex = .female
        case .other: sex = .other
        default: sex = .notSet
        }
    }
    
    // MARK: - Goal Calculation
    
    
    
    // MARK: - Completion
    
    private func completeOnboarding() {
        saveUserProfile()
        hasCompletedOnboarding = true
    }
    
    private func saveUserProfile() {
        // You can later replace this with CoreData / Supabase / local JSON
        
        let profile: [String: Any] = [
            "userName": userName,
            "age": age,
            "weight": weight,
            "height": height,
            "sex": sex.rawValue,
            "calories": targetCalories,
            "protein": targetProtein,
            "carbs": targetCarbs,
            "fat": targetFat
        ]
        
        UserDefaults.standard.set(profile, forKey: "userProfile")
    }
}

// MARK: - Supporting Types


enum Sex: String, CaseIterable {
    case notSet = "Prefer not to say"
    case male = "Male"
    case female = "Female"
    case other = "Other"
    
    var healthKitValue: HKBiologicalSex {
        switch self {
        case .notSet:
            return .notSet
        case .male:
            return .male
        case .female:
            return .female
        case .other:
            return .other
        }
    }
}
