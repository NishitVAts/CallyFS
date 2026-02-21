//
//   Home.swift
//  CallyFS
//
//  Created by Nishit Vats on 18/02/26.
//

import SwiftUI

// MARK: - Models
struct MealSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let timeRange: String
    let gradient: [Color]
    var calories: Int
    var items: [LoggedMeal]
}

struct LoggedMeal: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
}

// MARK: - Haptic Manager
class HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Main Home Screen
struct HomeScreenView: View {
    @State private var selectedDate = Date()
    @State private var caloriesConsumed: Int = 1240
    @State private var caloriesGoal: Int = 2000
    @State private var waterGlasses: Int = 4
    @State private var animateRing = false
    @State private var animateHeader = false
    @State private var expandedSection: UUID? = nil
    @State private var showAIInput = false
    @State private var activeMealSection: MealSection? = nil
    @State private var showNutrientBreakdown = false
    @State private var cardOffsets: [UUID: CGFloat] = [:]
    
    @State private var mealSections: [MealSection] = [
        MealSection(
            title: "Breakfast",
            icon: "sunrise.fill",
            timeRange: "6 AM – 10 AM",
            gradient: [Color(hex: "FF9A3C"), Color(hex: "FF6B6B")],
            calories: 480,
            items: [
                LoggedMeal(name: "Oats with banana", calories: 320, protein: 8, carbs: 54, fat: 6),
                LoggedMeal(name: "Black coffee", calories: 5, protein: 0, carbs: 0, fat: 0),
                LoggedMeal(name: "Boiled eggs ×2", calories: 155, protein: 12, carbs: 1, fat: 10)
            ]
        ),
        MealSection(
            title: "Lunch",
            icon: "sun.max.fill",
            timeRange: "12 PM – 3 PM",
            gradient: [Color(hex: "4ECDC4"), Color(hex: "44A08D")],
            calories: 560,
            items: [
                LoggedMeal(name: "White sauce pasta 100g", calories: 340, protein: 11, carbs: 48, fat: 12),
                LoggedMeal(name: "Garden salad", calories: 120, protein: 3, carbs: 14, fat: 7),
                LoggedMeal(name: "Orange juice 200ml", calories: 100, protein: 1, carbs: 24, fat: 0)
            ]
        ),
        MealSection(
            title: "Snacks",
            icon: "apple.logo",
            timeRange: "3 PM – 6 PM",
            gradient: [Color(hex: "A18CD1"), Color(hex: "FBC2EB")],
            calories: 200,
            items: [
                LoggedMeal(name: "Almonds 30g", calories: 200, protein: 7, carbs: 6, fat: 18)
            ]
        ),
        MealSection(
            title: "Dinner",
            icon: "moon.stars.fill",
            timeRange: "7 PM – 10 PM",
            gradient: [Color(hex: "2C3E7A"), Color(hex: "5B86E5")],
            calories: 0,
            items: []
        )
    ]
    
    var progress: Double {
        Double(caloriesConsumed) / Double(caloriesGoal)
    }
    
    var remainingCalories: Int {
        max(0, caloriesGoal - caloriesConsumed)
    }
    
    var body: some View {
        ZStack {
            // Background
            
            
            // Ambient orbs
//            ambientBackground
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        
                    
                    calorieRingSection
                        .padding(.top, 24)
                    
                    macroBarSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    waterTrackerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    mealSectionsView
                        .padding(.top, 28)
                    
                    Spacer().frame(height: 120)
                }
            }
            
            // AI Input Sheet
            if showAIInput, let section = activeMealSection {
                AIInputOverlay(
                    mealSection: section,
                    isPresented: $showAIInput
                )
                .zIndex(100)
            }
        }
        
    }
    
    
}

extension HomeScreenView {
    // MARK: - Ambient Background
    var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FF6B6B").opacity(0.07))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color(hex: "4ECDC4").opacity(0.07))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 130, y: 100)
            
            Circle()
                .fill(Color(hex: "A18CD1").opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -80, y: 400)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
               
                Text("Today")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
//                    .opacity(animateHeader ? 1 : 0)
//                    .offset(y: animateHeader ? 0 : -10)
//                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animateHeader)
                
                Text(formattedDate)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "5A6070"))
//                    .opacity(animateHeader ? 1 : 0)
//                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateHeader)
            }
            
            Spacer()
            
            // Avatar + Streak
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "FF9A3C"), Color(hex: "FF6B6B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 46, height: 46)
                    
                    Text("A")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color(hex: "FF6B6B").opacity(0.4), radius: 10)
                .onTapGesture { HapticManager.impact(.light) }
                
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "FF9A3C"))
                    Text("7d")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF9A3C"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "FF9A3C").opacity(0.15))
                .clipShape(Capsule())
            }
            .opacity(animateHeader ? 1 : 0)
            .scaleEffect(animateHeader ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateHeader)
        }
    }
    
    // MARK: - Calorie Ring
    var calorieRingSection: some View {
        ZStack {
            // Glass card
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            
            HStack(spacing: 30) {
                // Ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 14)
                        .frame(width: 130, height: 130)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: animateRing ? progress : 0)
                        .stroke(
                            AngularGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF9A3C"), Color(hex: "FFD93D")],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.4).delay(0.4), value: animateRing)
                    
                    // Center content
                    VStack(spacing: 2) {
                        Text("\(caloriesConsumed)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("kcal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "8A8FA8"))
                    }
                }
                
                // Stats column
                VStack(alignment: .leading, spacing: 16) {
                    calorieStatRow(
                        label: "Goal",
                        value: "\(caloriesGoal)",
                        unit: "kcal",
                        color: Color(hex: "4ECDC4")
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    calorieStatRow(
                        label: "Remaining",
                        value: "\(remainingCalories)",
                        unit: "kcal",
                        color: Color(hex: "FFD93D")
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    calorieStatRow(
                        label: "Burned",
                        value: "340",
                        unit: "kcal",
                        color: Color(hex: "FF6B6B")
                    )
                }
                .padding(.trailing, 8)
            }
            .padding(24)
        }
        .frame(height: 200)
        .padding(.horizontal, 20)
        .opacity(animateRing ? 1 : 0)
        .offset(y: animateRing ? 0 : 20)
        .animation(.easeOut(duration: 0.7).delay(0.3), value: animateRing)
    }
    
    func calorieStatRow(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "5A6070"))
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color.opacity(0.7))
            }
        }
    }
    
    // MARK: - Macro Bars
    var macroBarSection: some View {
        HStack(spacing: 12) {
            macroCard(name: "Protein", value: 89, goal: 150, unit: "g", color: Color(hex: "FF6B6B"), icon: "🥩")
            macroCard(name: "Carbs", value: 142, goal: 250, unit: "g", color: Color(hex: "FFD93D"), icon: "🍞")
            macroCard(name: "Fat", value: 38, goal: 65, unit: "g", color: Color(hex: "4ECDC4"), icon: "🥑")
        }
        .opacity(animateRing ? 1 : 0)
        .offset(y: animateRing ? 0 : 15)
        .animation(.easeOut(duration: 0.7).delay(0.5), value: animateRing)
    }
    
    func macroCard(name: String, value: Int, goal: Int, unit: String, color: Color, icon: String) -> some View {
        let pct = Double(value) / Double(goal)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(icon)
                    .font(.system(size: 16))
                Spacer()
                Text("\(value)\(unit)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "5A6070"))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: animateRing ? geo.size.width * pct : 0, height: 5)
                        .animation(.easeInOut(duration: 1.1).delay(0.6), value: animateRing)
                }
            }
            .frame(height: 5)
            
            Text("/ \(goal)\(unit)")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "3A3F52"))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Water Tracker
    var waterTrackerSection: some View {
        HStack(spacing: 14) {
            Image(systemName: "drop.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "5B86E5"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Hydration")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "5A6070"))
                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { i in
                        Capsule()
                            .fill(i < waterGlasses ? Color(hex: "5B86E5") : Color.white.opacity(0.07))
                            .frame(width: 22, height: 8)
                            .onTapGesture {
                                HapticManager.impact(.light)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    waterGlasses = i + 1
                                }
                            }
                    }
                }
            }
            
            Spacer()
            
            Text("\(waterGlasses)/8")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "5B86E5"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color(hex: "5B86E5").opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(animateRing ? 1 : 0)
        .animation(.easeOut(duration: 0.7).delay(0.65), value: animateRing)
    }
    
    // MARK: - Meal Sections
    var mealSectionsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Meals")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
            
            ForEach(Array(mealSections.enumerated()), id: \.element.id) { index, section in
                MealSectionCard(
                    section: section,
                    isExpanded: expandedSection == section.id,
                    onTap: {
                        HapticManager.impact(.medium)
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            expandedSection = expandedSection == section.id ? nil : section.id
                        }
                    },
                    onAddTap: {
                        HapticManager.notification(.success)
                        activeMealSection = section
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showAIInput = true
                        }
                    }
                )
                .padding(.horizontal, 20)
                .opacity(animateRing ? 1 : 0)
                .offset(y: animateRing ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.7 + Double(index) * 0.1), value: animateRing)
            }
        }
    }
    
    // MARK: - Helpers
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default: return "Good night,"
        }
    }
    
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }
}

// MARK: - Meal Section Card
struct MealSectionCard: View {
    let section: MealSection
    let isExpanded: Bool
    let onTap: () -> Void
    let onAddTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: section.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                            .shadow(color: section.gradient.first?.opacity(0.4) ?? .clear, radius: 8)
                        
                        Image(systemName: section.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(section.timeRange)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "5A6070"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(section.calories > 0 ? "\(section.calories)" : "–")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(section.calories > 0 ? .white : Color(hex: "3A3F52"))
                        Text("kcal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(hex: "3A3F52"))
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "3A3F52"))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(18)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.horizontal, 18)
                    
                    if section.items.isEmpty {
                        emptyStateView
                    } else {
                        loggedItemsList
                    }
                    
                    // AI Log Button
                    Button(action: onAddTap) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: section.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Log with AI")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Type naturally e.g. \"pasta 100g\"")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "5A6070"))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(LinearGradient(
                                    colors: section.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [section.gradient.first?.opacity(0.12) ?? .clear,
                                         section.gradient.last?.opacity(0.06) ?? .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    .buttonStyle(PressButtonStyle())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            isExpanded
                            ? (section.gradient.first?.opacity(0.35) ?? Color.white.opacity(0.1))
                            : Color.white.opacity(0.07),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: isExpanded ? (section.gradient.first?.opacity(0.15) ?? .clear) : .clear, radius: 20)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isExpanded)
    }
    
    var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: "3A3F52"))
            Text("Nothing logged yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "3A3F52"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    var loggedItemsList: some View {
        VStack(spacing: 0) {
            ForEach(section.items) { item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(
                            colors: section.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 6, height: 6)
                    
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "C5C9D6"))
                    
                    Spacer()
                    
                    Text("\(item.calories) kcal")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "8A8FA8"))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                
                if item.id != section.items.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.04))
                        .padding(.leading, 36)
                }
            }
        }
    }
}

// MARK: - AI Input Overlay
struct AIInputOverlay: View {
    let mealSection: MealSection
    @Binding var isPresented: Bool
    @State private var inputText = ""
    @State private var isAnalyzing = false
    @State private var animateIn = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    HapticManager.impact(.light)
                    withAnimation(.spring(response: 0.4)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 20) {
                    // Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                    
                    // Section label
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(
                                    colors: mealSection.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 36, height: 36)
                            Image(systemName: mealSection.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Log to \(mealSection.title)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Describe your food naturally")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "5A6070"))
                        }
                        Spacer()
                        
                        Button(action: {
                            HapticManager.impact(.light)
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color(hex: "3A3F52"))
                        }
                    }
                    
                    // Examples chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["white sauce pasta 100g", "2 boiled eggs", "oats with milk 250ml", "grilled chicken 150g"], id: \.self) { example in
                                Button(action: {
                                    HapticManager.selection()
                                    inputText = example
                                }) {
                                    Text(example)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color(hex: "8A8FA8"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    
                    // Input field
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(LinearGradient(
                                colors: mealSection.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        TextField("e.g. white sauce pasta 100g...", text: $inputText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                            .tint(mealSection.gradient.first)
                            .focused($isFocused)
                        
                        if !inputText.isEmpty {
                            Button(action: {
                                HapticManager.notification(.success)
                                withAnimation { isAnalyzing = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { isAnalyzing = false }
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(
                                            colors: mealSection.gradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 38, height: 38)
                                    
                                    if isAnalyzing {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isFocused
                                ? (mealSection.gradient.first?.opacity(0.5) ?? Color.white.opacity(0.12))
                                : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                    
                    if isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(mealSection.gradient.first)
                                .scaleEffect(0.8)
                            Text("Analyzing nutrition with AI...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(hex: "8A8FA8"))
                        }
                        .transition(.opacity)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: "0F1824"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .offset(y: animateIn ? 0 : 300)
                .animation(.spring(response: 0.55, dampingFraction: 0.8), value: animateIn)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onAppear {
            animateIn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFocused = true
            }
        }
    }
}

// MARK: - Press Button Style
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    HomeScreenView().preferredColorScheme(.dark)
}
