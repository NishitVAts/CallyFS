//
//  AnalyticsView.swift
//  CallyFS
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allMeals: [MealLog]

    @State private var selectedPeriod: TimePeriod = .week
    @State private var aiInsights: String?
    @State private var isLoadingInsights = false
    @State private var insightsLocked = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        BrandHeader(title: "Analytics", subtitle: "Your trends")

                        periodSelector
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        overviewCard
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        macroDistributionCard
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        caloriesTrendCard
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        insightsCard
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer().frame(height: AppTheme.Spacing.xxl)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadAIInsights() }
        }
    }

    // MARK: - Period selector

    private var periodSelector: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    HapticManager.shared.selectionChanged()
                    withAnimation(AppTheme.Animation.spring) { selectedPeriod = period }
                } label: {
                    Text(period.rawValue)
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? AppTheme.Colors.background : AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .liquidGlass(
                            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md),
                            tint: selectedPeriod == period ? AppTheme.Colors.accent : nil,
                            fallback: selectedPeriod == period ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated
                        )
                }
            }
        }
    }

    // MARK: - Overview

    private var overviewCard: some View {
        let stats = calculateStats(days: selectedPeriod.days)
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: selectedPeriod.title)
            HStack(spacing: AppTheme.Spacing.md) {
                StatTile(label: "Avg Calories", value: "\(Int(stats.avgCalories))", unit: "kcal/day logged")
                StatTile(label: "Meals Logged", value: "\(stats.totalMeals)", unit: "total")
            }
            HStack(spacing: AppTheme.Spacing.md) {
                StatTile(label: "Protein", value: "\(Int(stats.totalProtein))g", unit: selectedPeriod.unitLabel)
                StatTile(label: "Carbs", value: "\(Int(stats.totalCarbs))g", unit: selectedPeriod.unitLabel)
            }
        }
    }

    // MARK: - Macro distribution

    private var macroDistributionCard: some View {
        let stats = calculateStats(days: selectedPeriod.days)
        let total = stats.totalProtein + stats.totalCarbs + stats.totalFat

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Macro Distribution")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)

            if total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        Capsule().fill(AppTheme.Colors.macroProtein)
                            .frame(width: max(geo.size.width * (stats.totalProtein / total) - 2, 0))
                        Capsule().fill(AppTheme.Colors.macroCarbs)
                            .frame(width: max(geo.size.width * (stats.totalCarbs / total) - 2, 0))
                        Capsule().fill(AppTheme.Colors.macroFat)
                            .frame(width: max(geo.size.width * (stats.totalFat / total) - 2, 0))
                    }
                }
                .frame(height: 12)

                HStack(spacing: AppTheme.Spacing.lg) {
                    MacroLegend(name: "Protein", grams: stats.totalProtein, pct: stats.totalProtein / total, color: AppTheme.Colors.macroProtein)
                    MacroLegend(name: "Carbs", grams: stats.totalCarbs, pct: stats.totalCarbs / total, color: AppTheme.Colors.macroCarbs)
                    MacroLegend(name: "Fat", grams: stats.totalFat, pct: stats.totalFat / total, color: AppTheme.Colors.macroFat)
                }
            } else {
                emptyHint("Log meals to see your macro split")
            }
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }

    // MARK: - Trend

    private var caloriesTrendCard: some View {
        let trendData = calculateTrend()
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                Text("Calories Trend")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                if selectedPeriod == .year {
                    Text("daily avg per month")
                        .font(AppTheme.Typography.caption2())
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                }
            }

            if trendData.contains(where: { $0.calories > 0 }) {
                Chart(trendData) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: selectedPeriod == .year ? .month : .day),
                        y: .value("Calories", item.calories)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.Colors.gradientStart, AppTheme.Colors.gradientEnd],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(selectedPeriod == .month ? 2 : 6)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(AppTheme.Colors.border)
                        AxisValueLabel().foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: xAxisFormat)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
            } else {
                emptyHint("No calories logged in this period yet")
            }
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }

    private var xAxisFormat: Date.FormatStyle {
        switch selectedPeriod {
        case .week:  return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day().month(.abbreviated)
        case .year:  return .dateTime.month(.narrow)
        }
    }

    // MARK: - Insights

    @ViewBuilder
    private var insightsCard: some View {
        if insightsLocked {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                    .frame(width: 38, height: 38)
                    .liquidGlass(in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md),
                                 fallback: AppTheme.Colors.surfaceHighlight)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Insights — Pro")
                        .font(AppTheme.Typography.callout(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("Upgrade to CallyFS Pro for weekly AI coaching on your nutrition.")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .elevatedCardStyle()
        } else if let insights = aiInsights {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles").foregroundColor(AppTheme.Colors.accent)
                    Text("AI Insights")
                        .font(AppTheme.Typography.headline())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                Text(insights)
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(AppTheme.Spacing.lg)
            .elevatedCardStyle()
        } else if isLoadingInsights {
            HStack(spacing: AppTheme.Spacing.md) {
                ProgressView().tint(AppTheme.Colors.accent)
                Text("Generating insights…")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .elevatedCardStyle()
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.Typography.subheadline())
            .foregroundColor(AppTheme.Colors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, AppTheme.Spacing.lg)
    }

    // MARK: - Data

    private func calculateStats(days: Int) -> PeriodStats {
        let calendar = Calendar.current
        let periodStart = calendar.date(byAdding: .day, value: -days, to: Date())!
        let meals = allMeals.filter { $0.timestamp >= periodStart }

        let totalCalories = meals.reduce(0) { $0 + $1.calories }
        // Average over days the user actually logged, so a 2-day-old account
        // isn't shown a misleading near-zero number.
        let loggedDays = Set(meals.map { calendar.startOfDay(for: $0.timestamp) }).count

        return PeriodStats(
            avgCalories: loggedDays == 0 ? 0 : Double(totalCalories) / Double(loggedDays),
            totalMeals: meals.count,
            totalProtein: meals.reduce(0.0) { $0 + $1.protein },
            totalCarbs: meals.reduce(0.0) { $0 + $1.carbs },
            totalFat: meals.reduce(0.0) { $0 + $1.fat }
        )
    }

    private func calculateTrend() -> [TrendPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch selectedPeriod {
        case .week, .month:
            let days = selectedPeriod.days
            return (0..<days).compactMap { offset in
                guard let date = calendar.date(byAdding: .day, value: offset - (days - 1), to: today) else { return nil }
                let dayMeals = allMeals.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
                return TrendPoint(date: date, calories: dayMeals.reduce(0) { $0 + $1.calories })
            }
        case .year:
            // One point per month: average daily intake across logged days.
            return (0..<12).compactMap { offset in
                guard let monthStart = calendar.date(byAdding: .month, value: offset - 11, to: calendar.dateInterval(of: .month, for: today)!.start) else { return nil }
                guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return nil }
                let monthMeals = allMeals.filter { $0.timestamp >= monthStart && $0.timestamp < monthEnd }
                let loggedDays = Set(monthMeals.map { calendar.startOfDay(for: $0.timestamp) }).count
                let total = monthMeals.reduce(0) { $0 + $1.calories }
                return TrendPoint(date: monthStart, calories: loggedDays == 0 ? 0 : total / loggedDays)
            }
        }
    }

    private func loadAIInsights() {
        guard !isLoadingInsights, aiInsights == nil, !insightsLocked else { return }
        // Insights are always computed over the trailing week — that's what the
        // backend endpoint expects, independent of the selected display period.
        let stats = calculateStats(days: 7)
        guard stats.totalMeals > 0,
              let profile = UserDefaults.standard.dictionary(forKey: "userProfile"),
              let targetCalories = profile["calories"] as? Double,
              let goalString = profile["goal"] as? String,
              let goal = FitnessGoal(rawValue: goalString) else { return }

        isLoadingInsights = true
        Task {
            do {
                let insights = try await AIService.shared.generateInsights(
                    weeklyCalories: stats.avgCalories * 7,
                    weeklyProtein: stats.totalProtein,
                    weeklyCarbs: stats.totalCarbs,
                    weeklyFat: stats.totalFat,
                    goal: goal,
                    targetCalories: targetCalories
                )
                await MainActor.run { aiInsights = insights; isLoadingInsights = false }
            } catch {
                await MainActor.run {
                    isLoadingInsights = false
                    // Insights is a Pro feature server-side; show the upgrade
                    // teaser instead of failing silently. Other errors (offline,
                    // signed out) stay quiet — insights is a bonus, not a blocker.
                    if let apiError = error as? APIError, apiError.isEntitlementRequired {
                        insightsLocked = true
                    }
                }
            }
        }
    }
}

// MARK: - Models & components

struct PeriodStats {
    let avgCalories: Double
    let totalMeals: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
}

enum TimePeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var days: Int {
        switch self {
        case .week:  return 7
        case .month: return 30
        case .year:  return 365
        }
    }

    var title: String {
        switch self {
        case .week:  return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .year:  return "Last 12 Months"
        }
    }

    var unitLabel: String {
        switch self {
        case .week:  return "this week"
        case .month: return "this month"
        case .year:  return "this year"
        }
    }
}

struct StatTile: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption2(weight: .medium))
                .foregroundColor(AppTheme.Colors.textQuaternary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(unit)
                .font(AppTheme.Typography.caption2())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceHighlight, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
    }
}

struct MacroLegend: View {
    let name: String
    let grams: Double
    let pct: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(name)
                    .font(AppTheme.Typography.caption1(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Text("\(Int(grams))g")
                .font(AppTheme.Typography.subheadline(weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text("\(Int(pct * 100))%")
                .font(AppTheme.Typography.caption2())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AnalyticsView()
        .preferredColorScheme(.dark)
}
