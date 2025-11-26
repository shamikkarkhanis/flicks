//
//  ProfileView.swift
//  Flicks
//
//  Created by Shamik Karkhanis on 11/24/25.
//

import SwiftUI

struct ProfileView: View {
    private let name = "Shamik Karkhanis"
    private let likes = ["Sci-Fi", "Cozy", "Thrillers", "Indie Gems"]
    private let watchlist = ["Dune: Part Two", "Past Lives", "The Holdovers", "Poor Things"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppStyle.brandGradient
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
            Text("What I like")
                .font(.system(size: 18, weight: .semibold))

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 110), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(likes, id: \.self) { like in
                    Text(like)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watchlist")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 10) {
                ForEach(watchlist, id: \.self) { title in
                    HStack {
                        Image(systemName: "film")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28)

                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
