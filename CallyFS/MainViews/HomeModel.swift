//
//  HomeModel.swift
//  CallyFS
//
//  Created by Nishit Vats on 24/02/26.
//

import Foundation
import SwiftUI


struct LoggedItem: Identifiable {
    let id = UUID()
    var name: String
    var kcal: Int
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var emoji: String = "🍽️"
    var time: Date = Date()
}

struct MealSlot: Identifiable {
    let id = UUID()
    let type: SlotType
    var items: [LoggedItem] = []

    enum SlotType: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch     = "Lunch"
        case dinner    = "Dinner"

        var emoji: String {
            switch self {
            case .breakfast: return "🥐"
            case .lunch:     return "🍱"
            case .dinner:    return "🥩"
            }
        }
    }

    var totalKcal: Int  { items.reduce(0) { $0 + $1.kcal } }
    var isLogged: Bool  { !items.isEmpty }
}

struct MacroNutrient: Identifiable {
    let id = UUID()
    let name: String
    var current: Double
    var total: Double
    let color: Color

    var progress: Double { guard total > 0 else { return 0 }; return min(current / total, 1.0) }
    var currentInt: Int  { Int(current) }
    var totalInt: Int    { Int(total) }
}
