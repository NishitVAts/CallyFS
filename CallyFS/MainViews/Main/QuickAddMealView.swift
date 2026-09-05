//
//  QuickAddMealView.swift
//  CallyFS
//

import SwiftUI
import SwiftData
import Speech
import AVFoundation

struct QuickAddMealView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.timestamp, order: .reverse) private var recentMeals: [MealLog]

    @State private var mealName = ""
    @State private var selectedCategory: MealSlot.SlotType = .breakfast
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isManualMode = false
    @State private var manualCalories = 0
    @State private var manualProtein = 0.0
    @State private var manualCarbs = 0.0
    @State private var manualFat = 0.0
    @FocusState private var isNameFocused: Bool
    @StateObject private var speech = SpeechRecognizer()

    /// Most recent distinct, fully-analyzed meals — the "repeat your usual" list.
    private var recents: [MealLog] {
        var seen = Set<String>()
        var out: [MealLog] = []
        for meal in recentMeals where meal.calories > 0 {
            let key = meal.name.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            out.append(meal)
            if out.count == 8 { break }
        }
        return out
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                        if !recents.isEmpty {
                            recentsSection
                        }

                        inputSection

                        modeSelector

                        if isManualMode {
                            manualSection
                        }

                        mealTypeSection

                        if let error = errorMessage {
                            errorBanner(error)
                        }

                        addButton
                    }
                    .padding(AppTheme.Spacing.xl)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.cardDismiss()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(AppTheme.Typography.subheadline(weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .liquidGlass(in: Circle(), fallback: AppTheme.Colors.surfaceElevated)
                    }
                }
            }
            .onChange(of: speech.transcript) { _, newValue in
                if speech.isRecording { mealName = newValue }
            }
            .onDisappear { speech.stop() }
        }
    }

    // MARK: - Recents (instant re-log)

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: "Log your usual")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(recents) { meal in
                        Button {
                            relog(meal)
                        } label: {
                            HStack(spacing: 7) {
                                Text(meal.emoji)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(meal.name)
                                        .font(AppTheme.Typography.caption1(weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .lineLimit(1)
                                    Text("\(meal.calories) kcal")
                                        .font(AppTheme.Typography.caption2())
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .liquidGlass(in: Capsule(), fallback: AppTheme.Colors.surfaceElevated)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Input + voice

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: speech.isRecording ? "Listening…" : "What did you eat?")

            HStack(spacing: AppTheme.Spacing.md) {
                TextField("Type or say a meal", text: $mealName)
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .focused($isNameFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .disabled(speech.isRecording)

                Button(action: toggleVoice) {
                    Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(speech.isRecording ? AppTheme.Colors.background : AppTheme.Colors.accent)
                        .frame(width: 36, height: 36)
                        .liquidGlass(
                            in: Circle(),
                            tint: speech.isRecording ? AppTheme.Colors.error : nil,
                            fallback: speech.isRecording ? AppTheme.Colors.error : AppTheme.Colors.surfaceHighlight
                        )
                        .scaleEffect(speech.isRecording ? 1.08 : 1)
                        .animation(speech.isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                                   value: speech.isRecording)
                }
                .accessibilityLabel(speech.isRecording ? "Stop voice input" : "Log by voice")
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .stroke(
                        speech.isRecording ? AppTheme.Colors.error.opacity(0.5)
                            : (isNameFocused ? AppTheme.Colors.accent.opacity(0.3) : AppTheme.Colors.border),
                        lineWidth: 1.5
                    )
            )

            if !isManualMode {
                Text("Tip: say something like “two eggs and toast with butter.”")
                    .font(AppTheme.Typography.caption2())
                    .foregroundColor(AppTheme.Colors.textQuaternary)
            }
        }
    }

    // MARK: - Entry mode (AI estimate vs manual)

    private var modeSelector: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            modePill(title: "AI Estimate", icon: "sparkles", isActive: !isManualMode) {
                isManualMode = false
            }
            modePill(title: "Manual", icon: "keyboard", isActive: isManualMode) {
                isManualMode = true
            }
        }
    }

    private func modePill(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.selectionChanged()
            withAnimation(AppTheme.Animation.easeInOut) { action() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(AppTheme.Typography.footnote(weight: .semibold))
            }
            .foregroundColor(isActive ? AppTheme.Colors.background : AppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .liquidGlass(
                in: Capsule(),
                tint: isActive ? AppTheme.Colors.accent : nil,
                fallback: isActive ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated
            )
        }
        .buttonStyle(.plain)
    }

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: "Nutrition")

            CalorieInputField(calories: $manualCalories)

            HStack(spacing: AppTheme.Spacing.sm) {
                MacroInputField(label: "Protein", value: $manualProtein, color: AppTheme.Colors.macroProtein)
                MacroInputField(label: "Carbs", value: $manualCarbs, color: AppTheme.Colors.macroCarbs)
                MacroInputField(label: "Fat", value: $manualFat, color: AppTheme.Colors.macroFat)
            }

            Text("Macros are optional — calories are enough. Works offline.")
                .font(AppTheme.Typography.caption2())
                .foregroundColor(AppTheme.Colors.textQuaternary)
        }
    }

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionLabel(text: "Meal type")

            Menu {
                ForEach(MealSlot.SlotType.allCases, id: \.self) { category in
                    Button(action: {
                        HapticManager.shared.categorySelection()
                        withAnimation(AppTheme.Animation.easeInOut) { selectedCategory = category }
                    }) {
                        HStack {
                            Text(category.emoji)
                            Text(category.rawValue)
                            if selectedCategory == category {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory.emoji).font(.system(size: 22))
                    Text(selectedCategory.rawValue)
                        .font(AppTheme.Typography.body(weight: .medium))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTheme.Typography.footnote(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textQuaternary)
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                        .stroke(AppTheme.Colors.border, lineWidth: 1.5)
                )
            }
        }
    }

    private var addButton: some View {
        Button(action: logMeal) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(canAdd ? AppTheme.Colors.background : AppTheme.Colors.textQuaternary)
                } else {
                    Image(systemName: isManualMode ? "plus" : "sparkles")
                        .font(AppTheme.Typography.footnote(weight: .semibold))
                    Text("Add Meal")
                        .font(AppTheme.Typography.body(weight: .semibold))
                }
            }
            .foregroundColor(canAdd ? AppTheme.Colors.background : AppTheme.Colors.textQuaternary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .liquidGlass(
                in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl),
                tint: canAdd ? AppTheme.Colors.accent : nil,
                fallback: canAdd ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated
            )
        }
        .disabled(!canAdd || isLoading)
        .animation(AppTheme.Animation.easeInOut, value: canAdd)
        .animation(AppTheme.Animation.easeInOut, value: isLoading)
    }

    private var canAdd: Bool {
        guard !mealName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return isManualMode ? manualCalories > 0 : true
    }

    private func errorBanner(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.Colors.error)
                Text(message)
                    .font(AppTheme.Typography.caption1())
                    .foregroundColor(AppTheme.Colors.error)
            }
            if !isManualMode {
                Button {
                    HapticManager.shared.light()
                    withAnimation(AppTheme.Animation.easeInOut) {
                        isManualMode = true
                        errorMessage = nil
                    }
                } label: {
                    Text("Enter nutrition manually instead")
                        .font(AppTheme.Typography.caption1(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .underline()
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.error.opacity(0.1), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
    }

    // MARK: - Actions

    private func toggleVoice() {
        if speech.isRecording {
            speech.stop()
            HapticManager.shared.light()
            isNameFocused = true
            return
        }
        Task {
            let ok = await speech.requestAuthorization()
            guard ok else {
                errorMessage = "Enable Microphone and Speech Recognition in Settings to log by voice."
                HapticManager.shared.error()
                return
            }
            errorMessage = nil
            mealName = ""
            isNameFocused = false
            do {
                try speech.start()
                HapticManager.shared.light()
            } catch {
                errorMessage = "Couldn't start voice input. Please try again."
            }
        }
    }

    /// Re-log a previous meal instantly — no AI call, no latency, no cost.
    private func relog(_ meal: MealLog) {
        let copy = MealLog(
            name: meal.name,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            emoji: meal.emoji,
            timestamp: Date(),
            mealType: selectedCategory.rawValue,
            isAIGenerated: meal.isAIGenerated
        )
        modelContext.insert(copy)
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            modelContext.delete(copy)
            errorMessage = "Couldn't log that meal. Please try again."
            HapticManager.shared.error()
        }
    }

    private func logMeal() {
        if speech.isRecording { speech.stop() }
        let trimmed = mealName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if isManualMode {
            logManualMeal(named: trimmed)
            return
        }

        isLoading = true
        errorMessage = nil

        let tempMeal = MealLog(
            name: trimmed,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            emoji: selectedCategory.emoji,
            mealType: selectedCategory.rawValue
        )
        modelContext.insert(tempMeal)

        Task {
            do {
                let nutrition = try await AIService.shared.getNutritionInfo(for: trimmed)
                await MainActor.run {
                    tempMeal.calories = nutrition.calories
                    tempMeal.protein = nutrition.protein
                    tempMeal.carbs = nutrition.carbs
                    tempMeal.fat = nutrition.fat
                    try? modelContext.save()
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    modelContext.delete(tempMeal)
                    isLoading = false
                    HapticManager.shared.error()
                }
            }
        }
    }

    /// Log with user-provided nutrition — no AI call, works offline.
    private func logManualMeal(named name: String) {
        guard manualCalories > 0 else { return }

        let meal = MealLog(
            name: name,
            calories: manualCalories,
            protein: max(manualProtein, 0),
            carbs: max(manualCarbs, 0),
            fat: max(manualFat, 0),
            emoji: selectedCategory.emoji,
            mealType: selectedCategory.rawValue,
            isAIGenerated: false
        )
        modelContext.insert(meal)
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            modelContext.delete(meal)
            errorMessage = "Couldn't log that meal. Please try again."
            HapticManager.shared.error()
        }
    }
}

// MARK: - Speech Recognizer

/// Lightweight live speech-to-text wrapper for voice meal logging.
/// Kept in this file to avoid Xcode project file surgery; can be promoted to its
/// own file under Core/Services later.
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestAuthorization() async -> Bool {
        let speechOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let micOK = await AVAudioApplication.requestRecordPermission()
        return speechOK && micOK
    }

    func start() throws {
        task?.cancel()
        task = nil
        transcript = ""

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stop()
                }
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stop() {
        guard isRecording || request != nil else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

#Preview {
    QuickAddMealView()
        .preferredColorScheme(.dark)
}
