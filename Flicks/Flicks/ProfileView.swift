//
//  ProfileView.swift
//  Flicks
//
//  Created by Shamik Karkhanis on 11/24/25.
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var userState: UserState
    private let name = "Shamik Karkhanis"

    // Cache the gradient and colors so we don’t recompute during body updates
    @State private var backgroundGradient: LinearGradient?
    @State private var backgroundColors: [UIColor] = []

    // Centralized image load for downstream tasks
    private var uiImage: UIImage? {
        UIImage(named: "interstellar.jpg")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if let gradient = backgroundGradient {
                        gradient
                    } else {
                        // Fallback while computing or if image/colors are unavailable
                        AppStyle.brandGradient
                    }
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        likesSection
                        watchlistSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                populateGradientIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle()
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)

                // Placeholder profile image
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .glassEffect()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Movie lover • Curated picks for friends")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var likesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genres")
                .font(.system(size: 18, weight: .semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(userState.likes, id: \.self) { like in
                        Text(like)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 1) // Tiny padding to avoid clipping shadows if any
            }
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.system(size: 18, weight: .semibold))

            if userState.watchlist.isEmpty {
                Text("Your history is empty. Swipe right on movies to add them here!")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(userState.watchlist) { movie in
                        MovieCardMiniView(
                            title: movie.title,
                            dateWatched: movie.dateAdded,
                            imageName: movie.imageName
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func populateGradientIfNeeded() {
        // Only compute once per appearance unless you want it dynamic
        guard backgroundGradient == nil else { return }
        guard let uiImage else { return }

        if backgroundColors.isEmpty {
            backgroundColors = AppStyle.dominantColors(from: uiImage, sampleGrid: 4) ?? []
        }
        if !backgroundColors.isEmpty {
            backgroundGradient = AppStyle.gradient(from: backgroundColors)
        } else {
            backgroundGradient = AppStyle.brandGradient
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserState())
}
