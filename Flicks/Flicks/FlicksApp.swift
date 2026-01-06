//
//  FlicksApp.swift
//  Flicks
//
//  Created by Shamik Karkhanis on 11/19/25.
//

import SwiftUI

@main
struct FlicksApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var userState = UserState()

    init() {
        // FOR TESTING ONLY: Reset onboarding state on every launch
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(userState)
            } else {
                OnboardingView()
                    .environmentObject(userState)
            }
        }
    }
}
