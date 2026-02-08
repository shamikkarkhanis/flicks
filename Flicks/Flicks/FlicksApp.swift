import SwiftUI

@main
struct FlicksApp: App {
    @StateObject private var userState = UserState()
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            if !authManager.isAuthenticated {
                LoginView()
                    .environmentObject(userState)
                    .environmentObject(authManager)
                    .statusBarHidden(true)
            } else if userState.hasCompletedOnboarding {
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
