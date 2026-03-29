//
//  HistoryView.swift
//  CallyFS
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.timestamp, order: .reverse) private var allMeals: [MealLog]
    
    @State private var selectedDate = Date()
    @State private var showCalendar = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    dateSelector
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            dailySummaryCard
                            
                            mealsListSection
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.top, AppTheme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCalendar) {
                CalendarPickerView(selectedDate: $selectedDate)
            }
        }
    }
    
    private var dateSelector: some View {
        HStack {
            Button(action: {
                HapticManager.shared.light()
                withAnimation(AppTheme.Animation.spring) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Typography.subheadline(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.light()
                showCalendar = true
            }) {
                VStack(spacing: 2) {
                    Text(selectedDate, style: .date)
                        .font(AppTheme.Typography.body(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if Calendar.current.isDateInToday(selectedDate) {
                        Text("Today")
                            .font(AppTheme.Typography.caption2())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.light()
                withAnimation(AppTheme.Animation.spring) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.subheadline(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(Circle())
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
            .opacity(Calendar.current.isDateInToday(selectedDate) ? 0.5 : 1)
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .padding(.vertical, AppTheme.Spacing.lg)
    }
    
    private var dailySummaryCard: some View {
        let dayMeals = mealsForSelectedDate()
        let totalCalories = dayMeals.reduce(0) { $0 + $1.calories }
        let totalProtein = dayMeals.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = dayMeals.reduce(0.0) { $0 + $1.carbs }
        let totalFat = dayMeals.reduce(0.0) { $0 + $1.fat }
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Daily Summary")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack(spacing: AppTheme.Spacing.md) {
                SummaryPill(
                    icon: "flame.fill",
                    value: "\(totalCalories)",
                    label: "Calories"
                )
                
                SummaryPill(
                    icon: "fork.knife",
                    value: "\(dayMeals.count)",
                    label: "Meals"
                )
            }
            
            HStack(spacing: AppTheme.Spacing.sm) {
                MacroPill(name: "P", value: totalProtein, color: AppTheme.Colors.macroProtein)
                MacroPill(name: "C", value: totalCarbs, color: AppTheme.Colors.macroCarbs)
                MacroPill(name: "F", value: totalFat, color: AppTheme.Colors.macroFat)
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
    
    private var mealsListSection: some View {
        let dayMeals = mealsForSelectedDate()
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Meals")
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xxl)
            
            if dayMeals.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                    
                    Text("No meals logged")
                        .font(AppTheme.Typography.body(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Text("Tap the + button to add your first meal")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.massive)
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(dayMeals) { meal in
                        MealHistoryCard(meal: meal) {
                            deleteMeal(meal)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
            }
        }
    }
    
    private func mealsForSelectedDate() -> [MealLog] {
        allMeals.filter { meal in
            Calendar.current.isDate(meal.timestamp, inSameDayAs: selectedDate)
        }
    }
    
    private func deleteMeal(_ meal: MealLog) {
        HapticManager.shared.deleteItem()
        withAnimation(AppTheme.Animation.spring) {
            modelContext.delete(meal)
        }
    }
}

struct SummaryPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 44, height: 44)
                .background(AppTheme.Colors.surfaceHighlight)
                .cornerRadius(AppTheme.CornerRadius.md)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTheme.Typography.title3(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(label)
                    .font(AppTheme.Typography.caption1())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.surfaceHighlight)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }
}

struct MacroPill: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text(name)
                .font(AppTheme.Typography.caption1(weight: .bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text("\(Int(value))g")
                .font(AppTheme.Typography.caption1(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(color.opacity(0.2))
        .cornerRadius(AppTheme.CornerRadius.sm)
    }
}

struct MealHistoryCard: View {
    let meal: MealLog
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(meal.emoji)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(AppTheme.Colors.surfaceHighlight)
                .cornerRadius(AppTheme.CornerRadius.lg)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(AppTheme.Typography.body(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(meal.timestamp, style: .time)
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Circle()
                        .fill(AppTheme.Colors.textQuaternary)
                        .frame(width: 3, height: 3)
                    
                    Text(meal.mealType)
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(meal.calories) kcal")
                    .font(AppTheme.Typography.subheadline(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack(spacing: 4) {
                    Text("P:\(Int(meal.protein))")
                    Text("C:\(Int(meal.carbs))")
                    Text("F:\(Int(meal.fat))")
                }
                .font(AppTheme.Typography.caption2())
                .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(AppTheme.Typography.footnote())
                    .foregroundColor(AppTheme.Colors.textQuaternary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
}

struct CalendarPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(AppTheme.Colors.accent)
                .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
}
