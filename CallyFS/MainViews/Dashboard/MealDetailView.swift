//
//  MealDetailView.swift
//  CallyFS
//
//  Revamped: shows detailed macros, sticky Add button, custom bottom panel, reusable for all meal slots.
//

import SwiftUI
import SwiftData

struct MealDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMeals: [MealLog]

    let slotType: MealSlot.SlotType
    @State private var showAddPanel = false

    // MARK: - Derived data

    var meals: [MealLog] {
        allMeals.filter {
            Calendar.current.isDateInToday($0.timestamp) &&
            $0.mealType == slotType.rawValue
        }
    }

    var totalCalories: Int   { meals.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { meals.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double   { meals.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double     { meals.reduce(0) { $0 + $1.fat } }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    navBar
                    summaryCard
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.xxl)

                    if meals.isEmpty {
                        emptyState
                    } else {
                        mealsList
                    }

                    Spacer().frame(height: 120)
                }
            }

            addButton

            // Custom bottom panel overlay
            if showAddPanel {
                AddMealPanel(slotType: slotType, isPresented: $showAddPanel)
                    .transition(.identity) // panel animates itself
                    .zIndex(10)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 14) {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.surfaceElevated)
                        .frame(width: 38, height: 38)
                        .overlay(Circle().stroke(AppTheme.Colors.border, lineWidth: 1))
                    Image(systemName: "chevron.left")
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Text(slotType.emoji)
                .font(.system(size: 22))

            Text(slotType.rawValue)
                .font(AppTheme.Typography.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            // Date badge
            Text(Date(), style: .date)
                .font(AppTheme.Typography.caption1())
                .foregroundColor(AppTheme.Colors.textQuaternary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.Colors.surfaceElevated)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.Colors.border, lineWidth: 1))
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.top, AppTheme.Spacing.lg)
    }

    // MARK: - Summary Card (calories + macros)

    private var summaryCard: some View {
        VStack(spacing: 0) {
            // Calorie row
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(totalCalories)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("kcal")
                    .font(AppTheme.Typography.callout(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textQuaternary)
                    .offset(y: -4)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(meals.count) item\(meals.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.caption1(weight: .medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text("today")
                        .font(AppTheme.Typography.caption2())
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.xl)

            // Divider
            Rectangle()
                .fill(AppTheme.Colors.border)
                .frame(height: 1)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.lg)

            // Macro row
            HStack(spacing: 0) {
                macroCell(label: "Protein", value: totalProtein, color: AppTheme.Colors.macroProtein)
                macroDivider()
                macroCell(label: "Carbs", value: totalCarbs, color: AppTheme.Colors.macroCarbs)
                macroDivider()
                macroCell(label: "Fat", value: totalFat, color: AppTheme.Colors.macroFat)
            }
            .padding(.vertical, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.xxl)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxl)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func macroCell(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("g")
                    .font(AppTheme.Typography.caption1())
                    .foregroundColor(AppTheme.Colors.textQuaternary)
            }
            Text(label)
                .font(AppTheme.Typography.caption2(weight: .medium))
                .foregroundColor(AppTheme.Colors.textTertiary)

            // Mini indicator bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.Colors.borderLight)
                    .frame(height: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: totalCalories > 0 ? geo.size.width * macroRatio(value: value) : 0, height: 3),
                        alignment: .leading
                    )
            }
            .frame(height: 3)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func macroRatio(value: Double) -> CGFloat {
        let total = totalProtein + totalCarbs + totalFat
        guard total > 0 else { return 0 }
        return min(CGFloat(value / total), 1.0)
    }

    private func macroDivider() -> some View {
        Rectangle()
            .fill(AppTheme.Colors.border)
            .frame(width: 1, height: 40)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 60)
            Text(slotType.emoji)
                .font(.system(size: 52))
            Text("Nothing logged yet")
                .font(AppTheme.Typography.body(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text("Tap below to add your first item")
                .font(AppTheme.Typography.footnote())
                .foregroundColor(AppTheme.Colors.textDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Meals List

    private var mealsList: some View {
        VStack(spacing: 8) {
            ForEach(meals) { meal in
                MealItemCard(meal: meal) {
                    deleteMeal(meal)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.top, AppTheme.Spacing.xl)
    }

    // MARK: - Add Button (sticky bottom)

    private var addButton: some View {
        Button(action: {
            HapticManager.shared.light()
            showAddPanel = true
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(width: 28, height: 28)
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                Text("Add to \(slotType.rawValue)")
                    .font(AppTheme.Typography.callout(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.surfaceHighlight)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.Colors.accent)
            .cornerRadius(AppTheme.CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .stroke(AppTheme.Colors.borderLight, lineWidth: 1)
            )
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        
        .background(
            // Fade effect so list content doesn't feel cut off
            LinearGradient(
                colors: [AppTheme.Colors.background.opacity(0), AppTheme.Colors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false),
            alignment: .top
        )
    }

    // MARK: - Delete

    private func deleteMeal(_ meal: MealLog) {
        HapticManager.shared.deleteItem()
        withAnimation(AppTheme.Animation.spring) {
            modelContext.delete(meal)
        }
    }
}

// MARK: - MealItemCard (expanded with macros)

struct MealItemCard: View {
    let meal: MealLog
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.Colors.border, lineWidth: 1)
                        )
                    Text(meal.emoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name)
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    if meal.calories == 0 {
                        Label("Calculating…", systemImage: "sparkles")
                            .font(AppTheme.Typography.caption2(weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    } else {
                        Text(meal.timestamp, style: .time)
                            .font(AppTheme.Typography.caption2())
                            .foregroundColor(AppTheme.Colors.textDisabled)
                    }
                }

                Spacer()

                if meal.calories == 0 {
                    Image(systemName: "sparkles")
                        .font(AppTheme.Typography.subheadline())
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                } else {
                    Text("\(meal.calories) kcal")
                        .font(AppTheme.Typography.footnote(weight: .bold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(AppTheme.Typography.footnote())
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Macro chips row (only when calories are available)
            if meal.calories > 0 {
                HStack(spacing: 6) {
                    macroPill(value: meal.protein, label: "P", color: AppTheme.Colors.macroProtein)
                    macroPill(value: meal.carbs,   label: "C", color: AppTheme.Colors.macroCarbs)
                    macroPill(value: meal.fat,     label: "F", color: AppTheme.Colors.macroFat)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 8)
            } else {
                Spacer().frame(height: 12)
            }
        }
        .background(AppTheme.Colors.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func macroPill(value: Double, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color.opacity(0.7))
            Text(String(format: "%.0fg", value))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.Colors.surfaceHighlight)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Keyboard height observer

final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        withAnimation(.easeOut(duration: duration)) {
            keyboardHeight = frame.height
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        withAnimation(.easeOut(duration: duration)) {
            keyboardHeight = 0
        }
    }
}

// MARK: - AddMealPanel (custom bottom overlay, keyboard-aware)

struct AddMealPanel: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var keyboard = KeyboardObserver()

    let slotType: MealSlot.SlotType
    @Binding var isPresented: Bool

    @State private var mealName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var dragOffset: CGFloat = 0
    @State private var isVisible = false
    @FocusState private var isNameFocused: Bool

    private let dismissThreshold: CGFloat = 80

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop — tap to dismiss
            Color.black
                .opacity(isVisible ? 0.55 : 0)
                .ignoresSafeArea()
                .onTapGesture { close() }
                .animation(.easeInOut(duration: 0.22), value: isVisible)

            // Panel
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.Colors.borderHighlight)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WHAT DID YOU EAT?")
                            .font(AppTheme.Typography.label())
                            .foregroundColor(AppTheme.Colors.textQuaternary)
                            .tracking(1.2)
                        Text(slotType.rawValue)
                            .font(AppTheme.Typography.headline())
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }

                    Spacer()

                    // Close button
                    Button(action: { close() }) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.surfaceHighlight)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(AppTheme.Colors.border, lineWidth: 1))
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                // Text field
                TextField("e.g. Grilled Chicken Salad", text: $mealName)
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .focused($isNameFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { if !mealName.isEmpty { logMeal() } }
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.surfaceHighlight)
                    .cornerRadius(AppTheme.CornerRadius.xl)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                            .stroke(
                                isNameFocused
                                    ? AppTheme.Colors.accent.opacity(0.25)
                                    : AppTheme.Colors.border,
                                lineWidth: 1.5
                            )
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.xl)

                // Error
                if let error = errorMessage {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.Colors.error)
                        Text(error)
                            .font(AppTheme.Typography.caption1())
                            .foregroundColor(AppTheme.Colors.error)
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.error.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Log button
                Button(action: logMeal) {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .tint(mealName.isEmpty ? AppTheme.Colors.textQuaternary : AppTheme.Colors.background)
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Log to \(slotType.rawValue)")
                                .font(AppTheme.Typography.body(weight: .semibold))
                        }
                    }
                    .foregroundColor(mealName.isEmpty ? AppTheme.Colors.textQuaternary : AppTheme.Colors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(mealName.isEmpty ? AppTheme.Colors.surfaceElevated : AppTheme.Colors.accent)
                    .cornerRadius(AppTheme.CornerRadius.xl)
                }
                .disabled(mealName.isEmpty || isLoading)
                .animation(AppTheme.Animation.easeInOut, value: mealName.isEmpty)
                .animation(AppTheme.Animation.easeInOut, value: isLoading)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.xl)
                // Bottom padding — shrinks when keyboard is up
                Spacer().frame(height: keyboard.keyboardHeight > 0 ? AppTheme.Spacing.lg : AppTheme.Spacing.xxxl)
            }
            .background(
                AppTheme.Colors.surfaceElevated
                    .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))
            )
            .overlay(
                RoundedCorner(radius: 28, corners: [.topLeft, .topRight])
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
            // Lift panel above keyboard
            .padding(.bottom, keyboard.keyboardHeight)
            // Drag to dismiss (only when keyboard is hidden)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard keyboard.keyboardHeight == 0 else { return }
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        guard keyboard.keyboardHeight == 0 else { return }
                        if value.translation.height > dismissThreshold {
                            close()
                        } else {
                            withAnimation(AppTheme.Animation.spring) { dragOffset = 0 }
                        }
                    }
            )
            .offset(y: isVisible ? dragOffset : 500)
            .animation(AppTheme.Animation.spring, value: isVisible)
            .animation(AppTheme.Animation.spring, value: dragOffset)
        }
        .ignoresSafeArea()
        .onAppear {
            // Slight delay so ZStack renders before animating in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isVisible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNameFocused = true
                }
            }
        }
    }

    // MARK: - Close

    private func close() {
        isNameFocused = false
        withAnimation(AppTheme.Animation.easeInOut) { isVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }

    // MARK: - Log meal

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
            emoji: slotType.emoji,
            mealType: slotType.rawValue
        )

        modelContext.insert(tempMeal)

        Task {
            do {
                let nutrition = try await AIService.shared.getNutritionInfo(for: mealName)

                await MainActor.run {
                    tempMeal.calories = nutrition.calories
                    tempMeal.protein  = nutrition.protein
                    tempMeal.carbs    = nutrition.carbs
                    tempMeal.fat      = nutrition.fat

                    try? modelContext.save()
                    HapticManager.shared.success()
                    close()
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        if let aiError = error as? AIServiceError {
                            errorMessage = aiError.errorDescription
                        } else {
                            errorMessage = "Failed to analyze meal. Please try again."
                        }
                    }
                    modelContext.delete(tempMeal)
                    isLoading = false
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// MARK: - RoundedCorner helper (top-only radius)

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview("Breakfast") {
    MealDetailView(slotType: .breakfast)
        .preferredColorScheme(.dark)
}

