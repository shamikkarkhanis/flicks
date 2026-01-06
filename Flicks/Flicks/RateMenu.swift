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
        ZStack(alignment: .bottom) {
            // Background dimmer
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // The Menu Capsule
            HStack(spacing: selectedOption == nil ? 20 : 0) {
                // Dislike Button
                if selectedOption == nil || selectedOption == .dislike {
                    RateButton(
                        icon: "hand.thumbsdown.fill",
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
            .scaleEffect(selectedOption != nil ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedOption)
            .padding(.bottom, 40) // Match position with MenuButton
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
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .glassEffect()
                    .frame(width: 70, height: 70)

                Image(systemName: icon)
                    .font(.system(size: 30, weight: .bold))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .foregroundColor(color)
                    
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
