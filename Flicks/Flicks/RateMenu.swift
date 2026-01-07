import SwiftUI

struct RateMenu: View {
    enum Option {
        case dislike, neutral, like
    }

    var onDislike: () -> Void
    var onNeutral: () -> Void
    var onLike: () -> Void
    var onDismiss: () -> Void

    @State private var selectedOption: Option?
    @State private var isAnimated = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background dimmer
            Color.black.opacity(isAnimated ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // The Menu Capsule
            HStack(spacing: isAnimated ? (selectedOption == nil ? 20 : 0) : -70) {
                // Dislike Button
                if selectedOption == nil || selectedOption == .dislike {
                    RateButton(
                        icon: "hand.thumbsdown.fill",
                        label: "Dislike",
                        color: .red,
                        isSelected: selectedOption == .dislike
                    ) {
                        select(.dislike)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Neutral Button
                if selectedOption == nil || selectedOption == .neutral {
                    RateButton(
                        icon: "minus",
                        label: "Neutral",
                        color: .gray,
                        isSelected: selectedOption == .neutral
                    ) {
                        select(.neutral)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Like Button
                if selectedOption == nil || selectedOption == .like {
                    RateButton(
                        icon: "hand.thumbsup.fill",
                        label: "Like",
                        color: .green,
                        isSelected: selectedOption == .like
                    ) {
                        select(.like)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
//            .glassEffect()
            .scaleEffect(isAnimated ? (selectedOption != nil ? 0.95 : 1.0) : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedOption)
            .padding(.bottom, 40) // Match position with MenuButton
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isAnimated = true
            }
        }
    }

    private func select(_ option: Option) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if selectedOption == option {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedOption = nil
            }
        } else {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                selectedOption = option
            }

            // Delay action to allow animation to play
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Check if it's still selected (user might have unselected during the tiny delay)
                if selectedOption == option {
                    switch option {
                    case .dislike: onDislike()
                    case .neutral: onNeutral()
                    case .like: onLike()
                    }
                    onDismiss()
                }
            }
        }
    }
}

struct RateButton: View {
    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Selection highlight glow
                    if isSelected {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 84, height: 84)
                            .blur(radius: 12)
                            .transition(.opacity.combined(with: .scale))
                    }

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(color)
                        .frame(width: 70, height: 70)
                        .glassEffect()
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(color.opacity(isSelected ? 0.5 : 0), lineWidth: 2)
                        )
                }
                .contentShape(Circle())
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.black
        RateMenu(onDislike: {}, onNeutral: {}, onLike: {}, onDismiss: {})
    }
}
