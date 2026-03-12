

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
