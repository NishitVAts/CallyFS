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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        periodSelector
                        
                        weeklyOverviewCard
                        
                        macroDistributionChart
                        
                        caloriesTrendChart
                        
                        if let insights = aiInsights {
                            aiInsightsCard(insights)
                        } else if isLoadingInsights {
                            loadingInsightsCard
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, AppTheme.Spacing.xl)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadAIInsights()
            }
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: {
                    HapticManager.shared.selectionChanged()
                    withAnimation(AppTheme.Animation.spring) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? AppTheme.Colors.background : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(selectedPeriod == period ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
                        .cornerRadius(AppTheme.CornerRadius.md)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private var weeklyOverviewCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Weekly Overview")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            let stats = calculateWeeklyStats()
            
            HStack(spacing: AppTheme.Spacing.md) {
                StatPill(
                    label: "Avg Calories",
                    value: "\(Int(stats.avgCalories))",
                    unit: "kcal"
                )
                
                StatPill(
                    label: "Total Meals",
                    value: "\(stats.totalMeals)",
                    unit: "logged"
                )
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                StatPill(
                    label: "Protein",
                    value: "\(Int(stats.totalProtein))g",
                    unit: "total"
                )
                
                StatPill(
                    label: "Carbs",
                    value: "\(Int(stats.totalCarbs))g",
                    unit: "total"
                )
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private var macroDistributionChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Macro Distribution")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            let stats = calculateWeeklyStats()
            let total = stats.totalProtein + stats.totalCarbs + stats.totalFat
            
            if total > 0 {
                HStack(spacing: AppTheme.Spacing.md) {
                    MacroBar(
                        name: "Protein",
                        grams: stats.totalProtein,
                        percentage: (stats.totalProtein / total) * 100,
                        color: AppTheme.Colors.macroProtein
                    )
                    
                    MacroBar(
                        name: "Carbs",
                        grams: stats.totalCarbs,
                        percentage: (stats.totalCarbs / total) * 100,
                        color: AppTheme.Colors.macroCarbs
                    )
                    
                    MacroBar(
                        name: "Fat",
                        grams: stats.totalFat,
                        percentage: (stats.totalFat / total) * 100,
                        color: AppTheme.Colors.macroFat
                    )
                }
            } else {
                Text("No data available")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.xxl)
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private var caloriesTrendChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Calories Trend")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            let dailyData = calculateDailyCalories()
            
            if !dailyData.isEmpty {
                Chart(dailyData) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Calories", item.calories)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.gradientStart, AppTheme.Colors.gradientEnd],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            } else {
                Text("No data available")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.xxl)
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private func aiInsightsCard(_ insights: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.Colors.accent)
                Text("AI Insights")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Text(insights)
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
        }
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private var loadingInsightsCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .tint(AppTheme.Colors.accent)
            Text("Generating insights...")
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private func calculateWeeklyStats() -> WeeklyStats {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let weekMeals = allMeals.filter { $0.timestamp >= weekAgo }
        
        let totalCalories = weekMeals.reduce(0) { $0 + $1.calories }
        let totalProtein = weekMeals.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = weekMeals.reduce(0.0) { $0 + $1.carbs }
        let totalFat = weekMeals.reduce(0.0) { $0 + $1.fat }
        
        return WeeklyStats(
            avgCalories: weekMeals.isEmpty ? 0 : Double(totalCalories) / 7,
            totalMeals: weekMeals.count,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat
        )
    }
    
    private func calculateDailyCalories() -> [DailyCalorieData] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        var dailyData: [DailyCalorieData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: weekAgo)!
            let dayMeals = allMeals.filter {
                calendar.isDate($0.timestamp, inSameDayAs: date)
            }
            let totalCalories = dayMeals.reduce(0) { $0 + $1.calories }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayName = formatter.string(from: date)
            
            dailyData.append(DailyCalorieData(day: dayName, calories: totalCalories))
        }
        
        return dailyData
    }
    
    private func loadAIInsights() {
        guard !isLoadingInsights else { return }
        
        isLoadingInsights = true
        
        let stats = calculateWeeklyStats()
        
        guard let profile = UserDefaults.standard.dictionary(forKey: "userProfile"),
              let targetCalories = profile["calories"] as? Double,
              let goalString = profile["goal"] as? String,
              let goal = FitnessGoal(rawValue: goalString) else {
            isLoadingInsights = false
            return
        }
        
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
                
                await MainActor.run {
                    aiInsights = insights
                    isLoadingInsights = false
                }
            } catch {
                await MainActor.run {
                    isLoadingInsights = false
                }
            }
        }
    }
}

struct WeeklyStats {
    let avgCalories: Double
    let totalMeals: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
}

struct DailyCalorieData: Identifiable {
    let id = UUID()
    let day: String
    let calories: Int
}

enum TimePeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct StatPill: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.caption2(weight: .medium))
                .foregroundColor(AppTheme.Colors.textQuaternary)
            Text(value)
                .font(AppTheme.Typography.title3(weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(unit)
                .font(AppTheme.Typography.caption1())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceHighlight)
        .cornerRadius(AppTheme.CornerRadius.md)
    }
}

struct MacroBar: View {
    let name: String
    let grams: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(name)
                .font(AppTheme.Typography.caption1(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("\(Int(grams))g")
                .font(AppTheme.Typography.subheadline(weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("\(Int(percentage))%")
                .font(AppTheme.Typography.caption2())
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 40, height: 8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AnalyticsView()
        .preferredColorScheme(.dark)
}
