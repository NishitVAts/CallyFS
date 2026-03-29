//
//  CustomTabBar.swift
//  CallyFS
//
//  Created by Nishit Vats on 26/03/26.
//

import Foundation
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showAddMeal: Bool
    
    let items: [(String, Int)] = [
        ("house.fill", 0),
        ("chart.bar.fill", 1),
        ("plus", 2),
        ("calendar", 3),
        ("person.fill", 4)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.1) { icon, tag in
                if tag == 2 {
                    Button(action: {
                        HapticManager.shared.fabTap()
                        showAddMeal = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .frame(width: 58, height: 58)
                                .shadow(color: AppTheme.Colors.accent.opacity(0.2), radius: 12, y: 2)
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppTheme.Colors.background)
                        }
                    }
                    .padding(.horizontal, 10)
                    .offset(y: -15)
                } else {
                    Button(action: {
                        HapticManager.shared.light()
                        selectedTab = tag
                    }) {
                        Image(systemName: icon)
                            .font(.system(size: 21, weight: selectedTab == tag ? .semibold : .regular))
                            .foregroundColor(selectedTab == tag ? AppTheme.Colors.textPrimary : AppTheme.Colors.textQuaternary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .padding(.bottom)
                    }
                }
            }
        }
    }
}
