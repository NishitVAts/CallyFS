//
//  QuickAddMealView.swift
//  CallyFS
//

import SwiftUI
import SwiftData

struct QuickAddMealView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var mealName = ""
    @State private var selectedCategory: MealSlot.SlotType = .breakfast
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("WHAT DID YOU EAT?")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            TextField("e.g. Grilled Chicken Salad", text: $mealName)
                                .font(AppTheme.Typography.body())
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .focused($isNameFocused)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.surfaceElevated)
                                .cornerRadius(AppTheme.CornerRadius.xl)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                                        .stroke(
                                            isNameFocused ? AppTheme.Colors.accent.opacity(0.3) : AppTheme.Colors.border,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("MEAL TYPE")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            Menu {
                                ForEach(MealSlot.SlotType.allCases, id: \.self) { category in
                                    Button(action: {
                                        HapticManager.shared.categorySelection()
                                        withAnimation(AppTheme.Animation.easeInOut) {
                                            selectedCategory = category
                                        }
                                    }) {
                                        HStack {
                                            Text(category.emoji)
                                            Text(category.rawValue)
                                            if selectedCategory == category {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory.emoji)
                                        .font(.system(size: 24))
                                    Text(selectedCategory.rawValue)
                                        .font(AppTheme.Typography.body(weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(AppTheme.Typography.footnote(weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.textQuaternary)
                                }
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.surfaceElevated)
                                .cornerRadius(AppTheme.CornerRadius.xl)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                                        .stroke(AppTheme.Colors.border, lineWidth: 1.5)
                                )
                            }
                        }
                        
                        if let error = errorMessage {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.Colors.error)
                                Text(error)
                                    .font(AppTheme.Typography.caption1())
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.error.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.md)
                        }
                        
                        Button(action: logMeal) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .tint(mealName.isEmpty ? AppTheme.Colors.textQuaternary : AppTheme.Colors.background)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(AppTheme.Typography.footnote(weight: .semibold))
                                    Text("Add Meal")
                                        .font(AppTheme.Typography.body(weight: .semibold))
                                }
                            }
                            .foregroundColor(mealName.isEmpty ? AppTheme.Colors.textQuaternary : AppTheme.Colors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(mealName.isEmpty ? AppTheme.Colors.surfaceElevated : AppTheme.Colors.accent)
                            .cornerRadius(AppTheme.CornerRadius.xl)
                        }
                        .disabled(mealName.isEmpty || isLoading)
                        .animation(AppTheme.Animation.easeInOut, value: mealName.isEmpty)
                        .animation(AppTheme.Animation.easeInOut, value: isLoading)
                    }
                    .padding(AppTheme.Spacing.xxl)
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.cardDismiss()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(AppTheme.Typography.subheadline(weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.Colors.surfaceElevated)
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNameFocused = true
                }
            }
        }
    }
    
    private func logMeal() {
        guard !mealName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        let tempMeal = MealLog(
            name: mealName,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            emoji: selectedCategory.emoji,
            mealType: selectedCategory.rawValue
        )
        
        modelContext.insert(tempMeal)
        
        Task {
            do {
                let nutrition = try await AIService.shared.getNutritionInfo(for: mealName)
                
                await MainActor.run {
                    tempMeal.calories = nutrition.calories
                    tempMeal.protein = nutrition.protein
                    tempMeal.carbs = nutrition.carbs
                    tempMeal.fat = nutrition.fat
                    
                    try? modelContext.save()
                    
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    if let aiError = error as? AIServiceError {
                        errorMessage = aiError.errorDescription
                    } else {
                        errorMessage = "Failed to analyze meal. Please try again."
                    }
                    
                    modelContext.delete(tempMeal)
                    isLoading = false
                    HapticManager.shared.error()
                }
            }
        }
    }
}

#Preview {
    QuickAddMealView()
        .preferredColorScheme(.dark)
}
