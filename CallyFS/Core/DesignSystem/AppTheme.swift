//
//  AppTheme.swift
//  CallyFS
//

import SwiftUI

enum AppTheme {
    
    // MARK: - Colors
    enum Colors {
        static let background = Color(hex: "#0F0F0F")
        static let surface = Color(hex: "#151515")
        static let surfaceElevated = Color(hex: "#1A1A1A")
        static let surfaceHighlight = Color(hex: "#1E1E1E")
        
        static let border = Color(hex: "#2A2A2A")
        static let borderLight = Color(hex: "#3A3A3A")
        static let borderHighlight = Color(hex: "#454545")
        
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#AAAAAA")
        static let textTertiary = Color(hex: "#888888")
        static let textQuaternary = Color(hex: "#666666")
        static let textDisabled = Color(hex: "#555555")
        
        static let accent = Color.white
        static let accentSecondary = Color(hex: "#DDDDDD")
        
        static let success = Color(hex: "#4CAF50")
        static let warning = Color(hex: "#FF9800")
        static let error = Color(hex: "#FF6B6B")
        static let info = Color(hex: "#2196F3")
        
        static let macroProtein = Color(hex: "#A0A0A0")
        static let macroCarbs = Color(hex: "#E8E8E8")
        static let macroFat = Color(hex: "#C8C8C8")
        
        static let gradientStart = Color(hex: "#E0E0E0")
        static let gradientEnd = Color(hex: "#909090")
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        static let massive: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 12
        static let lg: CGFloat = 14
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let xxxl: CGFloat = 24
        static let round: CGFloat = 28
    }
    
    // MARK: - Typography
    enum Typography {
        static func largeTitle(weight: Font.Weight = .black) -> Font {
            .system(size: 64, weight: weight, design: .rounded)
        }
        
        static func title1(weight: Font.Weight = .bold) -> Font {
            .system(size: 36, weight: weight)
        }
        
        static func title2(weight: Font.Weight = .bold) -> Font {
            .system(size: 28, weight: weight)
        }
        
        static func title3(weight: Font.Weight = .bold) -> Font {
            .system(size: 24, weight: weight)
        }
        
        static func headline(weight: Font.Weight = .semibold) -> Font {
            .system(size: 20, weight: weight)
        }
        
        static func body(weight: Font.Weight = .regular) -> Font {
            .system(size: 17, weight: weight)
        }
        
        static func callout(weight: Font.Weight = .regular) -> Font {
            .system(size: 16, weight: weight)
        }
        
        static func subheadline(weight: Font.Weight = .regular) -> Font {
            .system(size: 15, weight: weight)
        }
        
        static func footnote(weight: Font.Weight = .regular) -> Font {
            .system(size: 13, weight: weight)
        }
        
        static func caption1(weight: Font.Weight = .regular) -> Font {
            .system(size: 12, weight: weight)
        }
        
        static func caption2(weight: Font.Weight = .regular) -> Font {
            .system(size: 11, weight: weight)
        }
        
        static func label(weight: Font.Weight = .bold) -> Font {
            .system(size: 11, weight: weight)
        }
    }
    
    // MARK: - Shadows
    enum Shadows {
        static func card() -> some View {
            EmptyView().shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        }
        
        static func elevated() -> some View {
            EmptyView().shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        }
        
        static func subtle() -> some View {
            EmptyView().shadow(color: .black.opacity(0.2), radius: 2)
        }
    }
    
    // MARK: - Animation
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.85)
        static let springFast = SwiftUI.Animation.spring(response: 0.28, dampingFraction: 0.82)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.38, dampingFraction: 0.72)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.2)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
    }
    
    func elevatedCardStyle() -> some View {
        self
            .background(AppTheme.Colors.surfaceElevated)
            .cornerRadius(AppTheme.CornerRadius.xxl)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxl)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
    }
    
    func buttonStyle(isEnabled: Bool = true) -> some View {
        self
            .background(isEnabled ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
            .cornerRadius(AppTheme.CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .stroke(isEnabled ? Color.clear : AppTheme.Colors.borderLight, lineWidth: 1)
            )
    }
}
