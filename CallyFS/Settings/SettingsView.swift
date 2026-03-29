//
//  SettingsView.swift
//  CallyFS
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var apiKey: String = ""
    @State private var showingSaved = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var hasExistingKey = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                        apiKeySection
                        
                        instructionsSection
                        
                        if hasExistingKey {
                            dangerZoneSection
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, AppTheme.Spacing.xl)
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
            .onAppear(perform: loadAPIKey)
        }
    }
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("OpenRouter API")
                    .font(AppTheme.Typography.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Add your OpenRouter API key to enable AI-powered nutrition analysis and meal planning")
                    .font(AppTheme.Typography.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("API KEY")
                    .font(AppTheme.Typography.label())
                    .foregroundColor(AppTheme.Colors.textQuaternary)
                    .tracking(1.2)
                
                TextField("sk-or-v1-...", text: $apiKey)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.surfaceElevated)
                    .cornerRadius(AppTheme.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                            .stroke(AppTheme.Colors.border, lineWidth: 1.5)
                    )
            }
            
            if showingError {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.Colors.error)
                    Text(errorMessage)
                        .font(AppTheme.Typography.caption1())
                        .foregroundColor(AppTheme.Colors.error)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.error.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.md)
            }
            
            Button(action: saveAPIKey) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: showingSaved ? "checkmark.circle.fill" : "key.fill")
                        .font(AppTheme.Typography.callout())
                    Text(showingSaved ? "Saved!" : "Save API Key")
                        .font(AppTheme.Typography.callout(weight: .semibold))
                }
                .foregroundColor(apiKey.isEmpty ? AppTheme.Colors.textQuaternary : AppTheme.Colors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(apiKey.isEmpty ? AppTheme.Colors.surfaceElevated : AppTheme.Colors.accent)
                .cornerRadius(AppTheme.CornerRadius.lg)
            }
            .disabled(apiKey.isEmpty)
            .animation(AppTheme.Animation.easeInOut, value: apiKey.isEmpty)
            .animation(AppTheme.Animation.easeInOut, value: showingSaved)
        }
        .padding(AppTheme.Spacing.xxl)
        .elevatedCardStyle()
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("How to get your API key")
                .font(AppTheme.Typography.body(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                InstructionRow(number: "1", text: "Visit openrouter.ai and create an account")
                InstructionRow(number: "2", text: "Go to Settings → API Keys")
                InstructionRow(number: "3", text: "Create a new API key and paste it above")
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Danger Zone")
                .font(AppTheme.Typography.body(weight: .semibold))
                .foregroundColor(AppTheme.Colors.error)
            
            Button(action: deleteAPIKey) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(AppTheme.Typography.subheadline())
                    Text("Delete API Key")
                        .font(AppTheme.Typography.subheadline(weight: .semibold))
                    Spacer()
                }
                .foregroundColor(AppTheme.Colors.error)
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.error.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.md)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
    
    private func loadAPIKey() {
        if let key = APIKeyManager.shared.getAPIKey() {
            apiKey = key
            hasExistingKey = true
        }
    }
    
    private func saveAPIKey() {
        showingError = false
        errorMessage = ""
        
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            errorMessage = "Please enter an API key"
            showingError = true
            return
        }
        
//        if !APIKeyManager.shared.validateAPIKey(trimmedKey) {
//            errorMessage = "Invalid API key format. Key should start with 'sk-or-v1-'"
//            showingError = true
//            HapticManager.shared.error()
//            return
//        }
        
        let success = APIKeyManager.shared.saveAPIKey(trimmedKey)
        
        if success {
            HapticManager.shared.success()
            hasExistingKey = true
            withAnimation(AppTheme.Animation.spring) {
                showingSaved = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(AppTheme.Animation.spring) {
                    showingSaved = false
                }
            }
        } else {
            errorMessage = "Failed to save API key. Please try again."
            showingError = true
            HapticManager.shared.error()
        }
    }
    
    private func deleteAPIKey() {
        HapticManager.shared.warning()
        APIKeyManager.shared.deleteAPIKey()
        apiKey = ""
        hasExistingKey = false
        HapticManager.shared.success()
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Text(number + ".")
                .font(AppTheme.Typography.subheadline(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textQuaternary)
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Typography.subheadline())
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
