import SwiftUI
import UIKit
import CoreGraphics

struct MovieDetailView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let friendInitials: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var appearSpin = true

    // Cache the gradient so it doesn’t recompute often
    @State private var backgroundGradient: LinearGradient?
    
    // Cache primary colors for other uses
    @State private var backgroundColors: [UIColor] = []

    // A sensible maximum content width to avoid overly wide layouts on larger devices
    private let maxContentWidth: CGFloat = 700

    // Centralized image load for downstream tasks
    private var uiImage: UIImage? {
        UIImage(named: imageName)
    }

    var body: some View {
        GeometryReader { proxy in
            let deviceWidth = proxy.size.width
            let contentWidth = min(deviceWidth, maxContentWidth)

            ZStack {
                // Background: gradient derived from the movie image colors
                Group {
                    if let gradient = backgroundGradient {
                        gradient
                            .ignoresSafeArea()
                    } else {
                        Color(.systemBackground).ignoresSafeArea()
                    }
                }

                ScrollView {
                    VStack {
                        // Constrain the entire card to contentWidth and center it
                        VStack(alignment: .leading, spacing: 16) {
                            if !imageName.isEmpty {
                                // Constrain the image to contentWidth and crop as needed
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: contentWidth - 32, height: 240) // subtract padding to align edges
                                    .clipped()
                                    .cornerRadius(16)
                            }

                            Section {
                                // Card content
                                VStack(alignment: .leading, spacing: 16) {

                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(title)
                                                .font(.title2).bold()
                                                .foregroundStyle(.primary)
                                            Text(subtitle)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button {
                                            withAnimation(.snappy(duration: 0.3, extraBounce: 0.05)) {
                                                appearSpin = true
                                            }
                                            dismiss()
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Close")
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Ratings")
                                            .font(.headline)
                                        HStack(spacing: 12) {
                                            ratingBadge(title: "Critics", value: "92")
                                                .glassEffect(.regular.tint(Color(uiColor: backgroundColors[safe: 0] ?? .gray).opacity(0.6)))
                                            ratingBadge(title: "Audience", value: "89")
                                                .glassEffect(.regular.tint(Color(uiColor: backgroundColors[safe: 0] ?? .gray).opacity(0.6)))
                                            ratingBadge(title: "Your Friends", value: "91")
                                                .glassEffect(.regular.tint(Color(uiColor: backgroundColors[safe: 0] ?? .gray).opacity(0.6)))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Why you’ll like this")
                                            .font(.headline)
                                        Text("Because you enjoyed mind-bending sci-fi with heartfelt characters and striking visuals. This pick matches your recent interest in ambitious, genre-mixing stories.")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Friends")
                                            .font(.headline)
                                        ForEach(friendInitials, id: \.self) { initials in
                                            HStack(spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .frame(width: 32, height: 32)
                                                        .glassEffect()
                                                    Text(initials)
                                                        .font(.caption2).bold()
                                                }
                                                Text("\(initials) rated it \(Int.random(in: 7...10))/10")
                                                    .font(.subheadline)
                                            }
                                        }
                                    }
                                }
                                .padding(20)
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                        }
                        // The internal padding around the card
                        .padding(16)
                        // Constrain and center the content
                        .frame(width: contentWidth, alignment: .center)
                    }
                    // Make the ScrollView take full width but center its content
                    .frame(maxWidth: .infinity)
                }
                // Spin-in effect for the presented view to simulate spinning from the card
                .rotation3DEffect(.degrees(appearSpin ? 90 : 0), axis: (x: 0, y: 1, z: 0), anchor: .center)
                .scaleEffect(appearSpin ? 0.9 : 1.0)
                .opacity(appearSpin ? 0.0 : 1.0)
                .onAppear {
                    withAnimation(.snappy(duration: 0.35, extraBounce: 0.05)) {
                        appearSpin = false
                    }

                    populateGradient()
                }
                // If imageName can change while presented, recompute
                .onChange(of: imageName) { _ in
                    backgroundColors.removeAll()
                    backgroundGradient = nil
                    populateGradient()
                }
            }
        }
    }

    private func ratingBadge(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.headline).bold()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
            .glassEffect()
        )
    }
}

// MARK: - Helpers

private extension MovieDetailView {
    func populateGradient() {
        guard let uiImage = uiImage else { return }
        if backgroundColors.isEmpty {
            backgroundColors = AppStyle.dominantColors(from: uiImage, sampleGrid: 4) ?? []
        }
        if backgroundGradient == nil, !backgroundColors.isEmpty {
            backgroundGradient = AppStyle.gradient(from: backgroundColors)
        }
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    MovieDetailView(
        title: "Everything Everywhere All At Once",
        subtitle: "Action · Comedy · Sci‑Fi",
        imageName: "spiderverse.jpg",
        friendInitials: ["SK", "AB", "JK"]
    )
}
