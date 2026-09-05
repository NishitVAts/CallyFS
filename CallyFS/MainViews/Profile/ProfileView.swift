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
    @State private var goalLabel = "Fitness Enthusiast"
    @State private var targetCalories = 2000.0
    @State private var targetProtein = 150.0
    @State private var targetCarbs = 200.0
    @State private var targetFat = 65.0

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        BrandHeader(title: "Profile", subtitle: "Your plan")

                        identityCard

                        goalsCard

                        quickActionsSection

                        settingsSection

                        Spacer().frame(height: AppTheme.Spacing.xxl)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadProfile)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showMealPlans) { MealPlansView() }
        }
    }

    // MARK: - Identity

    private var identityCard: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Text(userName.prefix(1).uppercased())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.background)
                .frame(width: 64, height: 64)
                .background(
                    LinearGradient(
                        colors: [AppTheme.Colors.gradientStart, AppTheme.Colors.gradientEnd],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(userName)
                    .font(AppTheme.Typography.title3(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(goalLabel)
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xl)
    }

    // MARK: - Goals

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: "Daily Targets")

            HStack(spacing: AppTheme.Spacing.md) {
                GoalTile(icon: "flame.fill", value: "\(Int(targetCalories))", unit: "kcal", tint: AppTheme.Colors.warning)
                GoalTile(icon: "bolt.fill", value: "\(Int(targetProtein))", unit: "g protein", tint: AppTheme.Colors.macroProtein)
            }
            HStack(spacing: AppTheme.Spacing.md) {
                GoalTile(icon: "leaf.fill", value: "\(Int(targetCarbs))", unit: "g carbs", tint: AppTheme.Colors.macroCarbs)
                GoalTile(icon: "drop.fill", value: "\(Int(targetFat))", unit: "g fat", tint: AppTheme.Colors.macroFat)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: "Quick Actions")

            ProfileRow(icon: "sparkles", tint: AppTheme.Colors.accent,
                       title: "AI Meal Plans", subtitle: "Personalized plans for your goals") {
                HapticManager.shared.light(); showMealPlans = true
            }
            ProfileRow(icon: "arrow.clockwise", tint: AppTheme.Colors.info,
                       title: "Recalculate Goals", subtitle: "Update from your current stats") {
                recalculateGoals()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: "Settings")

            ProfileRow(icon: "gearshape.fill", tint: AppTheme.Colors.textSecondary,
                       title: "App Settings", subtitle: "API keys, preferences") {
                HapticManager.shared.settingsTap(); showSettings = true
            }
            ProfileRow(icon: "heart.fill", tint: AppTheme.Colors.error,
                       title: "Health Permissions", subtitle: "Manage HealthKit access") {
                HapticManager.shared.light(); openHealthSettings()
            }
            ProfileRow(icon: "arrow.counterclockwise", tint: AppTheme.Colors.error,
                       title: "Reset Onboarding", subtitle: "Start fresh", isDestructive: true) {
                HapticManager.shared.warning(); resetOnboarding()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
    }

    // MARK: - Logic

    private func loadProfile() {
        guard let profile = UserDefaults.standard.dictionary(forKey: "userProfile") else { return }
        userName = profile["userName"] as? String ?? "User"
        targetCalories = profile["calories"] as? Double ?? 2000
        targetProtein = profile["protein"] as? Double ?? 150
        targetCarbs = profile["carbs"] as? Double ?? 200
        targetFat = profile["fat"] as? Double ?? 65
        if let goal = profile["goal"] as? String { goalLabel = goal }
    }

    private func recalculateGoals() {
        guard let targets = GoalCalculator.recalculateAndPersist() else {
            HapticManager.shared.error()
            return
        }
        withAnimation(AppTheme.Animation.spring) {
            targetCalories = targets.calories
            targetProtein = targets.protein
            targetCarbs = targets.carbs
            targetFat = targets.fat
        }
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

// MARK: - Components

struct GoalTile: View {
    let icon: String
    let value: String
    let unit: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint)

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(unit)
                    .font(AppTheme.Typography.caption2())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }
}

struct ProfileRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 42, height: 42)
                    .liquidGlass(in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md),
                                 fallback: AppTheme.Colors.surfaceHighlight)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.callout(weight: .semibold))
                        .foregroundColor(isDestructive ? AppTheme.Colors.error : AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption1(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textDisabled)
            }
            .padding(AppTheme.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
