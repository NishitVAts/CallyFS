//
//  CallyFSApp.swift
//  CallyFS
//

import SwiftUI

@main
struct CallyFSApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                DashboardView()
            } else {
                OnBoardingView()
            }
        }
    }
}
