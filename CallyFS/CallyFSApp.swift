//
//  CallyFSApp.swift
//  CallyFS
//

import SwiftUI
import SwiftData

@main
struct CallyFSApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                MealLog.self,
                WaterLog.self,
                WorkoutLog.self,
                DailyGoals.self,
                MealPlan.self
            ])
            
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnBoardingView()
            }
        }
        .modelContainer(container)
    }
}
