

import SwiftUI

// MARK: - Capsule Button Bar

struct capsuleBars: View {
    var textLabel: String = "Sign in with Apple"
    var bgColor: Color = .black
    var strokeOrNot: Bool = false

    var body: some View {
        Capsule()
            .fill(bgColor)
            .stroke(strokeOrNot ? Color.gray : Color.clear)
            .frame(height: 60)
            .overlay(
                Text(textLabel)
                    .foregroundColor(bgColor == .black ? .white : .black)
                    .font(.headline)
            )
    }
}

// MARK: - Brand Header (shared large title across screens)

/// A branded scrolling header using the app's Georgia display font, matching the
/// Dashboard. Use at the top of a screen's scroll content for a cohesive identity.
struct BrandHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                if let subtitle {
                    Text(subtitle)
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                Text(title)
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            Spacer()
            if let trailing {
                trailing
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.bottom, AppTheme.Spacing.lg)
    }
}

/// A small uppercase section label used above grouped content.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(AppTheme.Typography.label())
            .foregroundColor(AppTheme.Colors.textQuaternary)
            .tracking(1.4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Nutrition input fields (shared by meal editing + manual logging)

extension View {
    /// Standard chrome for a nutrition input field.
    func inputFieldChrome() -> some View {
        self
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .stroke(AppTheme.Colors.border, lineWidth: 1.5)
            )
    }
}

/// A labeled calories row with a trailing numeric field.
struct CalorieInputField: View {
    @Binding var calories: Int

    var body: some View {
        HStack {
            Text("Calories")
                .font(AppTheme.Typography.subheadline(weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
            TextField("0", value: $calories, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(AppTheme.Typography.body(weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .frame(width: 90)
            Text("kcal")
                .font(AppTheme.Typography.caption1())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .inputFieldChrome()
    }
}

/// A compact gram field for one macro, with a colored dot label.
struct MacroInputField: View {
    let label: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label)
                    .font(AppTheme.Typography.caption2(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            HStack(spacing: 2) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .font(AppTheme.Typography.body(weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("g")
                    .font(AppTheme.Typography.caption1())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Goal Calculator

/// Daily nutrition targets derived from a user's stats and goal.
struct GoalTargets {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let water: Double
}

/// Mifflin-St Jeor BMR → activity-adjusted TDEE → goal-adjusted daily targets.
/// Single source of truth for goal math; used by onboarding and Profile's
/// "Recalculate Goals".
enum GoalCalculator {
    static func targets(
        weightKg: Double,
        heightCm: Double,
        ageYears: Int,
        sex: Sex,
        workouts: workoutRange,
        goal: FitnessGoal
    ) -> GoalTargets {
        let male   = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears)) + 5
        let female = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears)) - 161

        let bmr: Double
        switch sex {
        case .male:   bmr = male
        case .female: bmr = female
        default:      bmr = (male + female) / 2
        }

        let tdee = bmr * workouts.activityMultiplier

        let calories: Double
        switch goal {
        case .lose:               calories = tdee - 500
        case .gain:               calories = tdee + 400
        case .maintain, .improve: calories = tdee
        case .notSet:             calories = 2000
        }

        let protein: Double
        let fat: Double
        switch goal {
        case .lose: protein = weightKg * 2.0; fat = weightKg * 0.8
        case .gain: protein = weightKg * 2.2; fat = weightKg * 1.0
        default:    protein = weightKg * 1.8; fat = weightKg * 0.9
        }
        let carbs = max((calories - protein * 4 - fat * 9) / 4, 0)

        // ~35ml per kg of body weight, rounded to the nearest 250ml glass
        let water = max((weightKg * 35 / 250).rounded() * 250, 1500)

        return GoalTargets(calories: calories, protein: protein, carbs: carbs, fat: fat, water: water)
    }

    /// Recomputes targets from the persisted `userProfile` dictionary and writes
    /// the updated calorie/macro/water values back. Returns the new targets, or
    /// nil if the stored profile is missing the required stats.
    @discardableResult
    static func recalculateAndPersist() -> GoalTargets? {
        guard var profile = UserDefaults.standard.dictionary(forKey: "userProfile"),
              let weightKg = Double(profile["weight"] as? String ?? ""),
              let heightMeters = Double(profile["height"] as? String ?? ""),
              let ageYears = Int(profile["age"] as? String ?? "")
        else { return nil }

        let sex = Sex(rawValue: profile["sex"] as? String ?? "") ?? .notSet
        let workouts = workoutRange(rawValue: profile["workouts"] as? String ?? "") ?? .nowAndThen
        let goal = FitnessGoal(rawValue: profile["goal"] as? String ?? "") ?? .maintain

        let targets = self.targets(
            weightKg: weightKg,
            heightCm: heightMeters * 100,
            ageYears: ageYears,
            sex: sex,
            workouts: workouts,
            goal: goal
        )

        profile["calories"] = targets.calories
        profile["protein"]  = targets.protein
        profile["carbs"]    = targets.carbs
        profile["fat"]      = targets.fat
        profile["water"]    = targets.water
        UserDefaults.standard.set(profile, forKey: "userProfile")

        return targets
    }
}

// MARK: - Liquid Glass helper

extension View {
    /// Applies an iOS 26 Liquid Glass effect clipped to `shape`. On earlier
    /// systems it falls back to a solid `fallback` fill so the control still
    /// reads as a tappable surface. Pass a `tint` to give the glass a color
    /// (use for prominent / selected controls).
    @ViewBuilder
    func liquidGlass<S: Shape>(in shape: S, tint: Color? = nil, fallback: Color) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                self.glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            self.background(fallback, in: shape)
        }
    }
}

// MARK: - Color Hex Extension (single declaration for whole project)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
