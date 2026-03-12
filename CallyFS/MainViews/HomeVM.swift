//
//  HomeVM.swift
//  CallyFS
//

import SwiftUI


// MARK: - ViewModel

final class DashboardViewModel: ObservableObject {
    
    private let openRouterService: OpenRouterService

    // User & goals (loaded from onboarding UserDefaults)
    @Published var userName:  String = "User"
    @Published var goalKcal:  Double = 2000
    @Published var eatenKcal: Double = 0

    @Published var macros: [MacroNutrient] = []

    @Published var mealSlots: [MealSlot] = [
        MealSlot(type: .breakfast),
        MealSlot(type: .lunch),
        MealSlot(type: .dinner)
    ]

    // Add-item sheet state
    @Published var showAddSheet: Bool = false
    @Published var inputName: String = ""
    @Published var inputKcal: String = ""
    @Published var activeSlot: MealSlot.SlotType = .breakfast

    // MARK: Computed
    var kcalLeft: Int { max(Int(goalKcal - eatenKcal), 0) }
    var calorieProgress: Double { guard goalKcal > 0 else { return 0 }; return min(eatenKcal / goalKcal, 1.0) }
    var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default:      return "Good evening,"
        }
    }

    init() {
        let apiKey = UserDefaults.standard.string(forKey: "openRouterAPIKey") ?? ""
        self.openRouterService = OpenRouterService(apiKey: apiKey)
        load()
    }

    // MARK: - Load from UserDefaults
    func load() {
        guard let p = UserDefaults.standard.dictionary(forKey: "userProfile") else { return }
        userName = p["userName"] as? String ?? "User"
        goalKcal = p["calories"] as? Double ?? 2000
        let protein = p["protein"] as? Double ?? 150
        let carbs   = p["carbs"]   as? Double ?? 200
        let fat     = p["fat"]     as? Double ?? 65
        macros = [
            MacroNutrient(name: "Carbs",   current: 0, total: carbs,   color: Color(hex: "#E8E8E8")),
            MacroNutrient(name: "Protein", current: 0, total: protein, color: Color(hex: "#A0A0A0")),
            MacroNutrient(name: "Fat",     current: 0, total: fat,     color: Color(hex: "#C8C8C8"))
        ]
    }

    // MARK: - Sheet
    
    func openSheet(for slot: MealSlot.SlotType) {
        activeSlot = slot
        inputName  = ""
        inputKcal  = ""
        showAddSheet = true
    }

    func confirmAdd() {
        guard !inputName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let item = LoggedItem(name: inputName, kcal: 0, emoji: activeSlot.emoji)
        
        if let i = mealSlots.firstIndex(where: { $0.type == activeSlot }) {
            mealSlots[i].items.append(item)
        }
        
        let mealName = inputName
        let itemId = item.id
        let slotType = activeSlot
        
        Task {
            do {
                let nutrition = try await openRouterService.getNutritionInfo(for: mealName)
                
                await MainActor.run {
                    if let slotIndex = mealSlots.firstIndex(where: { $0.type == slotType }),
                       let itemIndex = mealSlots[slotIndex].items.firstIndex(where: { $0.id == itemId }) {
                        
                        mealSlots[slotIndex].items[itemIndex].kcal = nutrition.calories
                        mealSlots[slotIndex].items[itemIndex].protein = nutrition.protein
                        mealSlots[slotIndex].items[itemIndex].carbs = nutrition.carbs
                        mealSlots[slotIndex].items[itemIndex].fat = nutrition.fat
                        
                        eatenKcal += Double(nutrition.calories)
                        
                        if let proteinIndex = macros.firstIndex(where: { $0.name == "Protein" }) {
                            macros[proteinIndex].current += nutrition.protein
                        }
                        if let carbsIndex = macros.firstIndex(where: { $0.name == "Carbs" }) {
                            macros[carbsIndex].current += nutrition.carbs
                        }
                        if let fatIndex = macros.firstIndex(where: { $0.name == "Fat" }) {
                            macros[fatIndex].current += nutrition.fat
                        }
                    }
                }
            } catch {
                print("Error fetching nutrition: \(error.localizedDescription)")
                HapticManager.shared.error()
                await MainActor.run {
                    if let slotIndex = mealSlots.firstIndex(where: { $0.type == slotType }),
                       let itemIndex = mealSlots[slotIndex].items.firstIndex(where: { $0.id == itemId }) {
                        mealSlots[slotIndex].items[itemIndex].kcal = 300
                        eatenKcal += 300
                    }
                }
            }
        }
        
        inputName = ""
        inputKcal = ""
    }

    func deleteItem(_ item: LoggedItem, from slot: MealSlot.SlotType) {
        guard let i = mealSlots.firstIndex(where: { $0.type == slot }) else { return }
        mealSlots[i].items.removeAll { $0.id == item.id }
        eatenKcal = max(eatenKcal - Double(item.kcal), 0)
        
        if let proteinIndex = macros.firstIndex(where: { $0.name == "Protein" }) {
            macros[proteinIndex].current = max(macros[proteinIndex].current - item.protein, 0)
        }
        if let carbsIndex = macros.firstIndex(where: { $0.name == "Carbs" }) {
            macros[carbsIndex].current = max(macros[carbsIndex].current - item.carbs, 0)
        }
        if let fatIndex = macros.firstIndex(where: { $0.name == "Fat" }) {
            macros[fatIndex].current = max(macros[fatIndex].current - item.fat, 0)
        }
    }
}
