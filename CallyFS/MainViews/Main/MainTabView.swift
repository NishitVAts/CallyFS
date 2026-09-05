//
//  MainTabView.swift
//  CallyFS
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        // Native TabView: on iOS 26 the system renders this as the Liquid Glass
        // tab bar automatically (floating, translucent, morphing). On iOS 17–25
        // it falls back to the standard system tab bar. Each tab supplies its own
        // NavigationStack, so no outer stack is needed here.
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
                .tag(1)

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(AppTheme.Colors.accent)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
