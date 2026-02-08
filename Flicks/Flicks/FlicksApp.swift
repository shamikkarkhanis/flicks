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
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            if !authManager.isAuthenticated {
                LoginView()
                    .environmentObject(userState)
                    .environmentObject(authManager)
                    .statusBarHidden(true)
            } else if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(userState)
                    .environmentObject(authManager)
                    .statusBarHidden(true)
            } else {
                OnboardingView()
                    .environmentObject(userState)
                    .environmentObject(authManager)
                    .statusBarHidden(true)
            }
        }
    }
}
