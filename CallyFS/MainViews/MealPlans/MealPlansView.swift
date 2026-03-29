//
//  MealPlansView.swift
//  CallyFS
//

import SwiftUI
import SwiftData

struct MealPlansView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlan.createdAt, order: .reverse) private var mealPlans: [MealPlan]
    @State private var showGenerateSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                if mealPlans.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            ForEach(mealPlans) { plan in
                                MealPlanCard(plan: plan) {
                                    showPlanDetail(plan)
                                }
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.top, AppTheme.Spacing.xl)
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Meal Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.light()
                        showGenerateSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showGenerateSheet) {
                GenerateMealPlanView()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.surfaceElevated)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.Colors.accent)
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("No Meal Plans Yet")
                    .font(AppTheme.Typography.title3())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Generate AI-powered meal plans tailored to your goals and preferences")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.massive)
            }
            
            Button(action: {
                HapticManager.shared.light()
                showGenerateSheet = true
            }) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(AppTheme.Typography.body(weight: .semibold))
                    Text("Generate Meal Plan")
                        .font(AppTheme.Typography.body(weight: .semibold))
                }
                .foregroundColor(AppTheme.Colors.background)
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.accent)
                .cornerRadius(AppTheme.CornerRadius.xl)
            }
            
            Spacer()
        }
    }
    
    private func showPlanDetail(_ plan: MealPlan) {
        // Navigate to detail view
    }
}

struct MealPlanCard: View {
    let plan: MealPlan
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(AppTheme.Typography.body(weight: .bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("\(plan.duration) days")
                            .font(AppTheme.Typography.caption1())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    if plan.isActive {
                        Text("Active")
                            .font(AppTheme.Typography.caption2(weight: .semibold))
                            .foregroundColor(AppTheme.Colors.success)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(AppTheme.Colors.success.opacity(0.15))
                            .cornerRadius(AppTheme.CornerRadius.xs)
                    }
                }
                
                Text(plan.createdAt, style: .date)
                    .font(AppTheme.Typography.caption2())
                    .foregroundColor(AppTheme.Colors.textQuaternary)
                
                HStack {
                    Image(systemName: "sparkles")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.accent)
                    Text("AI Generated")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Typography.caption1(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                }
            }
            .padding(AppTheme.Spacing.xl)
            .elevatedCardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct GenerateMealPlanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var planName = ""
    @State private var duration = 7
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    let durationOptions = [3, 5, 7, 14, 30]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("PLAN NAME")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            TextField("e.g. Summer Shred Plan", text: $planName)
                                .font(AppTheme.Typography.body())
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.surfaceElevated)
                                .cornerRadius(AppTheme.CornerRadius.xl)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                                        .stroke(AppTheme.Colors.border, lineWidth: 1.5)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("DURATION")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            Picker("Duration", selection: $duration) {
                                ForEach(durationOptions, id: \.self) { days in
                                    Text("\(days) days").tag(days)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("WHAT TO EXPECT")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            VStack(spacing: AppTheme.Spacing.sm) {
                                FeatureRow(icon: "sparkles", text: "AI-powered meal suggestions")
                                FeatureRow(icon: "chart.bar.fill", text: "Balanced macros for your goals")
                                FeatureRow(icon: "fork.knife", text: "Variety and delicious recipes")
                                FeatureRow(icon: "clock.fill", text: "Easy to prepare meals")
                            }
                            .padding(AppTheme.Spacing.lg)
                            .background(AppTheme.Colors.surfaceElevated)
                            .cornerRadius(AppTheme.CornerRadius.lg)
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
                        
                        Button(action: generatePlan) {
                            HStack(spacing: 10) {
                                if isGenerating {
                                    ProgressView()
                                        .tint(AppTheme.Colors.background)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Generate Plan")
                                        .font(AppTheme.Typography.body(weight: .semibold))
                                }
                            }
                            .foregroundColor(planName.isEmpty ? AppTheme.Colors.textQuaternary : AppTheme.Colors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(planName.isEmpty ? AppTheme.Colors.surfaceElevated : AppTheme.Colors.accent)
                            .cornerRadius(AppTheme.CornerRadius.xl)
                        }
                        .disabled(planName.isEmpty || isGenerating)
                        .animation(AppTheme.Animation.easeInOut, value: planName.isEmpty)
                        .animation(AppTheme.Animation.easeInOut, value: isGenerating)
                    }
                    .padding(AppTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Generate Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                    .disabled(isGenerating)
                }
            }
        }
    }
    
    private func generatePlan() {
        guard !planName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        
        guard let profile = UserDefaults.standard.dictionary(forKey: "userProfile"),
              let calories = profile["calories"] as? Double,
              let protein = profile["protein"] as? Double,
              let carbs = profile["carbs"] as? Double,
              let fat = profile["fat"] as? Double,
              let goalString = profile["goal"] as? String,
              let goal = FitnessGoal(rawValue: goalString) else {
            errorMessage = "Unable to load profile data"
            isGenerating = false
            return
        }
        
        let dietRequirements = (profile["dietRequirements"] as? [String]) ?? []
        
        Task {
            do {
                let planContent = try await AIService.shared.generateMealPlan(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    goal: goal,
                    dietaryRestrictions: dietRequirements,
                    duration: duration
                )
                
                await MainActor.run {
                    let newPlan = MealPlan(
                        name: planName,
                        aiGeneratedPlan: planContent,
                        isActive: false,
                        duration: duration
                    )
                    
                    modelContext.insert(newPlan)
                    try? modelContext.save()
                    
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    if let aiError = error as? AIServiceError {
                        errorMessage = aiError.errorDescription
                    } else {
                        errorMessage = "Failed to generate meal plan. Please try again."
                    }
                    isGenerating = false
                    HapticManager.shared.error()
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    MealPlansView()
        .preferredColorScheme(.dark)
}
