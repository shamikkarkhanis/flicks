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

    var body: some View {
        ZStack {
            // Background dimmer
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // The Menu Capsule
            HStack(spacing: 20) {
                // Dislike Button
                RateButton(
                    icon: "hand.thumbsdown.fill",
                    color: .red,
                    isSelected: selectedOption == .dislike
                ) {
                    select(.dislike)
                }

                // Neutral Button
                RateButton(
                    icon: "minus",
                    color: .gray,
                    isSelected: selectedOption == .neutral
                ) {
                    select(.neutral)
                }

                // Like Button
                RateButton(
                    icon: "hand.thumbsup.fill",
                    color: .green,
                    isSelected: selectedOption == .like
                ) {
                    select(.like)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(selectedOption != nil ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedOption)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private func select(_ option: Option) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            selectedOption = option
        }

        // Delay action to allow animation to play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            switch option {
            case .dislike: onDislike()
            case .neutral: onNeutral()
            case .like: onLike()
            }
            onDismiss()
        }
    }
}

struct RateButton: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? color : Color.white.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isSelected ? .white : color.opacity(0.8))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.black
        RateMenu(onDislike: {}, onNeutral: {}, onLike: {}, onDismiss: {})
    }
}
