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

    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
    }
}
