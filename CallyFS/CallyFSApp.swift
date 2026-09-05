//
//  CallyFSApp.swift
//  CallyFS
//

import SwiftUI
import SwiftData

@main
struct CallyFSApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnBoardingView()
                }
            }
            // The UI is built entirely from dark, hardcoded colors, so pin the
            // app to dark mode until/unless an adaptive palette is introduced.
            .preferredColorScheme(.dark)
        }
        .modelContainer(AppPersistence.container)
    }
}
