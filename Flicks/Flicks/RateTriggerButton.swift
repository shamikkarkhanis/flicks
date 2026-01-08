import SwiftUI

struct RateTriggerButton: View {
    let rating: UserState.UserRating?
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(iconColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 50, height: 50)
            .glassEffect()
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .overlay(
            Color.clear
                .frame(width: 80, height: 80)
                .contentShape(Circle())
                .onTapGesture(perform: action)
        )
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        switch rating {
        case .like: return "hand.thumbsup.fill"
        case .dislike: return "hand.thumbsdown.fill"
        case .neutral: return "minus"
        case nil: return "sparkles"
        }
    }
    
    private var iconColor: Color {
        switch rating {
        case .like: return .green
        case .dislike: return .red
        case .neutral: return .white
        case nil: return .white
        }
    }
}
