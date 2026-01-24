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
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @StateObject private var userState = UserState()

    init() {
        // FOR TESTING ONLY: Reset onboarding state on every launch
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    var body: some Scene {
        WindowGroup {
            if !isLoggedIn {
                LoginView()
                    .statusBarHidden(true)
            } else if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(userState)
                    .statusBarHidden(true)
            } else {
                OnboardingView()
                    .environmentObject(userState)
                    .statusBarHidden(true)
            }
        }
    }
}
