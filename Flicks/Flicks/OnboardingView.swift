//
//  OnboardingView.swift
//  Flicks
//
//  Created by Shamik Karkhanis on 12/28/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userState: UserState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Use your sample data to populate the stack
    @State private var mediaDeck: [Movie] = sampleMovies

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if mediaDeck.isEmpty {
                VStack(spacing: 12) {
                    Text("You're all set")
                        .font(.title2).bold()
                    Text("We’ll tailor recommendations based on your picks.")
                        .foregroundStyle(.secondary)
                    
                    Button {
                        Task {
                            await userState.syncUserProfile()
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
            } else {
                ZStack {
                    // Render items so the last one appears on top
                    ForEach(Array(mediaDeck.enumerated()), id: \.element.id) { index, movie in
                        VerticalMovieCardView(
                            title: movie.title,
                            subtitle: movie.subtitle,
                            imageName: movie.imageName,
                            friendInitials: movie.friendInitials,
                            disableDetail: true,
                            onSwipe: { liked in
                                if liked {
                                    userState.addToWatchlist(movie)
                                }
                                // Remove this movie from the deck when the card commits a swipe
                                mediaDeck.removeAll { $0.id == movie.id }
                            }
                        )
                        .scaleEffect(0.95)
                        .padding(.horizontal, 20)
                        .zIndex(Double(index))
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
