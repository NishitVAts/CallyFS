//
//  MealPlansView.swift
//  CallyFS
//

import SwiftUI
import SwiftData

struct MealPlansView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlan.createdAt, order: .reverse) private var mealPlans: [MealPlan]
    @State private var showGenerateSheet = false
    @State private var selectedPlan: MealPlan?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                if mealPlans.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            ForEach(mealPlans) { plan in
                                MealPlanCard(plan: plan) {
                                    HapticManager.shared.light()
                                    selectedPlan = plan
                                }
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.top, AppTheme.Spacing.xl)
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Meal Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.light()
                        showGenerateSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showGenerateSheet) {
                GenerateMealPlanView()
            }
            .sheet(item: $selectedPlan) { plan in
                MealPlanDetailView(plan: plan)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 110, height: 110)
                .liquidGlass(in: Circle(), fallback: AppTheme.Colors.surfaceElevated)
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("No Meal Plans Yet")
                    .font(AppTheme.Typography.title3())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Generate AI-powered meal plans tailored to your goals and preferences")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.massive)
            }
            
            Button(action: {
                HapticManager.shared.light()
                showGenerateSheet = true
            }) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(AppTheme.Typography.body(weight: .semibold))
                    Text("Generate Meal Plan")
                        .font(AppTheme.Typography.body(weight: .semibold))
                }
                .foregroundColor(AppTheme.Colors.background)
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.vertical, AppTheme.Spacing.lg)
                .liquidGlass(in: Capsule(), tint: AppTheme.Colors.accent, fallback: AppTheme.Colors.accent)
            }
            
            Spacer()
        }
    }
    
}

struct MealPlanCard: View {
    let plan: MealPlan
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(AppTheme.Typography.body(weight: .bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("\(plan.duration) days")
                            .font(AppTheme.Typography.caption1())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    if plan.isActive {
                        Text("Active")
                            .font(AppTheme.Typography.caption2(weight: .semibold))
                            .foregroundColor(AppTheme.Colors.success)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(AppTheme.Colors.success.opacity(0.15))
                            .cornerRadius(AppTheme.CornerRadius.xs)
                    }
                }
                
                Text(plan.createdAt, style: .date)
                    .font(AppTheme.Typography.caption2())
                    .foregroundColor(AppTheme.Colors.textQuaternary)
                
                HStack {
                    Image(systemName: "sparkles")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.accent)
                    Text("AI Generated")
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Typography.caption1(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                }
            }
            .padding(AppTheme.Spacing.xl)
            .elevatedCardStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plan Detail

struct MealPlanDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    let plan: MealPlan
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                        headerCard
                        planContent
                        Spacer().frame(height: AppTheme.Spacing.xxl)
                    }
                    .padding(AppTheme.Spacing.xl)
                }
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.Colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: toggleActive) {
                            Label(plan.isActive ? "Deactivate" : "Set as Active Plan",
                                  systemImage: plan.isActive ? "pause.circle" : "checkmark.circle")
                        }
                        Button(role: .destructive, action: { showDeleteConfirm = true }) {
                            Label("Delete Plan", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
            }
            .confirmationDialog("Delete this meal plan?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: deletePlan)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(AppTheme.Typography.title3())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    HStack(spacing: 6) {
                        Text("\(plan.duration) days")
                        Circle().fill(AppTheme.Colors.textQuaternary).frame(width: 3, height: 3)
                        Text(plan.createdAt, style: .date)
                    }
                    .font(AppTheme.Typography.caption1())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                }
                Spacer()
                if plan.isActive {
                    Text("Active")
                        .font(AppTheme.Typography.caption2(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.success.opacity(0.15))
                        .cornerRadius(AppTheme.CornerRadius.xs)
                }
            }

            Button(action: toggleActive) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: plan.isActive ? "pause.circle.fill" : "checkmark.circle.fill")
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                    Text(plan.isActive ? "Deactivate Plan" : "Set as Active Plan")
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                }
                .foregroundColor(plan.isActive ? AppTheme.Colors.textSecondary : AppTheme.Colors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .liquidGlass(
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg),
                    tint: plan.isActive ? nil : AppTheme.Colors.accent,
                    fallback: plan.isActive ? AppTheme.Colors.surfaceHighlight : AppTheme.Colors.accent
                )
            }
        }
        .padding(AppTheme.Spacing.lg)
        .elevatedCardStyle()
    }

    private var planContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ForEach(PlanMarkdown.blocks(from: plan.aiGeneratedPlan)) { block in
                blockView(block)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }

    @ViewBuilder
    private func blockView(_ block: PlanMarkdown.Block) -> some View {
        switch block.kind {
        case .heading(let level):
            Text(block.text)
                .font(level <= 1 ? AppTheme.Typography.title3()
                      : level == 2 ? AppTheme.Typography.headline()
                      : AppTheme.Typography.body(weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.top, AppTheme.Spacing.sm)
        case .bullet:
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Circle()
                    .fill(AppTheme.Colors.accentSecondary)
                    .frame(width: 4, height: 4)
                    .padding(.top, 7)
                Text(PlanMarkdown.inline(block.text))
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineSpacing(3)
            }
        case .paragraph:
            Text(PlanMarkdown.inline(block.text))
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: Actions

    private func toggleActive() {
        if plan.isActive {
            plan.isActive = false
        } else {
            // Only one plan can be active at a time.
            let descriptor = FetchDescriptor<MealPlan>()
            if let all = try? modelContext.fetch(descriptor) {
                for other in all { other.isActive = false }
            }
            plan.isActive = true
        }
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            HapticManager.shared.error()
        }
    }

    private func deletePlan() {
        modelContext.delete(plan)
        do {
            try modelContext.save()
            HapticManager.shared.deleteItem()
            dismiss()
        } catch {
            HapticManager.shared.error()
        }
    }
}

/// Minimal markdown block parser for AI-generated plans: headings, bullets and
/// paragraphs, with inline styling (bold/italic) handled by AttributedString.
enum PlanMarkdown {
    struct Block: Identifiable {
        enum Kind {
            case heading(Int)
            case bullet
            case paragraph
        }
        let id = UUID()
        let kind: Kind
        let text: String
    }

    static func blocks(from markdown: String) -> [Block] {
        var blocks: [Block] = []
        var paragraph: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(Block(kind: .paragraph, text: paragraph.joined(separator: " ")))
            paragraph = []
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
            } else if line.hasPrefix("#") {
                flushParagraph()
                let level = line.prefix(while: { $0 == "#" }).count
                let text = line.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                blocks.append(Block(kind: .heading(level), text: text))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") {
                flushParagraph()
                blocks.append(Block(kind: .bullet, text: String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)))
            } else if let match = line.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
                flushParagraph()
                blocks.append(Block(kind: .bullet, text: String(line[match.upperBound...])))
            } else {
                paragraph.append(line)
            }
        }
        flushParagraph()
        return blocks
    }

    static func inline(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}

struct GenerateMealPlanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var planName = ""
    @State private var duration = 7
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    let durationOptions = [3, 5, 7, 14, 30]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("PLAN NAME")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            TextField("e.g. Summer Shred Plan", text: $planName)
                                .font(AppTheme.Typography.body())
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .autocorrectionDisabled()
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.surfaceElevated)
                                .cornerRadius(AppTheme.CornerRadius.xl)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                                        .stroke(AppTheme.Colors.border, lineWidth: 1.5)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("DURATION")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            Picker("Duration", selection: $duration) {
                                ForEach(durationOptions, id: \.self) { days in
                                    Text("\(days) days").tag(days)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("WHAT TO EXPECT")
                                .font(AppTheme.Typography.label())
                                .foregroundColor(AppTheme.Colors.textQuaternary)
                                .tracking(1.2)
                            
                            VStack(spacing: AppTheme.Spacing.sm) {
                                FeatureRow(icon: "sparkles", text: "AI-powered meal suggestions")
                                FeatureRow(icon: "chart.bar.fill", text: "Balanced macros for your goals")
                                FeatureRow(icon: "fork.knife", text: "Variety and delicious recipes")
                                FeatureRow(icon: "clock.fill", text: "Easy to prepare meals")
                            }
                            .padding(AppTheme.Spacing.lg)
                            .background(AppTheme.Colors.surfaceElevated)
                            .cornerRadius(AppTheme.CornerRadius.lg)
                        }
                        
                        if let error = errorMessage {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.Colors.error)
                                Text(error)
                                    .font(AppTheme.Typography.caption1())
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.error.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.md)
                        }
                        
                        Button(action: generatePlan) {
                            HStack(spacing: 10) {
                                if isGenerating {
                                    ProgressView()
                                        .tint(AppTheme.Colors.background)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Generate Plan")
                                        .font(AppTheme.Typography.body(weight: .semibold))
                                }
                            }
                            .foregroundColor(planName.isEmpty ? AppTheme.Colors.textQuaternary : AppTheme.Colors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .liquidGlass(
                                in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl),
                                tint: planName.isEmpty ? nil : AppTheme.Colors.accent,
                                fallback: planName.isEmpty ? AppTheme.Colors.surfaceElevated : AppTheme.Colors.accent
                            )
                        }
                        .disabled(planName.isEmpty || isGenerating)
                        .animation(AppTheme.Animation.easeInOut, value: planName.isEmpty)
                        .animation(AppTheme.Animation.easeInOut, value: isGenerating)
                    }
                    .padding(AppTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Generate Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                    .disabled(isGenerating)
                }
            }
        }
    }
    
    private func generatePlan() {
        guard !planName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        
        guard let profile = UserDefaults.standard.dictionary(forKey: "userProfile"),
              let calories = profile["calories"] as? Double,
              let protein = profile["protein"] as? Double,
              let carbs = profile["carbs"] as? Double,
              let fat = profile["fat"] as? Double,
              let goalString = profile["goal"] as? String,
              let goal = FitnessGoal(rawValue: goalString) else {
            errorMessage = "Unable to load profile data"
            isGenerating = false
            return
        }
        
        let dietRequirements = (profile["dietRequirements"] as? [String]) ?? []
        
        Task {
            do {
                let planContent = try await AIService.shared.generateMealPlan(
                    name: planName,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    goal: goal,
                    dietaryRestrictions: dietRequirements,
                    duration: duration
                )
                
                await MainActor.run {
                    let newPlan = MealPlan(
                        name: planName,
                        aiGeneratedPlan: planContent,
                        isActive: false,
                        duration: duration
                    )

                    modelContext.insert(newPlan)
                    do {
                        try modelContext.save()
                        HapticManager.shared.success()
                        dismiss()
                    } catch {
                        modelContext.delete(newPlan)
                        errorMessage = "Your plan was generated but couldn't be saved. Please try again."
                        isGenerating = false
                        HapticManager.shared.error()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                    HapticManager.shared.error()
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    MealPlansView()
        .preferredColorScheme(.dark)
}
