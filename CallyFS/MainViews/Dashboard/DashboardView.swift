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
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    headerSection
                    
                    calorieCard
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                        .padding(.top, AppTheme.Spacing.xxl)
                    
                    macrosSection
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                        .padding(.top, AppTheme.Spacing.lg)
                    
                    waterTrackingCard
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                        .padding(.top, AppTheme.Spacing.xxl)
                    
                    mealsSection
                        .padding(.top, AppTheme.Spacing.xxxl)
                    
                    Spacer().frame(height: 120)
                    
                }
            }
        }
        .onAppear {
            viewModel.loadProfile()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greetingText)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text(viewModel.userName)
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            Spacer()
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gear.circle.fill")
            }

        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .padding(.top, AppTheme.Spacing.xl)
    }
    
    private var calorieCard: some View {
        let todayMeals = mealsForToday()
        let eatenCalories = todayMeals.reduce(0) { $0 + $1.calories }
        let remaining = max(Int(viewModel.goalCalories) - eatenCalories, 0)
        let progress = min(Double(eatenCalories) / viewModel.goalCalories, 1.0)
        
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
                    HStack(spacing: 8) {
                        Text("Daily")
                            .font(.custom("Georgia", size: 15))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text("CALORIES")
                            .font(.custom("Georgia-Bold", size: 15))
                            .foregroundColor(AppTheme.Colors.accentSecondary)
                            .tracking(1.8)
                    }
                    Spacer()
                }
                
                Spacer().frame(height: 22)
                
                Text("Eaten \(eatenCalories)")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Spacer().frame(height: 8)
                
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("\(remaining)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("KCAL LEFT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .tracking(1.2)
                        .padding(.bottom, 10)
                }
                
                Spacer().frame(height: 22)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.Colors.surfaceHighlight)
                            .frame(height: 40)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.Colors.gradientStart, AppTheme.Colors.gradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 40)
                            .animation(AppTheme.Animation.springBouncy, value: progress)
                        
                        if eatenCalories > 0 {
                            Text("\(eatenCalories) KCAL")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.Colors.background)
                                .padding(.leading, 14)
                        }
                    }
                }
                .frame(height: 40)
            }
            .padding(AppTheme.Spacing.xxl)
        }
        .frame(height: 240)
    }
    
    private var macrosSection: some View {
        let todayMeals = mealsForToday()
        let totalProtein = todayMeals.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = todayMeals.reduce(0.0) { $0 + $1.carbs }
        let totalFat = todayMeals.reduce(0.0) { $0 + $1.fat }
        
        return HStack(spacing: 14) {
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
        let goalWater = 2000.0
        let progress = min(totalWater / goalWater, 1.0)
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.info)
                
                Text("Water Intake")
                    .font(AppTheme.Typography.body(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    addWater(250)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("250ml")
                            .font(AppTheme.Typography.caption1(weight: .semibold))
                    }
                    .foregroundColor(AppTheme.Colors.info)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.info.opacity(0.15))
                    .cornerRadius(AppTheme.CornerRadius.sm)
                }
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(totalWater))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("/ \(Int(goalWater)) ml")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.Colors.info)
                        .frame(width: geo.size.width * progress, height: 12)
                        .animation(AppTheme.Animation.springBouncy, value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding(AppTheme.Spacing.xl)
        .elevatedCardStyle()
    }
    
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Meals")
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Text(Date(), style: .date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textQuaternary)
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            
            ForEach(MealSlot.SlotType.allCases, id: \.self) { slotType in
                NavigationLink(destination: MealDetailView(slotType: slotType)) {
                    MealSlotCard(
                        slotType: slotType,
                        meals: mealsForSlot(slotType)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppTheme.Spacing.xxl)
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
        HapticManager.shared.success()
        let waterLog = WaterLog(amount: amount)
        modelContext.insert(waterLog)
        try? modelContext.save()
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
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(AppTheme.Typography.footnote(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(Int(current))")
                    .font(AppTheme.Typography.body(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(" / \(Int(total))g")
                    .font(AppTheme.Typography.footnote())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(height: 5)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 5)
                        .animation(AppTheme.Animation.springBouncy, value: progress)
                }
            }
            .frame(height: 5)
        }
        .padding(14)
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
        HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.surfaceElevated)
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )
                
                Text(slotType.emoji)
                    .font(.system(size: 26))
                    .frame(width: 56, height: 56)
                
                if isLogged {
                    Circle()
                        .fill(AppTheme.Colors.textPrimary)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AppTheme.Colors.background)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2)
                        .offset(x: 8, y: -8)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(slotType.rawValue)
                    .font(AppTheme.Typography.callout(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if isLogged {
                    if hasCalculating {
                        Text("Calculating...")
                            .font(AppTheme.Typography.footnote(weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            
                    } else {
                        HStack(spacing: 8) {
                            Text("\(meals.count) item\(meals.count == 1 ? "" : "s")")
                                .font(AppTheme.Typography.footnote())
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Circle()
                                .fill(AppTheme.Colors.textQuaternary)
                                .frame(width: 3, height: 3)
                            Text("\(totalCalories) kcal")
                                .font(AppTheme.Typography.footnote(weight: .semibold))
                                .foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                    }
                } else {
                    Text("Tap to add food")
                        .font(AppTheme.Typography.footnote())
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.footnote(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textDisabled)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
