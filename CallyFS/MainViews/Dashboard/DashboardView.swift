//
//  DashboardView.swift
//  CallyFS
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allMeals: [MealLog]
    @Query private var waterLogs: [WaterLog]
    
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedDate = Date()
    @State private var errorMessage: String?
    @State private var showAddMeal = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        headerSection

                        calorieCard
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.top, AppTheme.Spacing.lg)

                        macrosSection
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.top, AppTheme.Spacing.md)

                        waterTrackingCard
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.top, AppTheme.Spacing.md)

                        mealsSection
                            .padding(.top, AppTheme.Spacing.xl)

                        Spacer().frame(height: AppTheme.Spacing.xxl)

                    }
                }
            }
            .onAppear {
                viewModel.loadProfile()
            }
            .sheet(isPresented: $showAddMeal) {
                QuickAddMealView()
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greetingText)
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text(viewModel.userName)
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            Spacer()

            Button {
                HapticManager.shared.fabTap()
                showAddMeal = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.Colors.background)
                    .frame(width: 44, height: 44)
                    .liquidGlass(in: Circle(), tint: AppTheme.Colors.accent, fallback: AppTheme.Colors.accent)
            }
            .accessibilityLabel("Add meal")

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .liquidGlass(in: Circle(), fallback: AppTheme.Colors.surfaceElevated)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.top, AppTheme.Spacing.sm)
    }
    
    private var calorieCard: some View {
        let todayMeals = mealsForToday()
        let eatenCalories = todayMeals.reduce(0) { $0 + $1.calories }
        let goal = Int(viewModel.goalCalories)
        let isOver = eatenCalories > goal
        let diff = abs(goal - eatenCalories)
        let progress = min(Double(eatenCalories) / viewModel.goalCalories, 1.0)
        let barColors = isOver
            ? [AppTheme.Colors.calorieOver, AppTheme.Colors.calorieOver.opacity(0.7)]
            : [AppTheme.Colors.gradientStart, AppTheme.Colors.gradientEnd]

        return ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxl)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.surfaceElevated, AppTheme.Colors.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxl)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.Colors.borderLight, AppTheme.Colors.border],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            
            GeometryReader { geo in
                DiagonalPattern()
                    .frame(width: geo.size.width * 0.5, height: geo.size.height)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .opacity(0.05)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxl))
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Text("Daily")
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text("CALORIES")
                            .font(.custom("Georgia-Bold", size: 12))
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                            .tracking(1.6)
                    }
                    Spacer()
                }

                Spacer().frame(height: 12)

                Text("Eaten \(eatenCalories)")
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)

                Spacer().frame(height: 2)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(isOver ? "+\(diff)" : "\(diff)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(isOver ? AppTheme.Colors.calorieOver : AppTheme.Colors.textPrimary)
                    Text(isOver ? "KCAL OVER" : "KCAL LEFT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isOver ? AppTheme.Colors.calorieOver : AppTheme.Colors.textSecondary)
                        .tracking(1.0)
                        .padding(.bottom, 7)
                }

                Spacer().frame(height: 14)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.Colors.surfaceHighlight)
                            .frame(height: 26)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: barColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 26)
                            .animation(AppTheme.Animation.springBouncy, value: progress)

                        if eatenCalories > 0 {
                            Text("\(eatenCalories) KCAL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.Colors.background)
                                .padding(.leading, 11)
                        }
                    }
                }
                .frame(height: 26)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .frame(height: 168)
    }
    
    private var macrosSection: some View {
        let todayMeals = mealsForToday()
        let totalProtein = todayMeals.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = todayMeals.reduce(0.0) { $0 + $1.carbs }
        let totalFat = todayMeals.reduce(0.0) { $0 + $1.fat }
        
        return HStack(spacing: 10) {
            MacroCard(
                name: "Carbs",
                current: totalCarbs,
                total: viewModel.goalCarbs,
                color: AppTheme.Colors.macroCarbs
            )
            
            MacroCard(
                name: "Protein",
                current: totalProtein,
                total: viewModel.goalProtein,
                color: AppTheme.Colors.macroProtein
            )
            
            MacroCard(
                name: "Fat",
                current: totalFat,
                total: viewModel.goalFat,
                color: AppTheme.Colors.macroFat
            )
        }
    }
    
    private var waterTrackingCard: some View {
        let todayWater = waterForToday()
        let totalWater = todayWater.reduce(0.0) { $0 + $1.amount }
        let goalWater = viewModel.goalWater
        let progress = min(totalWater / goalWater, 1.0)
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.info)

                Text("Water Intake")
                    .font(AppTheme.Typography.subheadline(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Button(action: {
                    addWater(250)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("250ml")
                            .font(AppTheme.Typography.caption2(weight: .semibold))
                    }
                    .foregroundColor(AppTheme.Colors.info)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 5)
                    .liquidGlass(in: Capsule(), fallback: AppTheme.Colors.info.opacity(0.15))
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(totalWater))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("/ \(Int(goalWater)) ml")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppTheme.Colors.info)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(AppTheme.Animation.springBouncy, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }
    
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Meals")
                    .font(.custom("Georgia-Bold", size: 17))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Text(Date(), style: .date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textQuaternary)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            ForEach(MealSlot.SlotType.allCases, id: \.self) { slotType in
                NavigationLink(destination: MealDetailView(slotType: slotType)) {
                    MealSlotCard(
                        slotType: slotType,
                        meals: mealsForSlot(slotType)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppTheme.Spacing.xl)
            }
        }
    }
    
    private func mealsForToday() -> [MealLog] {
        allMeals.filter { meal in
            Calendar.current.isDateInToday(meal.timestamp)
        }
    }
    
    private func waterForToday() -> [WaterLog] {
        waterLogs.filter { log in
            Calendar.current.isDateInToday(log.timestamp)
        }
    }
    
    private func mealsForSlot(_ slotType: MealSlot.SlotType) -> [MealLog] {
        mealsForToday().filter { $0.mealType == slotType.rawValue }
    }
    
    private func addWater(_ amount: Double) {
        let waterLog = WaterLog(amount: amount)
        modelContext.insert(waterLog)
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            modelContext.delete(waterLog)
            errorMessage = "Couldn't save your water intake. Please try again."
            HapticManager.shared.error()
        }
    }
}

struct MacroCard: View {
    let name: String
    let current: Double
    let total: Double
    let color: Color
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return min(current / total, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(AppTheme.Typography.caption1(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(Int(current))")
                    .font(AppTheme.Typography.subheadline(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(" / \(Int(total))g")
                    .font(AppTheme.Typography.caption2())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(AppTheme.Animation.springBouncy, value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(11)
        .cardStyle()
    }
}

struct MealSlotCard: View {
    let slotType: MealSlot.SlotType
    let meals: [MealLog]
    
    var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    var isLogged: Bool {
        !meals.isEmpty
    }
    
    var hasCalculating: Bool {
        meals.contains(where: { $0.calories == 0 })
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 13)
                    .fill(AppTheme.Colors.surfaceElevated)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )

                Text(slotType.emoji)
                    .font(.system(size: 21))
                    .frame(width: 44, height: 44)

                if isLogged {
                    Circle()
                        .fill(AppTheme.Colors.textPrimary)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(AppTheme.Colors.background)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2)
                        .offset(x: 5, y: -5)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(slotType.rawValue)
                    .font(AppTheme.Typography.subheadline(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if isLogged {
                    if hasCalculating {
                        Text("Calculating...")
                            .font(AppTheme.Typography.caption1(weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)

                    } else {
                        HStack(spacing: 6) {
                            Text("\(meals.count) item\(meals.count == 1 ? "" : "s")")
                                .font(AppTheme.Typography.caption1())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Circle()
                                .fill(AppTheme.Colors.textQuaternary)
                                .frame(width: 3, height: 3)
                            Text("\(totalCalories) kcal")
                                .font(AppTheme.Typography.caption1(weight: .semibold))
                                .foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                    }
                } else {
                    Text("Tap to add food")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.caption1(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textDisabled)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}

struct DiagonalPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
            let count = Int(size.width / spacing) + Int(size.height / spacing) + 2
            for i in 0..<count {
                let x = CGFloat(i) * spacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x - size.height, y: size.height))
                context.stroke(path, with: .color(.white), lineWidth: 1)
            }
        }
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var userName = "User"
    @Published var goalCalories = 2000.0
    @Published var goalProtein = 150.0
    @Published var goalCarbs = 200.0
    @Published var goalFat = 65.0
    @Published var goalWater = 2000.0

    var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }
    
    func loadProfile() {
        guard let profile = UserDefaults.standard.dictionary(forKey: "userProfile") else { return }
        userName = profile["userName"] as? String ?? "User"
        goalCalories = profile["calories"] as? Double ?? 2000
        goalProtein = profile["protein"] as? Double ?? 150
        goalCarbs = profile["carbs"] as? Double ?? 200
        goalFat = profile["fat"] as? Double ?? 65
        goalWater = profile["water"] as? Double ?? 2000
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
