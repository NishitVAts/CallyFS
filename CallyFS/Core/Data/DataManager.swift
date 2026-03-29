//
//  DataManager.swift
//  CallyFS
//

import Foundation
import SwiftData

@MainActor
final class DataManager {
    static let shared = DataManager()
    
    let container: ModelContainer
    let context: ModelContext
    
    private init() {
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
            context = ModelContext(container)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - Meal Logs
    
    func saveMeal(_ meal: MealLog) throws {
        context.insert(meal)
        try context.save()
    }
    
    func fetchMeals(for date: Date) throws -> [MealLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<MealLog> { meal in
            meal.timestamp >= startOfDay && meal.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<MealLog>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        return try context.fetch(descriptor)
    }
    
    func fetchAllMeals() throws -> [MealLog] {
        let descriptor = FetchDescriptor<MealLog>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    func deleteMeal(_ meal: MealLog) throws {
        context.delete(meal)
        try context.save()
    }
    
    // MARK: - Water Logs
    
    func saveWater(_ water: WaterLog) throws {
        context.insert(water)
        try context.save()
    }
    
    func fetchWaterLogs(for date: Date) throws -> [WaterLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<WaterLog> { water in
            water.timestamp >= startOfDay && water.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<WaterLog>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        return try context.fetch(descriptor)
    }
    
    func deleteWaterLog(_ water: WaterLog) throws {
        context.delete(water)
        try context.save()
    }
    
    // MARK: - Workout Logs
    
    func saveWorkout(_ workout: WorkoutLog) throws {
        context.insert(workout)
        try context.save()
    }
    
    func fetchWorkouts(for date: Date) throws -> [WorkoutLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<WorkoutLog> { workout in
            workout.timestamp >= startOfDay && workout.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<WorkoutLog>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        return try context.fetch(descriptor)
    }
    
    func deleteWorkout(_ workout: WorkoutLog) throws {
        context.delete(workout)
        try context.save()
    }
    
    // MARK: - Daily Goals
    
    func saveDailyGoals(_ goals: DailyGoals) throws {
        context.insert(goals)
        try context.save()
    }
    
    func fetchDailyGoals(for date: Date) throws -> DailyGoals? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let predicate = #Predicate<DailyGoals> { goals in
            goals.date == startOfDay
        }
        
        let descriptor = FetchDescriptor<DailyGoals>(predicate: predicate)
        return try context.fetch(descriptor).first
    }
    
    // MARK: - Meal Plans
    
    func saveMealPlan(_ plan: MealPlan) throws {
        context.insert(plan)
        try context.save()
    }
    
    func fetchActiveMealPlan() throws -> MealPlan? {
        let predicate = #Predicate<MealPlan> { plan in
            plan.isActive == true
        }
        
        let descriptor = FetchDescriptor<MealPlan>(predicate: predicate)
        return try context.fetch(descriptor).first
    }
    
    func fetchAllMealPlans() throws -> [MealPlan] {
        let descriptor = FetchDescriptor<MealPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    func deleteMealPlan(_ plan: MealPlan) throws {
        context.delete(plan)
        try context.save()
    }
    
    // MARK: - Analytics
    
    func fetchMealsInDateRange(from startDate: Date, to endDate: Date) throws -> [MealLog] {
        let predicate = #Predicate<MealLog> { meal in
            meal.timestamp >= startDate && meal.timestamp <= endDate
        }
        
        let descriptor = FetchDescriptor<MealLog>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        return try context.fetch(descriptor)
    }
    
    func getTotalCaloriesForWeek(endingOn date: Date) throws -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: date)!
        let meals = try fetchMealsInDateRange(from: startDate, to: date)
        return Double(meals.reduce(0) { $0 + $1.calories })
    }
}
