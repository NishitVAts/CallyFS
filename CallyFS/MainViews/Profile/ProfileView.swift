//
//  ProfileView.swift
//  CallyFS
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = true
    
    @State private var showSettings = false
    @State private var showMealPlans = false
    @State private var userName = "User"
    @State private var targetCalories = 2000.0
    @State private var targetProtein = 150.0
    @State private var targetCarbs = 200.0
    @State private var targetFat = 65.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        profileHeader
                        
                        dailyGoalsCard
                        
                        quickActionsSection
                        
                        settingsSection
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, AppTheme.Spacing.xl)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: loadProfile)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showMealPlans) {
                MealPlansView()
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.gradientStart, AppTheme.Colors.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(userName.prefix(1).uppercased())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppTheme.Colors.background)
            }
            
            Text(userName)
                .font(AppTheme.Typography.title2())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Fitness Enthusiast")
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }
    
    private var dailyGoalsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Daily Goals")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.md) {
                GoalRow(
                    icon: "flame.fill",
                    label: "Calories",
                    value: "\(Int(targetCalories))",
                    unit: "kcal"
                )
                
                GoalRow(
                    icon: "p.circle.fill",
                    label: "Protein",
                    value: "\(Int(targetProtein))",
                    unit: "g"
                )
                
                GoalRow(
                    icon: "c.circle.fill",
                    label: "Carbs",
                    value: "\(Int(targetCarbs))",
                    unit: "g"
                )
                
                GoalRow(
                    icon: "f.circle.fill",
                    label: "Fat",
                    value: "\(Int(targetFat))",
                    unit: "g"
                )
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Quick Actions")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xxl)
            
            VStack(spacing: AppTheme.Spacing.md) {
                ActionButton(
                    icon: "sparkles",
                    title: "AI Meal Plans",
                    subtitle: "Generate personalized meal plans",
                    color: AppTheme.Colors.accent
                ) {
                    HapticManager.shared.light()
                    showMealPlans = true
                }
                
                ActionButton(
                    icon: "arrow.clockwise",
                    title: "Recalculate Goals",
                    subtitle: "Update based on current stats",
                    color: AppTheme.Colors.info
                ) {
                    HapticManager.shared.light()
                    recalculateGoals()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Settings")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xxl)
            
            VStack(spacing: AppTheme.Spacing.md) {
                SettingsButton(
                    icon: "gearshape.fill",
                    title: "App Settings",
                    subtitle: "API keys, preferences"
                ) {
                    HapticManager.shared.settingsTap()
                    showSettings = true
                }
                
                SettingsButton(
                    icon: "heart.fill",
                    title: "Health Permissions",
                    subtitle: "Manage HealthKit access"
                ) {
                    HapticManager.shared.light()
                    openHealthSettings()
                }
                
                SettingsButton(
                    icon: "arrow.counterclockwise",
                    title: "Reset Onboarding",
                    subtitle: "Start fresh",
                    isDestructive: true
                ) {
                    HapticManager.shared.warning()
                    resetOnboarding()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
        }
    }
    
    private func loadProfile() {
        if let profile = UserDefaults.standard.dictionary(forKey: "userProfile") {
            userName = profile["userName"] as? String ?? "User"
            targetCalories = profile["calories"] as? Double ?? 2000
            targetProtein = profile["protein"] as? Double ?? 150
            targetCarbs = profile["carbs"] as? Double ?? 200
            targetFat = profile["fat"] as? Double ?? 65
        }
    }
    
    private func recalculateGoals() {
        // This would recalculate based on current user stats
        HapticManager.shared.success()
    }
    
    private func openHealthSettings() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

struct GoalRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 40, height: 40)
                .background(AppTheme.Colors.surfaceHighlight)
                .cornerRadius(AppTheme.CornerRadius.sm)
            
            Text(label)
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(AppTheme.Typography.body(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(unit)
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceHighlight)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.15))
                    .cornerRadius(AppTheme.CornerRadius.lg)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.body(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.footnote(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textQuaternary)
            }
            .padding(AppTheme.Spacing.lg)
            .elevatedCardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? AppTheme.Colors.error : AppTheme.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.surfaceHighlight)
                    .cornerRadius(AppTheme.CornerRadius.sm)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.body(weight: .semibold))
                        .foregroundColor(isDestructive ? AppTheme.Colors.error : AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.footnote(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textQuaternary)
            }
            .padding(AppTheme.Spacing.lg)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
