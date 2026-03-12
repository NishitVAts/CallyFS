//
//  HealthKitManager.swift
//  CallyFS
//
//  Updated by Nishit Vats
//

import Foundation
import HealthKit

final class HealthKitManager {
    
    // MARK: - Singleton (Optional but recommended for HealthKit)
    static let shared = HealthKitManager()
    private init() {}
    
    private let healthStore = HKHealthStore()
    
    // MARK: - Errors
    enum HealthKitError: Error {
        case notAvailable
        case authorizationFailed
        case typeUnavailable
        case noData
    }
    
    // MARK: - Snapshot Model
    struct HealthSnapshot {
        var age: Int
        var biologicalSex: HKBiologicalSex
        var height: Double
        var weight: Double
        var stepsToday: Double
    }
    
    // MARK: - Permission Request
    func requestPermissions() async throws {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        guard let readTypes = getReadTypes(),
              let shareTypes = getShareTypes() else {
            throw HealthKitError.typeUnavailable
        }
        
        try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
    }
    
    // MARK: - Read Types
    private func getReadTypes() -> Set<HKObjectType>? {
        guard let dob = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
              let gender = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
              let height = HKObjectType.quantityType(forIdentifier: .height),
              let weight = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
              let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
              let protein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
              let carbs = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
              let fat = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)
        else { return nil }
        
        return [dob, gender, height, weight, stepCount, activeEnergy, dietaryEnergy, protein, carbs, fat]
    }
    
    // MARK: - Share Types
    private func getShareTypes() -> Set<HKSampleType>? {
        guard let weight = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
              let protein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
              let carbs = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
              let fat = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)
        else { return nil }
        
        return [weight, dietaryEnergy, protein, carbs, fat]
    }
    
    // MARK: - Public Fetch
    func fetchInitialData() async throws -> HealthSnapshot {
        
        print("🔍 Starting HealthKit data fetch...")
        
        async let age = fetchAge()
        async let sex = fetchBiologicalSex()
        async let height = fetchMostRecent(.height)
        async let weight = fetchMostRecent(.bodyMass)
        async let steps = fetchTodayStepCount()
        
        let snapshot = try await HealthSnapshot(
            age: age,
            biologicalSex: sex,
            height: height,
            weight: weight,
            stepsToday: steps
        )
        
        print("✅ HealthKit fetch complete - Age: \(snapshot.age), Sex: \(snapshot.biologicalSex.rawValue), Height: \(snapshot.height)m, Weight: \(snapshot.weight)kg, Steps: \(snapshot.stepsToday)")
        
        return snapshot
    }
}

// MARK: - Private Fetch Methods
private extension HealthKitManager {
    
    // Proper age calculation
    func fetchAge() throws -> Int {
        print("🔍 Fetching age...")
        let components = try healthStore.dateOfBirthComponents()
        guard let birthDate = Calendar.current.date(from: components) else {
            print("❌ Could not parse birth date components")
            throw HealthKitError.noData
        }
        
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        print("✅ Age calculated: \(age)")
        return age
    }
    
    func fetchBiologicalSex() throws -> HKBiologicalSex {
        print("🔍 Fetching biological sex...")
        let sex = try healthStore.biologicalSex().biologicalSex
        print("✅ Biological sex: \(sex.rawValue)")
        return sex
    }
    
    func fetchMostRecent(_ identifier: HKQuantityTypeIdentifier) async throws -> Double {
        
        print("🔍 Fetching \(identifier.rawValue)...")
        
        guard let sampleType = HKSampleType.quantityType(forIdentifier: identifier) else {
            print("❌ Could not create sample type for \(identifier.rawValue)")
            throw HealthKitError.typeUnavailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                
                if let error = error {
                    print("❌ Error fetching \(identifier.rawValue): \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    print("⚠️ No \(identifier.rawValue) data found")
                    continuation.resume(throwing: HealthKitError.noData)
                    return
                }
                
                let unit = self.unit(for: identifier)
                let value = sample.quantity.doubleValue(for: unit)
                
                print("✅ \(identifier.rawValue): \(value) \(unit.unitString)")
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchTodayStepCount() async throws -> Double {
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeUnavailable
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    // Centralized unit handler (scalable)
    func unit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {
        switch identifier {
        case .height:
            return .meter()
        case .bodyMass:
            return .gramUnit(with: .kilo)
        case .stepCount:
            return .count()
        default:
            return .count()
        }
    }
}
