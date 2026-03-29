//
//  MainTabView.swift
//  CallyFS
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddMeal = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                DashboardView()
                VStack{
                    Spacer()
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        showAddMeal: $showAddMeal
                    ).background(AppTheme.Colors.background)
                }.edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
