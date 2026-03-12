//
//  SettingsView.swift
//  CallyFS
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showingSaved = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0F0F0F").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("OpenRouter API")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Add your OpenRouter API key to enable AI-powered nutrition calculation")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#888888"))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("API KEY")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "#666666"))
                                    .tracking(1.2)
                                
                                SecureField("sk-or-v1-...", text: $apiKey)
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .padding(16)
                                    .background(Color(hex: "#1A1A1A"))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "#2A2A2A"), lineWidth: 1.5)
                                    )
                            }
                            
                            Button(action: {
                                HapticManager.shared.success()
                                UserDefaults.standard.set(apiKey, forKey: "openRouterAPIKey")
                                withAnimation {
                                    showingSaved = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showingSaved = false
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: showingSaved ? "checkmark.circle.fill" : "key.fill")
                                        .font(.system(size: 16))
                                    Text(showingSaved ? "Saved!" : "Save API Key")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(apiKey.isEmpty ? Color(hex: "#666666") : .black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(apiKey.isEmpty ? Color(hex: "#222222") : Color.white)
                                .cornerRadius(14)
                            }
                            .disabled(apiKey.isEmpty)
                            .animation(.easeInOut(duration: 0.2), value: apiKey.isEmpty)
                            .animation(.easeInOut(duration: 0.2), value: showingSaved)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "#151515"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "#2A2A2A"), lineWidth: 1)
                                )
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How to get your API key:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#AAAAAA"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("1.")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#666666"))
                                    Text("Visit openrouter.ai and create an account")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "#888888"))
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Text("2.")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#666666"))
                                    Text("Go to Settings → API Keys")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "#888888"))
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Text("3.")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#666666"))
                                    Text("Create a new API key and paste it above")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "#888888"))
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: "openRouterAPIKey") ?? ""
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
