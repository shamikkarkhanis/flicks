//
//  LoginView.swift
//  Flicks
//
//  Created by Gemini on 1/24/26.
//

import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        ZStack {
            // Background Image
            Image("interstellar.jpg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    .black.opacity(0.1),
                    .black.opacity(0.6),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // App Title & Tagline
                VStack(spacing: 8) {
                    Text("Whatflix")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your AI Movie Companion")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 20)
                
                // Sign in with Apple Button
                // Per guidelines: White button on dark backgrounds
                Button(action: {
                    Task {
                        // Check if user has a profile
                        let profileExists = await userState.fetchUserProfile()
                        
                        await MainActor.run {
                            if profileExists {
                                hasCompletedOnboarding = true
                            }
                            withAnimation {
                                isLoggedIn = true
                            }
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                            .offset(y: -1) // Optical alignment
                        
                        Text("Sign in with Apple")
                            .font(.system(size: 19, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: 250)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(30) // Standard SIWA corner radius is usually smaller, or pill. 8 is safe.
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    LoginView()
}
