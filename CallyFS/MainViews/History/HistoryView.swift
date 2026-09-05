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
    @State private var editingMeal: MealLog?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        BrandHeader(title: "History", subtitle: "Look back")

                        dateSelector
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        dailySummaryCard
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        mealsListSection

                        Spacer().frame(height: AppTheme.Spacing.xxl)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCalendar) {
                CalendarPickerView(selectedDate: $selectedDate)
            }
            .sheet(item: $editingMeal) { meal in
                EditMealView(meal: meal)
            }
        }
    }

    // MARK: - Date selector

    private var dateSelector: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            navButton(icon: "chevron.left") {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            }
            .disabled(false)

            Button {
                HapticManager.shared.light()
                showCalendar = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                    Text(dateTitle)
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                }
                .foregroundColor(AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .liquidGlass(in: Capsule(), fallback: AppTheme.Colors.surfaceElevated)
            }

            navButton(icon: "chevron.right") {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
            .opacity(Calendar.current.isDateInToday(selectedDate) ? 0.4 : 1)
        }
    }

    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.light()
            withAnimation(AppTheme.Animation.spring) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 44, height: 44)
                .liquidGlass(in: Circle(), fallback: AppTheme.Colors.surfaceElevated)
        }
    }

    private var dateTitle: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Today" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    // MARK: - Summary

    private var dailySummaryCard: some View {
        let dayMeals = mealsForSelectedDate()
        let totalCalories = dayMeals.reduce(0) { $0 + $1.calories }
        let totalProtein = dayMeals.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = dayMeals.reduce(0.0) { $0 + $1.carbs }
        let totalFat = dayMeals.reduce(0.0) { $0 + $1.fat }

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(totalCalories)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("calories consumed")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(dayMeals.count)")
                        .font(AppTheme.Typography.title3(weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(dayMeals.count == 1 ? "meal" : "meals")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                MacroChip(name: "Protein", value: totalProtein, color: AppTheme.Colors.macroProtein)
                MacroChip(name: "Carbs", value: totalCarbs, color: AppTheme.Colors.macroCarbs)
                MacroChip(name: "Fat", value: totalFat, color: AppTheme.Colors.macroFat)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }

    // MARK: - Meals

    private var mealsListSection: some View {
        let dayMeals = mealsForSelectedDate()

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: "Meals")
                .padding(.horizontal, AppTheme.Spacing.xl)

            if dayMeals.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(dayMeals) { meal in
                        MealHistoryCard(
                            meal: meal,
                            onEdit: {
                                HapticManager.shared.light()
                                editingMeal = meal
                            },
                            onDelete: { deleteMeal(meal) }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.Colors.textQuaternary)
            Text("No meals logged")
                .font(AppTheme.Typography.callout(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text("Add meals from the Home tab")
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textQuaternary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.huge)
    }

    private func mealsForSelectedDate() -> [MealLog] {
        allMeals.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
    }

    private func deleteMeal(_ meal: MealLog) {
        HapticManager.shared.deleteItem()
        withAnimation(AppTheme.Animation.spring) {
            modelContext.delete(meal)
            try? modelContext.save()
        }
    }
}

// MARK: - Components

struct MacroChip: View {
    let name: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(name)
                    .font(AppTheme.Typography.caption2(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            Text("\(Int(value))g")
                .font(AppTheme.Typography.subheadline(weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceHighlight, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
    }
}

struct MealHistoryCard: View {
    let meal: MealLog
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(meal.emoji)
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(AppTheme.Colors.surfaceHighlight, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))

            VStack(alignment: .leading, spacing: 3) {
                Text(meal.name)
                    .font(AppTheme.Typography.callout(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(meal.timestamp, style: .time)
                    Circle().fill(AppTheme.Colors.textQuaternary).frame(width: 3, height: 3)
                    Text(meal.mealType)
                }
                .font(AppTheme.Typography.caption1())
                .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(meal.calories) kcal")
                    .font(AppTheme.Typography.subheadline(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                HStack(spacing: 5) {
                    Text("P\(Int(meal.protein))")
                    Text("C\(Int(meal.carbs))")
                    Text("F\(Int(meal.fat))")
                }
                .font(AppTheme.Typography.caption2())
                .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Meal", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete Meal", systemImage: "trash")
            }
        }
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
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(AppTheme.Colors.accent)
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
}
